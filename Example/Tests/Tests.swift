import XCTest
@testable import ProxyResolver

class MockProxyConfigProvider: ProxyConfigProvider {

    static public let httpHost = "test.proxy.com"
    static public let httpPort = 8080

    func getSystemConfigProxies(for url: URL) -> [[CFString : AnyObject]]? {
        return [
            [kCFProxyTypeKey: kCFProxyTypeHTTP,
             kCFProxyHostNameKey: MockProxyConfigProvider.httpHost as AnyObject,
             kCFProxyPortNumberKey: MockProxyConfigProvider.httpPort as AnyObject]
        ]
    }
}

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testHttpResolve() {
        // This is an example of a functional test case.
        let expectation = XCTestExpectation(description: "Completion called")
        let testConfigProvider = MockProxyConfigProvider()
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
    
}

