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

class MockProxyUrlFetcher: AutoConfigUrlFether {

    func fetch(request: URLRequest, completion: @escaping (String?, Error?) -> Void) {
        let contents = """
        function FindProxyForURL(url, host) {
            return "PROXY \(TestConfigs.autoConfigUrl.host):\(TestConfigs.autoConfigUrl.port)";
        }
        """.trimmingCharacters(in: .whitespacesAndNewlines)
        completion(contents, nil)
    }

}

enum TestConfigs {

    // swiftlint:disable type_name
    enum noProxy {
        static let config = [[kCFProxyTypeKey: kCFProxyTypeNone]]
    }

    enum autoConfigUrl {
        static let autoConfigUrl = "https://autoconf.server.com"
        static let host = "auto-http.proxy.com"
        static let port = 8000

        static let config = [
            [kCFProxyTypeKey: kCFProxyTypeAutoConfigurationURL,
             kCFProxyAutoConfigurationURLKey: autoConfigUrl as AnyObject]
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

    let testUrl = URL(string: "http://google.com")!

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

        proxy.resolve(for: testUrl) { result in
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
        wait(for: [expectation], timeout: 10.0)
    }

    func testAutoConfigurationUrlResolve() {
        let expectation = XCTestExpectation(description: "Completion called")
        testConfigProvider.setTestConfig(TestConfigs.autoConfigUrl.config)

        proxy.resolve(for: testUrl) { result in
            switch result {
            case .direct:
                XCTAssert(false, "Incorrect direct connection resolved")
            case .proxy(let proxy):
                XCTAssertNotNil(proxy)
                XCTAssert(.http == proxy.type)
                XCTAssert(TestConfigs.autoConfigUrl.host == proxy.host)
                XCTAssert(TestConfigs.autoConfigUrl.port == proxy.port)
            case .error(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

//    func testAutoConfigurationScriptResolve() {
//        XCTAssert(false)
//    }

    func testHttpResolve() {
        let expectation = XCTestExpectation(description: "Completion called")
        testConfigProvider.setTestConfig(TestConfigs.http.config)

        proxy.resolve(for: testUrl) { result in
            switch result {
            case .direct:
                XCTAssert(false, "Incorrect direct connection resolved")
            case .proxy(let proxy):
                XCTAssert(.http == proxy.type)
                XCTAssert(TestConfigs.http.host == proxy.host)
                XCTAssert(TestConfigs.http.port == proxy.port)
            case .error(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testHttpsResolve() {
        let expectation = XCTestExpectation(description: "Completion called")
        testConfigProvider.setTestConfig(TestConfigs.https.config)

        proxy.resolve(for: testUrl) { result in
            switch result {
            case .direct:
                XCTAssert(false, "Incorrect direct connection resolved")
            case .proxy(let proxy):
                XCTAssertNotNil(proxy)
                XCTAssert(.https == proxy.type)
                XCTAssert(TestConfigs.https.host == proxy.host)
                XCTAssert(TestConfigs.https.port == proxy.port)
            case .error(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testSocksResolve() {
        let expectation = XCTestExpectation(description: "Completion called")
        testConfigProvider.setTestConfig(TestConfigs.socks.config)

        proxy.resolve(for: testUrl) { result in
            switch result {
            case .direct:
                XCTAssert(false, "Incorrect direct connection resolved")
            case .proxy(let proxy):
                XCTAssertNotNil(proxy)
                XCTAssert(.socks == proxy.type)
                XCTAssert(TestConfigs.socks.host == proxy.host)
                XCTAssert(TestConfigs.socks.port == proxy.port)
            case .error(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

}
