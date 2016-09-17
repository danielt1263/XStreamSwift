//
//  MemoryStreamTests.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/4/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import XCTest
@testable import XStream


final class MemoryStreamTests: XCTestCase
{
	func testRemembersLastNext() {
		let stream = MemoryStream<Int>()
		var nextCalled = false
		
		stream.next(1)
		let _ = stream.add(listener: AnyListener<Int>(next: { val in
			XCTAssertEqual(val, 1)
			nextCalled = true
		}, complete: {
		}, error: { _ in
		}))
		
		XCTAssert(nextCalled)
	}
	
}
