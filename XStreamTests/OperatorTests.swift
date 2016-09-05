//
//  MapTests.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/4/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import XCTest
@testable import XStream


class OperatorTests: XCTestCase {
    
	func testMap() {
		let stream = Stream(fromArray: [1, 2, 3]).map { $0 * 10 }
		let expected = [10, 20, 30]
		var index = 0
		var completeCalled = false
		
		stream.addListener(AnyListener<Int>(next: { val in
			XCTAssert(val == expected[index])
			index += 1
		}, complete: {
			completeCalled = true
		}, error: { _ in
			XCTFail()
		}))
		
		XCTAssert(completeCalled)
		XCTAssert(index == expected.count)
	}

	func testTake() {
		let stream = Stream(fromArray: [1, 2, 3, 4, 5]).take(3)
		let expected = [1, 2, 3]
		var index = 0
		var completeCalled = false
		
		stream.addListener(AnyListener<Int>(next: { val in
			XCTAssert(val == expected[index])
			index += 1
		}, complete: {
			completeCalled = true
		}, error: { _ in
			XCTFail()
		}))
		
		XCTAssert(completeCalled)
		XCTAssert(index == expected.count)
	}
	
	func testDrop() {
		let stream = Stream(fromArray: [1, 2, 3, 4, 5]).drop(3)
		let expected = [4, 5]
		var index = 0
		var completeCalled = false
		
		stream.addListener(AnyListener<Int>(next: { val in
			XCTAssert(val == expected[index])
			index += 1
		}, complete: {
			completeCalled = true
		}, error: { _ in
			XCTFail()
		}))
		
		XCTAssert(completeCalled)
		XCTAssert(index == expected.count)
	}

	func testLast() {
		let stream = Stream(fromArray: [1, 2, 3, 4, 5]).last()
		let expected = [5]
		var index = 0
		var completeCalled = false
		
		stream.addListener(AnyListener<Int>(next: { val in
			XCTAssert(val == expected[index])
			index += 1
		}, complete: {
			completeCalled = true
		}, error: { _ in
			XCTFail()
		}))
		
		XCTAssert(completeCalled)
		XCTAssert(index == expected.count)
	}
	
	func testStartWith() {
		let stream = Stream(fromArray: [1, 2, 3, 4, 5]).startWith(0)
		let expected = [0, 1, 2, 3, 4, 5]
		var index = 0
		var completeCalled = false
		
		stream.addListener(AnyListener<Int>(next: { val in
			XCTAssertEqual(val, expected[index])
			index += 1
		}, complete: {
			completeCalled = true
		}, error: { _ in
			XCTFail()
		}))
		
		XCTAssert(completeCalled)
		XCTAssert(index == expected.count)
	}
	
	func testEndWhenCompletesOnNext() {
		let expectation = self.expectationWithDescription("testEndWhenCompletesOnNext")
		let source = periodicStream(0.2)
		let other = periodicStream(0.9)
		let stream = source.endWhen(other)
		let expected = [0, 1, 2, 3]
		var index = 0

		stream.addListener(AnyListener<Int>(next: { val in
			XCTAssert(val == expected[index])
			index += 1
		}, complete: {
			XCTAssertEqual(index, expected.count)
			expectation.fulfill()
		}, error: { _ in
			XCTFail()
		}))
		
		self.waitForExpectationsWithTimeout(10.0) { _ in }
	}
	
	func testFold() {
		let expectation = self.expectationWithDescription("testFold")
		let stream = periodicStream(0.20).take(4).fold(0) { $0.0 + $0.1 }
		let expected = [0, 0, 1, 3, 6]
		var index = 0
		
		stream.addListener(AnyListener<Int>(next: { val in
			XCTAssert(val == expected[index])
			index += 1
		}, complete: {
			XCTAssertEqual(index, expected.count)
			expectation.fulfill()
		}, error: { _ in
			XCTFail()
		}))
		
		self.waitForExpectationsWithTimeout(1.0) { _ in }
	}

}
