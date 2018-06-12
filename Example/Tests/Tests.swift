import XCTest
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

class MockProxyUrlFetcher: URLFether {

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
        static let config = [[kCFProxyTypeKey: kCFProxyTypeNone]]
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

class Tests: XCTestCase {

    var testConfigProvider: MockProxyConfigProvider!
    var testUrlFetcher: MockProxyUrlFetcher!
    var proxy: ProxyResolver!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        testConfigProvider = MockProxyConfigProvider()
        testUrlFetcher = MockProxyUrlFetcher()
        proxy = ProxyResolver(configProvider: testConfigProvider, urlFetcher: testUrlFetcher)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testNoProxyResolve() {
        let expectation = XCTestExpectation(description: "Completion called")
        testConfigProvider.setTestConfig(TestConfigs.noProxy.config)

        proxy.resolve(for: TestConfigs.httpUrl) { result in
            switch result {
            case .direct:
                XCTAssert(true)
            case .proxy(let proxy):
                XCTAssert(false, "Incorrect proxy connection resolved: \(proxy)")
            case .error(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TestConfigs.timeout)
    }

    func testAutoConfigurationUrlResolve() {
        let expectation = XCTestExpectation(description: "Completion called")
        testConfigProvider.setTestConfig(TestConfigs.autoConfig.urlConfig)

        proxy.resolve(for: TestConfigs.httpUrl) { result in
            switch result {
            case .direct:
                XCTAssert(false, "Incorrect direct connection resolved")
            case .proxy(let proxy):
                XCTAssert(proxy.type == .http)
                XCTAssert(proxy.host == TestConfigs.autoConfig.host)
                XCTAssert(proxy.port == TestConfigs.autoConfig.port)
            case .error(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TestConfigs.timeout)
    }

    func testAutoConfigurationScriptResolve() {
        let expectation = XCTestExpectation(description: "Completion called")
        testConfigProvider.setTestConfig(TestConfigs.autoConfig.scriptConfig)

        proxy.resolve(for: TestConfigs.httpUrl) { result in
            switch result {
            case .direct:
                XCTAssert(false, "Incorrect direct connection resolved")
            case .proxy(let proxy):
                XCTAssert(proxy.type == .http)
                XCTAssert(proxy.host == TestConfigs.autoConfig.host)
                XCTAssert(proxy.port == TestConfigs.autoConfig.port)
            case .error(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TestConfigs.timeout)
    }

    func testHttpResolve() {
        let expectation = XCTestExpectation(description: "Completion called")
        testConfigProvider.setTestConfig(TestConfigs.http.config)

        proxy.resolve(for: TestConfigs.httpUrl) { result in
            switch result {
            case .direct:
                XCTAssert(false, "Incorrect direct connection resolved")
            case .proxy(let proxy):
                XCTAssert(proxy.type == .http)
                XCTAssert(proxy.host == TestConfigs.http.host)
                XCTAssert(proxy.port == TestConfigs.http.port)
            case .error(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TestConfigs.timeout)
    }

    func testHttpsResolve() {
        let expectation = XCTestExpectation(description: "Completion called")
        testConfigProvider.setTestConfig(TestConfigs.https.config)

        proxy.resolve(for: TestConfigs.httpUrl) { result in
            switch result {
            case .direct:
                XCTAssert(false, "Incorrect direct connection resolved")
            case .proxy(let proxy):
                XCTAssert(proxy.type == .https)
                XCTAssert(proxy.host == TestConfigs.https.host)
                XCTAssert(proxy.port == TestConfigs.https.port)
            case .error(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TestConfigs.timeout)
    }

    func testSocksResolve() {
        let expectation = XCTestExpectation(description: "Completion called")
        testConfigProvider.setTestConfig(TestConfigs.socks.config)

        proxy.resolve(for: TestConfigs.httpUrl) { result in
            switch result {
            case .direct:
                XCTAssert(false, "Incorrect direct connection resolved")
            case .proxy(let proxy):
                XCTAssert(proxy.type == .socks)
                XCTAssert(proxy.host == TestConfigs.socks.host)
                XCTAssert(proxy.port == TestConfigs.socks.port)
            case .error(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TestConfigs.timeout)
    }

}
