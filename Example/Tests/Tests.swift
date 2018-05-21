import XCTest
import ProxyResolver

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        let expectation = XCTestExpectation(description: "Completion called")
        let proxy = ProxyResolver()
        let url = URL(string: "http://google.com")!
        proxy.resolve(for: url) { result in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }
    
}

