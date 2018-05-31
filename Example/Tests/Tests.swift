import XCTest
@testable import ProxyResolver

class MockProxyConfigProvider: ProxyConfigProvider {

    var testConfig: [[CFString : AnyObject]]?

    func setTestConfig(_ config: [[CFString : AnyObject]]?) {
        self.testConfig = config
    }

    func getSystemConfigProxies(for url: URL) -> [[CFString : AnyObject]]? {
        return testConfig
    }

}

enum TestConfigs {

    enum noProxy {
        static let config = [[kCFProxyTypeKey: kCFProxyTypeNone]]
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

}

class Tests: XCTestCase {

    let testUrl = URL(string: "http://google.com")!

    var testConfigProvider: MockProxyConfigProvider!
    var proxy: ProxyResolver!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        testConfigProvider = MockProxyConfigProvider()
        proxy = ProxyResolver(configProvider: testConfigProvider)
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
            case .success(let proxy):
                XCTAssertNil(proxy)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testAutoConfigurationUrlResolve() {
        XCTAssert(false)
    }

    func testAutoConfigurationScriptResolve() {
        XCTAssert(false)
    }

    func testHttpResolve() {
        let expectation = XCTestExpectation(description: "Completion called")
        testConfigProvider.setTestConfig(TestConfigs.http.config)

        let proxy = ProxyResolver(configProvider: testConfigProvider)
        let url = URL(string: "http://google.com")!
        proxy.resolve(for: url) { result in
            switch result {
            case .success(let proxy):
                XCTAssertNotNil(proxy)
                XCTAssert(.http == proxy!.type)
                XCTAssert(TestConfigs.http.host == proxy!.host)
                XCTAssert(TestConfigs.http.port == proxy!.port)
            case .failure(let error):
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
            case .success(let proxy):
                XCTAssertNotNil(proxy)
                XCTAssert(.https == proxy!.type)
                XCTAssert(TestConfigs.https.host == proxy!.host)
                XCTAssert(TestConfigs.https.port == proxy!.port)
            case .failure(let error):
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
            case .success(let proxy):
                XCTAssertNotNil(proxy)
                XCTAssert(.socks == proxy!.type)
                XCTAssert(TestConfigs.socks.host == proxy!.host)
                XCTAssert(TestConfigs.socks.port == proxy!.port)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
}

