//
//  DelegateTests.swift
//  ProxyResolver_Tests
//
//  Created by Mikhail Churbanov on 15/06/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import ProxyResolver

class TestDelegate: ProxyResolverDelegate {

    var didStopExpectation: XCTestExpectation?
    var didResolveExpectation: XCTestExpectation?

    var resolveUrl: URL?
    var resolveResult: ProxyResolutionResult?
    var resolveNextRoutine: ResolveNextRoutine?

    func proxyResolver(_ proxyResolver: ProxyResolver, didResolve result: ProxyResolutionResult, for url: URL,
                       resolveNext: ResolveNextRoutine?) {
        resolveUrl = url
        resolveResult = result
        resolveNextRoutine = resolveNext
        didResolveExpectation?.fulfill()
    }

    func clearResults() {
        resolveUrl = nil
        resolveResult = nil
    }

}

class DelegateTests: XCTestCase {

    var testConfigProvider: MockProxyConfigProvider!
    var testScriptFetcher: MockProxyUrlFetcher!
    var testDelegate: TestDelegate! // swiftlint:disable:this weak_delegate
    var proxy: ProxyResolver!

    override func setUp() {
        super.setUp()
        testConfigProvider = MockProxyConfigProvider()
        testScriptFetcher = MockProxyUrlFetcher()
        testDelegate = TestDelegate()
        let testConfig = ProxyResolverConfig()
        testConfig.configProvider = testConfigProvider
        testConfig.scriptFetcher = testScriptFetcher
        proxy = ProxyResolver(config: testConfig)
        proxy.delegate = testDelegate
    }

    override func tearDown() {
        super.tearDown()
        testDelegate.clearResults()
    }

    func testNoProxyResolve() {
        let resolveExpectation = XCTestExpectation(description: "didResolve called")
        let stopExpectation = XCTestExpectation(description: "didStop called")
        testDelegate.didResolveExpectation = resolveExpectation
        testDelegate.didStopExpectation = stopExpectation

        var config = TestConfigs.http.config
        config.append(TestConfigs.noProxy.config[0])
        testConfigProvider.setTestConfig(config)

        proxy.resolve(for: TestConfigs.httpUrl)
        wait(for: [resolveExpectation], timeout: TestConfigs.timeout)
        XCTAssertNotNil(testDelegate.resolveUrl)
        XCTAssert(testDelegate.resolveUrl! == TestConfigs.httpUrl)
        XCTAssertNotNil(testDelegate.resolveResult)
        switch testDelegate.resolveResult! {
        case .error(let error):
            XCTAssert(false, "Resulted with error: \(error)")

        default:
            break
        }
        XCTAssertNotNil(testDelegate.resolveNextRoutine)

        testDelegate.resolveNextRoutine!()
        wait(for: [resolveExpectation], timeout: TestConfigs.timeout)
        XCTAssertNotNil(testDelegate.resolveUrl)
        XCTAssert(testDelegate.resolveUrl! == TestConfigs.httpUrl)
        XCTAssertNotNil(testDelegate.resolveResult)
        switch testDelegate.resolveResult! {
        case .error(let error):
            XCTAssert(false, "Resulted with error: \(error)")

        default:
            break
        }
    }

}
