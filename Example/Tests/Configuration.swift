//
//  Configuration.swift
//  ProxyResolver_Tests
//
//  Created by Mikhail Churbanov on 15/06/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import ProxyResolver

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
        let contents = """
            function FindProxyForURL(url, host) {
            return "PROXY \(TestConfigs.autoConfig.host):\(TestConfigs.autoConfig.port)";
            }
            """.trimmingCharacters(in: .whitespacesAndNewlines)
        completion(contents, nil)
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
        return "PROXY \(autoConfig.host):\(autoConfig.port)";
        }
        """
        static let host = "auto-http.proxy.com"
        static let port = 8000

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
        static let host = "http.proxy.com"
        static let port = 8080

        static let config = [
            [kCFProxyTypeKey: kCFProxyTypeHTTP,
             kCFProxyHostNameKey: host as AnyObject,
             kCFProxyPortNumberKey: port as AnyObject]
        ]
    }

    enum https {
        static let host = "http.proxy.com"
        static let port = 8081

        static let config = [
            [kCFProxyTypeKey: kCFProxyTypeHTTPS,
             kCFProxyHostNameKey: host as AnyObject,
             kCFProxyPortNumberKey: port as AnyObject]
        ]
    }

    enum socks {
        static let host = "socks.proxy.com"
        static let port = 8082

        static let config = [
            [kCFProxyTypeKey: kCFProxyTypeSOCKS,
             kCFProxyHostNameKey: host as AnyObject,
             kCFProxyPortNumberKey: port as AnyObject]
        ]
    }
    // swiftlint:enable type_name

}
