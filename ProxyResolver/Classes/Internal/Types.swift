//
//  Types.swift
//  ProxyResolver
//
//  Created by Mikhail Churbanov on 11/06/2018.
//

import Foundation

enum ConfigProxyType {
    case none
    case autoConfigurationUrl
    case autoConfigurationScript
    case http
    case https
    case socks

    init?(from cfProxyType: CFString) {
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

        default:
            return nil
        }
    }
}

extension ProxyType {
    init?(from configProxyType: ConfigProxyType) {
        switch configProxyType {
        case .http:
            self = .http
        case .https:
            self = .https
        case .socks:
            self = .socks

        default:
            return nil
        }
    }
}

// MARK: - ProxyConfigProvide protocol

final class SystemProxyConfigProvider: ProxyConfigProvider {
    func getSystemConfigProxies(for url: URL) -> [[CFString: AnyObject]]? {
        guard let systemSettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() else { return nil }
        let cfProxies = CFNetworkCopyProxiesForURL(url as CFURL, systemSettings).takeRetainedValue()
        return cfProxies as? [[CFString: AnyObject]]
    }
}

// MARK: - Network abstraction protocol

final class URLSessionFetcher: ProxyScriptFether {
    func fetch(request: URLRequest, completion: @escaping (String?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { (data, response, error)  in
            if error == nil, let data = data, let scriptContents = String(data: data, encoding: .utf8) {
                completion(scriptContents, nil)
            } else {
                completion(nil, error)
            }
        }
        task.resume()
    }
}
