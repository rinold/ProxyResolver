//
//  Configuration.swift
//  ProxyResolver_Tests
//
//  Created by Mikhail Churbanov on 15/06/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import ProxyResolver

typealias ProxyConfigDict = [CFString: AnyObject]

class MockProxyConfigProvider: ProxyConfigProvider {

    var testConfig: [ProxyConfigDict]?

    func setTestConfig(_ config: [ProxyConfigDict]?) {
        self.testConfig = config
    }

    func getSystemConfigProxies(for url: URL) -> [ProxyConfigDict]? {
        return testConfig
    }

}

class MockProxyUrlFetcher: ProxyScriptFether {

    func fetch(request: URLRequest, completion: @escaping (String?, Error?) -> Void) {
        completion(TestConfigs.autoConfig.scriptContents, nil)
    }

}

enum TestConfigs {

    static let timeout = 1.0

    static let httpUrl = URL(string: "http://google.com")!
    static let httpsUrl = URL(string: "https://google.com")!

    // swiftlint:disable type_name
    enum noProxy {
        static let config = [[kCFProxyTypeKey: kCFProxyTypeNone as AnyObject]]
    }

    enum autoConfig {
        static let scriptUrl = "https://autoconf.server.com"
        static let scriptContents = """
        function FindProxyForURL(url, host) {
        return "PROXY \(autoConfig.httpProxy.host):\(autoConfig.httpProxy.port)";
        }
        """
        static let httpProxy = Proxy(type: .http, host: "auto-http.proxy.com", port: 8000)
        static let httpsProxy = Proxy(type: .https, host: "auto-https.proxy.com", port: 8001)
        static let urlConfig = [
            [kCFProxyTypeKey: kCFProxyTypeAutoConfigurationURL,
             kCFProxyAutoConfigurationURLKey: scriptUrl as AnyObject]
        ]
        static let scriptConfig = [
            [kCFProxyTypeKey: kCFProxyTypeAutoConfigurationJavaScript,
             kCFProxyAutoConfigurationJavaScriptKey: scriptContents as AnyObject]
        ]
    }

    enum http {
        static let proxy = Proxy(type: .http, host: "http.proxy.com", port: 8080)
        static let config = [
            [kCFProxyTypeKey: kCFProxyTypeHTTP,
             kCFProxyHostNameKey: proxy.host as AnyObject,
             kCFProxyPortNumberKey: proxy.port as AnyObject]
        ]
    }

    enum https {
        static let proxy = Proxy(type: .https, host: "https.proxy.com", port: 8081)
        static let config = [
            [kCFProxyTypeKey: kCFProxyTypeHTTPS,
             kCFProxyHostNameKey: proxy.host as AnyObject,
             kCFProxyPortNumberKey: proxy.port as AnyObject]
        ]
    }

    enum socks {
        static let proxy = Proxy(type: .socks, host: "socks", port: 8082)
        static let config = [
            [kCFProxyTypeKey: kCFProxyTypeSOCKS,
             kCFProxyHostNameKey: proxy.host as AnyObject,
             kCFProxyPortNumberKey: proxy.port as AnyObject]
        ]
    }
    // swiftlint:enable type_name

}

extension ProxyResolutionResult {
    func isSameSuccessfull(as other: ProxyResolutionResult) -> Bool {
        switch (self, other) {
        case (.direct, .direct): return true
        case let (.proxy(lproxy), .proxy(rproxy)): return lproxy == rproxy
        default: return false
        }
    }
}
