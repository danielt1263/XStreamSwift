//
//  Merge.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/7/16.
//  Copyright © 2016 Daniel Tartaglia. All rights reserved.
//

import XCTest
@testable import XStream


class merge: XCTestCase
{
	func testMergesStreams() {
		let expectation = self.expectationWithDescription("testMergesStreams")
		let stream = Stream(streams: [periodicStream(0.8).take(2), periodicStream(1).take(2)])
		let expected = [0, 0, 1, 1]
		var index = 0
		var completeCalled = false
		
		stream.add(AnyListener<Int>(next: { val in
			XCTAssertEqual(val, expected[index])
			index += 1
		}, complete: {
			completeCalled = true
			expectation.fulfill()
		}, error: { _ in
			XCTFail()
		}))
		
		self.waitForExpectationsWithTimeout(10.0) { _ in
			XCTAssertEqual(index, expected.count)
			XCTAssert(completeCalled)
		}
	}
}
