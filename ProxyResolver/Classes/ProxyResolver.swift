//
//  ProxyResolver.swift
//  ProxyResolver
//
//  Created by Mikhail Churbanov on 16/04/2018.
//  Copyright © 2018 Mikhail Churbanov. All rights reserved.
//

import Foundation

// MARK: - Public Types

public enum ProxyType {
    case http
    case https
    case socks
}

public struct Credentials {
    public let username: String
    public let password: String
}

extension Credentials {
    public static func get(for host: String) -> Credentials? {
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

public struct Proxy {
    public let type: ProxyType
    public let host: String
    public let port: UInt32

    public var credentials: Credentials? {
        return Credentials.get(for: host)
    }
}

// TODO: Swift 4.2 should have it auto-generated
extension Proxy: Equatable {
    public static func == (lhs: Proxy, rhs: Proxy) -> Bool {
        return lhs.type == rhs.type && lhs.host == rhs.host && lhs.port == rhs.port
    }
}

public enum ProxyResolutionResult {
    case direct
    case proxy(Proxy)
    case error(Error)
}

public enum ProxyResolutionError: Error {
    case proxyTypeUnsupported(String)
    case unexpectedError(Error?)
    case allFailed([Error])
}

// MARK: - ProxyConfigProvide protocol

public protocol ProxyConfigProvider {
    func getSystemConfigProxies(for url: URL) -> [[CFString: AnyObject]]?
}

// MARK: - Network abstraction protocol

public protocol ProxyScriptFether {
    func fetch(request: URLRequest, completion: @escaping (String?, Error?) -> Void)
}

// MARK: - ProxyResolver configuration

public final class ProxyResolverConfig {
    public var configProvider: ProxyConfigProvider
    public var scriptFetcher: ProxyScriptFether
    public var supportedAutoConfigUrlShemes: [String]
    public var shemeNormalizationRules: [String: String]

    public init() {
        configProvider = SystemProxyConfigProvider()
        scriptFetcher = URLSessionFetcher()
        supportedAutoConfigUrlShemes = ["http", "https"]
        shemeNormalizationRules = ["ws": "http",
                                   "wss": "https"]
    }
}

// MARK: - ProxyResolverDelegate protocol

public typealias ResolveNextRoutine = () -> Void

public protocol ProxyResolverDelegate: class {
    func proxyResolver(_ proxyResolver: ProxyResolver, didResolve result: ProxyResolutionResult, for url: URL,
                       resolveNext: ResolveNextRoutine?)
}

// MARK: - ProxyResolver class

public final class ProxyResolver {

    private let config: ProxyResolverConfig

    public weak var delegate: ProxyResolverDelegate?

    // MARK: Public Methods

    public init(config: ProxyResolverConfig = ProxyResolverConfig()) {
        self.config = config
    }

    public func resolve(for url: URL, completion: @escaping (ProxyResolutionResult) -> Void) {
        guard let normalizedUrl = urlWithNormalizedSheme(from: url) else { return }
        guard var proxiesConfig = config.configProvider.getSystemConfigProxies(for: normalizedUrl),
            !proxiesConfig.isEmpty
        else {
            let error = ProxyResolutionError.unexpectedError(nil)
            completion(.error(error))
            return
        }
        var errors = [Error]()
        var tryNextOnErrorCompletion: ((ProxyResolutionResult) -> Void)!
        tryNextOnErrorCompletion = { result in
            switch result {
            case .error(let error):
                errors.append(error)
                guard !proxiesConfig.isEmpty else {
                    let error = ProxyResolutionError.allFailed(errors)
                    completion(.error(error))
                    return
                }
                self.resolveProxy(from: proxiesConfig.removeFirst(), for: normalizedUrl, completion: tryNextOnErrorCompletion)

            case .direct, .proxy:
                completion(result)
            }
        }
        resolveProxy(from: proxiesConfig.removeFirst(), for: normalizedUrl, completion: tryNextOnErrorCompletion)
    }

    public func resolve(for url: URL) {
        guard let normalizedUrl = urlWithNormalizedSheme(from: url) else { return }
        guard var proxiesConfig = config.configProvider.getSystemConfigProxies(for: normalizedUrl),
            !proxiesConfig.isEmpty
        else {
            let error = ProxyResolutionError.unexpectedError(nil)
            let result = ProxyResolutionResult.error(error)
            self.delegate?.proxyResolver(self,
                                         didResolve: result,
                                         for: url,
                                         resolveNext: nil)
            return
        }

        var resolveCompletion: ((ProxyResolutionResult) -> Void)!
        let resolveNextRoutine: ResolveNextRoutine = {
            guard !proxiesConfig.isEmpty else { return }
            self.resolveProxy(from: proxiesConfig.removeFirst(), for: normalizedUrl, completion: resolveCompletion)
        }
        resolveCompletion = { result in
            let resolveNext = (proxiesConfig.count < 1) ? nil : resolveNextRoutine
            self.delegate?.proxyResolver(self,
                                         didResolve: result,
                                         for: url,
                                         resolveNext: resolveNext)
        }
        resolveProxy(from: proxiesConfig.removeFirst(), for: normalizedUrl, completion: resolveCompletion)
    }

    // MARK: Internal Methods

    func resolveProxy(from config: [CFString: AnyObject], for url: URL,
                      completion: @escaping (ProxyResolutionResult) -> Void) {

        guard let proxyTypeValue = config[kCFProxyTypeKey] else {
            let error = ProxyResolutionError.unexpectedError(nil)
            completion(.error(error))
            return
        }
        let cfProxyType = proxyTypeValue as! CFString
        guard let configProxyType = ConfigProxyType(from: cfProxyType) else {
            let error = ProxyResolutionError.proxyTypeUnsupported(cfProxyType as String)
            completion(.error(error))
            return
        }

        switch configProxyType {
        case .autoConfigurationUrl:
            guard let cfAutoConfigUrl = config[kCFProxyAutoConfigurationURLKey],
                let scriptUrlString = cfAutoConfigUrl as? String,
                let scriptUrl = URL(string: scriptUrlString)
            else {
                // TODO: proper error handling
                let error = ProxyResolutionError.unexpectedError(nil)
                completion(.error(error))
                return
            }
            fetchPacScript(from: scriptUrl) { scriptContent, error in
                guard let scriptContent = scriptContent else {
                    // TODO: proper error handling
                    let error = ProxyResolutionError.unexpectedError(nil)
                    completion(.error(error))
                    return
                }
                // TODO: process all, first is for now
                guard let pacProxyConfig = self.executePac(script: scriptContent, for: url)?.first else {
                    // TODO: proper error handling
                    let error = ProxyResolutionError.unexpectedError(nil)
                    completion(.error(error))
                    return
                }
                self.resolveProxy(from: pacProxyConfig, for: url, completion: completion)
            }

        case .autoConfigurationScript:
            guard let cfAutoConfigScript = config[kCFProxyAutoConfigurationJavaScriptKey],
                let scriptContent = cfAutoConfigScript as? String
            else {
                // TODO: proper error handling
                let error = ProxyResolutionError.unexpectedError(nil)
                completion(.error(error))
                return
            }
            // TODO: process all, first is for now
            // TODO: check if code for pac should be moved out (same used after pac fetch above)
            guard let pacProxyConfig = self.executePac(script: scriptContent, for: url)?.first else {
                // TODO: proper error handling
                let error = ProxyResolutionError.unexpectedError(nil)
                completion(.error(error))
                return
            }
            self.resolveProxy(from: pacProxyConfig, for: url, completion: completion)

        case .http, .https, .socks:
            guard let cfProxyHost = config[kCFProxyHostNameKey],
                let proxyHost = cfProxyHost as? String,
                let cfProxyPort = config[kCFProxyPortNumberKey],
                let proxyPort = (cfProxyPort as? NSNumber)?.uint32Value,
                let proxyType = ProxyType(from: configProxyType)
            else {
                let error = ProxyResolutionError.unexpectedError(nil)
                completion(.error(error))
                return
            }
            let proxy = Proxy(type: proxyType, host: proxyHost, port: proxyPort)
            completion(.proxy(proxy))

        case .none:
            completion(.direct)
        }
    }

    // MARK: - PAC resolution helper methods

    func fetchPacScript(from url: URL, completion: @escaping (String?, Error?) -> Void) {
        if url.isFileURL, let scriptContents = try? String(contentsOfFile: url.absoluteString) {
            completion(scriptContents, nil)
            return
        }

        guard let scheme = url.scheme?.lowercased(), config.supportedAutoConfigUrlShemes.contains(scheme) else {
            completion(nil, nil)
            return
        }

        let request = URLRequest(url: url)
        config.scriptFetcher.fetch(request: request, completion: completion)
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

    // MARK: - Helper methods

    func urlWithNormalizedSheme(from url: URL) -> URL? {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let scheme = urlComponents.scheme
        else {
            return nil
        }
        urlComponents.scheme = config.shemeNormalizationRules[scheme] ?? scheme
        return urlComponents.url
    }

}
