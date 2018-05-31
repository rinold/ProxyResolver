//
//  ProxyResolver.swift
//  ProxyConfig
//
//  Created by Mikhail Churbanov on 16/04/2018.
//  Copyright © 2018 Mikhail Churbanov. All rights reserved.
//

import Foundation

public enum ProxyType {
    case none
    case autoConfigurationUrl
    case autoConfigurationScript
    case http
    case https
    case socks

    fileprivate init?(from cfProxyType: CFString) {
        switch cfProxyType {
        case kCFProxyTypeNone:
            self = .none
        case kCFProxyTypeAutoConfigurationURL:
            self = .autoConfigurationUrl
        case kCFProxyTypeAutoConfigurationJavaScript:
            self = .autoConfigurationScript
        case kCFProxyTypeHTTP:
            self = .http
        case kCFProxyTypeHTTPS:
            self = .https
        case kCFProxyTypeSOCKS:
            self = .socks

        default: return nil
        }
    }
}

public struct Credentials {
    public let username: String
    public let password: String
}

public struct Proxy {
    public let type: ProxyType
    public let host: String
    public let port: UInt32

    public var credentials: Credentials? {
        return ProxyResolver.getCredentials(for: host)
    }

    public static let none = Proxy(type: .none, host: "", port: 0)
}

public enum ResolutionResult<ResultType> {
    case success(ResultType?)
    case failure(Error)
}

public enum ProxyResolutionError: Error {
    case proxyTypeUnsupported(String)
    case unexpectedError(Error?)
    case allFailed([Error])
}

public typealias ProxyResolutionCompletion = (ResolutionResult<Proxy>) -> Void
public typealias ProxiesResolutionCompletion = (ResolutionResult<[Proxy]>) -> Void

// MARK: - ProxyConfigProvide protocol

public protocol ProxyConfigProvider {
    func getSystemConfigProxies(for url: URL) -> [[CFString: AnyObject]]?
}

class SystemProxyConfigProvider: ProxyConfigProvider {
    func getSystemConfigProxies(for url: URL) -> [[CFString: AnyObject]]? {
        guard let systemSettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() else { return nil }
        let cfProxies = CFNetworkCopyProxiesForURL(url as CFURL, systemSettings).takeRetainedValue()
        return cfProxies as? [[CFString: AnyObject]]
    }
}

// MARK: - ProxyResolver class

public final class ProxyResolver {

    private var configProvider: ProxyConfigProvider
    private let supportedAutoConfigUrlShemes = ["http", "https"]
    private let shemeNormalizationRules = ["ws": "http",
                                           "wss": "https"]

    // MARK: Public Methods

    // TODO: Configuration for properties above
    public init() {
        self.configProvider = SystemProxyConfigProvider()
    }

    public func resolve(for url: URL, completion: @escaping ProxyResolutionCompletion) {
        guard let normalizedUrl = urlWithNormalizedSheme(from: url) else { return }
        guard let proxiesConfig = configProvider.getSystemConfigProxies(for: normalizedUrl),
            let firstProxyConfig = proxiesConfig.first
        else {
            let error = ProxyResolutionError.unexpectedError(nil)
            completion(.failure(error))
            return
        }
        var i = 0
        var errors = [Error]()
        var tryNextOnErrorCompletion: ProxyResolutionCompletion!
        tryNextOnErrorCompletion = { result in
            i += 1
            switch result {
            case .failure(let error):
                errors.append(error)
                guard i < proxiesConfig.count else {
                    let error = ProxyResolutionError.allFailed(errors)
                    completion(.failure(error))
                    return
                }
                self.resolveProxy(from: proxiesConfig[i], for: normalizedUrl, completion: tryNextOnErrorCompletion)
                return
            case .success(let proxy):
                completion(.success(proxy))
                return
            }
        }
        resolveProxy(from: firstProxyConfig, for: normalizedUrl, completion: tryNextOnErrorCompletion)
    }

//    public func resolveAll(for url: URL, completion: @escaping ProxiesResolutionCompletion) {
//        guard let normalizedUrl = urlWithNormalizedSheme(from: url) else { return }
//        guard let proxies = getSystemConfigProxies(for: normalizedUrl) else { return }
//    }

    // MARK: Internal Methods

    convenience init(configProvider: ProxyConfigProvider) {
        self.init()
        self.configProvider = configProvider
    }

