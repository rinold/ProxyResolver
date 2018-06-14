import XCTest
@testable import ProxyResolver

class Tests: XCTestCase {

    var testConfigProvider: MockProxyConfigProvider!
    var testScriptFetcher: MockProxyUrlFetcher!
    var proxy: ProxyResolver!

    override func setUp() {
        super.setUp()
        testConfigProvider = MockProxyConfigProvider()
        testScriptFetcher = MockProxyUrlFetcher()
        let testConfig = ProxyResolverConfig()
        testConfig.configProvider = testConfigProvider
        testConfig.scriptFetcher = testScriptFetcher
        proxy = ProxyResolver(config: testConfig)
    }

    override func tearDown() {
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
