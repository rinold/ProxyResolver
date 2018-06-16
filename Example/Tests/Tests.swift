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
        let expectedResult = ProxyResolutionResult.direct
        testConfigProvider.setTestConfig(TestConfigs.noProxy.config)

        proxy.resolve(for: TestConfigs.httpUrl) { result in
            XCTAssert(result.isSameSuccessfull(as: expectedResult))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TestConfigs.timeout)
    }

    func testAutoConfigurationUrlResolve() {
        let expectation = XCTestExpectation(description: "Completion called")
        let expectedResult = ProxyResolutionResult.proxy(TestConfigs.autoConfig.httpProxy)
        testConfigProvider.setTestConfig(TestConfigs.autoConfig.urlConfig)

        proxy.resolve(for: TestConfigs.httpUrl) { result in
            XCTAssert(result.isSameSuccessfull(as: expectedResult))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TestConfigs.timeout)
    }

    func testAutoConfigurationScriptResolve() {
        let expectation = XCTestExpectation(description: "Completion called")
        let expectedResult = ProxyResolutionResult.proxy(TestConfigs.autoConfig.httpProxy)
        testConfigProvider.setTestConfig(TestConfigs.autoConfig.scriptConfig)

        proxy.resolve(for: TestConfigs.httpUrl) { result in
            XCTAssert(result.isSameSuccessfull(as: expectedResult))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TestConfigs.timeout)
    }

    func testHttpResolve() {
        let expectation = XCTestExpectation(description: "Completion called")
        let expectedResult = ProxyResolutionResult.proxy(TestConfigs.http.proxy)
        testConfigProvider.setTestConfig(TestConfigs.http.config)

        proxy.resolve(for: TestConfigs.httpUrl) { result in
            XCTAssert(result.isSameSuccessfull(as: expectedResult))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TestConfigs.timeout)
    }

    func testHttpsResolve() {
        let expectation = XCTestExpectation(description: "Completion called")
        let expectedResult = ProxyResolutionResult.proxy(TestConfigs.https.proxy)
        testConfigProvider.setTestConfig(TestConfigs.https.config)

        proxy.resolve(for: TestConfigs.httpUrl) { result in
            XCTAssert(result.isSameSuccessfull(as: expectedResult))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TestConfigs.timeout)
    }

    func testSocksResolve() {
        let expectation = XCTestExpectation(description: "Completion called")
        let expectedResult = ProxyResolutionResult.proxy(TestConfigs.socks.proxy)
        testConfigProvider.setTestConfig(TestConfigs.socks.config)

        proxy.resolve(for: TestConfigs.httpUrl) { result in
            XCTAssert(result.isSameSuccessfull(as: expectedResult))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TestConfigs.timeout)
    }

}