    func resolveProxy(from config: [CFString: AnyObject], for url: URL,
                      completion: @escaping ProxyResolutionCompletion) {

        guard let proxyTypeValue = config[kCFProxyTypeKey] else {
            let error = ProxyResolutionError.unexpectedError(nil)
            completion(.failure(error))
            return
        }
        let cfProxyType = proxyTypeValue as! CFString
        guard let proxyType = ProxyType(from: cfProxyType) else {
            let error = ProxyResolutionError.proxyTypeUnsupported(cfProxyType as String)
            completion(.failure(error))
            return
        }

        switch proxyType {
        case .autoConfigurationUrl:
            guard let cfAutoConfigUrl = config[kCFProxyAutoConfigurationURLKey],
                let scriptUrlString = cfAutoConfigUrl as? String,
                let scriptUrl = URL(string: scriptUrlString)
            else {
                // TODO: proper error handling
                let error = ProxyResolutionError.unexpectedError(nil)
                completion(.failure(error))
                return
            }
            fetchPacScript(from: scriptUrl) { scriptContent, error in
                guard let scriptContent = scriptContent else {
                    // TODO: proper error handling
                    let error = ProxyResolutionError.unexpectedError(nil)
                    completion(.failure(error))
                    return
                }
                // TODO: process all, first is for now
                guard let pacProxyConfig = self.executePac(script: scriptContent, for: url)?.first else {
                    // TODO: proper error handling
                    let error = ProxyResolutionError.unexpectedError(nil)
                    completion(.failure(error))
                    return
                }
                // TODO: check if recursion here is possible?
                self.resolveProxy(from: pacProxyConfig, for: url, completion: completion)
            }

        case .autoConfigurationScript:
            guard let cfAutoConfigScript = config[kCFProxyAutoConfigurationJavaScriptKey],
                let scriptContent = cfAutoConfigScript as? String
            else {
                // TODO: proper error handling
                let error = ProxyResolutionError.unexpectedError(nil)
                completion(.failure(error))
                return
            }
            // TODO: process all, first is for now
            // TODO: check if code for pac should be moved out (same used after pac fetch above)
            guard let pacProxyConfig = self.executePac(script: scriptContent, for: url)?.first else {
                // TODO: proper error handling
                let error = ProxyResolutionError.unexpectedError(nil)
                completion(.failure(error))
                return
            }
            // TODO: check if recursion here is possible?
            self.resolveProxy(from: pacProxyConfig, for: url, completion: completion)

        case .http, .https, .socks:
            guard let cfProxyHost = config[kCFProxyHostNameKey],
                let proxyHost = cfProxyHost as? String,
                let cfProxyPort = config[kCFProxyPortNumberKey],
                let proxyPort = (cfProxyPort as? NSNumber)?.uint32Value
            else {
                let error = ProxyResolutionError.unexpectedError(nil)
                completion(.failure(error))
                return
            }
            let proxy = Proxy(type: proxyType, host: proxyHost, port: proxyPort)
            completion(.success(proxy))

        case .none:
            completion(.success(nil))
        }
    }

    func fetchPacScript(from url: URL, completion: @escaping (String?, Error?) -> Void) {
        if url.isFileURL, let scriptContents = try? String(contentsOfFile: url.absoluteString) {
            completion(scriptContents, nil)
            return
        }

        guard let scheme = url.scheme?.lowercased(), supportedAutoConfigUrlShemes.contains(scheme) else {
            completion(nil, nil)
            return
        }

        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error)  in
            if error == nil, let data = data, let scriptContents = String(data: data, encoding: .utf8) {
                completion(scriptContents, nil)
            } else {
                completion(nil, error)
            }
        }
        task.resume()
    }

    func executePac(script: String, for url: URL) -> [[CFString: AnyObject]]? {
        var error: Unmanaged<CFError>?
        let proxiesCopy = CFNetworkCopyProxiesForAutoConfigurationScript(script as CFString, url as CFURL, &error)
        guard error == nil,
            let cfProxies = proxiesCopy?.takeRetainedValue(),
            let proxies = cfProxies as? [[CFString: AnyObject]]
        else {
            return nil
        }
        return proxies
    }

    // MARK: - Helper Methods

    func urlWithNormalizedSheme(from url: URL) -> URL? {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let scheme = urlComponents.scheme
        else {
            return nil
        }
        urlComponents.scheme = shemeNormalizationRules[scheme] ?? scheme
        return urlComponents.url
    }

    class func getCredentials(for host: String) -> Credentials? {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: host,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }

        guard let existingItem = item as? [String : Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let password = String(data: passwordData, encoding: .utf8),
            let account = existingItem[kSecAttrAccount as String] as? String
        else {
            return nil
        }

        return Credentials(username: account, password: password)
    }

}
