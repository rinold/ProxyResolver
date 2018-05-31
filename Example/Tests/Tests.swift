import XCTest
@testable import ProxyResolver

class MockProxyConfigProvider: ProxyConfigProvider {

    static let httpHost = "http.proxy.com"
    static let httpPort = 8080

    static let httpsHost = "https.proxy.com"
    static let httpsPort = 8081

    static let socksHost = "socks.proxy.com"
    static let socksPort = 8082

    var testConfig: [[CFString : AnyObject]]?

    func setTestConfig(_ config: [[CFString : AnyObject]]?) {
        self.testConfig = config
    }

    func getSystemConfigProxies(for url: URL) -> [[CFString : AnyObject]]? {
        return testConfig
    }


}

class Tests: XCTestCase {

    var testConfigProvider: MockProxyConfigProvider!
    var proxy: ProxyResolver!

    let testUrl = URL(string: "http://google.com")!
    
    let noProxyConfig = [[kCFProxyTypeKey: kCFProxyTypeNone]]

    let httpProxyConfig = [
        [kCFProxyTypeKey: kCFProxyTypeHTTP,
         kCFProxyHostNameKey: MockProxyConfigProvider.httpHost as AnyObject,
         kCFProxyPortNumberKey: MockProxyConfigProvider.httpPort as AnyObject]
    ]

    let httpsProxyConfig = [
        [kCFProxyTypeKey: kCFProxyTypeHTTPS,
         kCFProxyHostNameKey: MockProxyConfigProvider.httpsHost as AnyObject,
         kCFProxyPortNumberKey: MockProxyConfigProvider.httpsPort as AnyObject]
    ]

    let socksProxyConfig = [
        [kCFProxyTypeKey: kCFProxyTypeSOCKS,
         kCFProxyHostNameKey: MockProxyConfigProvider.socksHost as AnyObject,
         kCFProxyPortNumberKey: MockProxyConfigProvider.socksPort as AnyObject]
    ]

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
        testConfigProvider.setTestConfig(noProxyConfig)

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
        testConfigProvider.setTestConfig(httpProxyConfig)

        let proxy = ProxyResolver(configProvider: testConfigProvider)
        let url = URL(string: "http://google.com")!
        proxy.resolve(for: url) { result in
            switch result {
            case .success(let proxy):
                XCTAssertNotNil(proxy)
                XCTAssert(.http == proxy!.type)
                XCTAssert(MockProxyConfigProvider.httpHost == proxy!.host)
                XCTAssert(MockProxyConfigProvider.httpPort == proxy!.port)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testHttpsResolve() {
        let expectation = XCTestExpectation(description: "Completion called")
        testConfigProvider.setTestConfig(httpsProxyConfig)

        proxy.resolve(for: testUrl) { result in
            switch result {
            case .success(let proxy):
                XCTAssertNotNil(proxy)
                XCTAssert(.https == proxy!.type)
                XCTAssert(MockProxyConfigProvider.httpsHost == proxy!.host)
                XCTAssert(MockProxyConfigProvider.httpsPort == proxy!.port)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testSocksResolve() {
        let expectation = XCTestExpectation(description: "Completion called")
        testConfigProvider.setTestConfig(socksProxyConfig)

        proxy.resolve(for: testUrl) { result in
            switch result {
            case .success(let proxy):
                XCTAssertNotNil(proxy)
                XCTAssert(.socks == proxy!.type)
                XCTAssert(MockProxyConfigProvider.socksHost == proxy!.host)
                XCTAssert(MockProxyConfigProvider.socksPort == proxy!.port)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
}

