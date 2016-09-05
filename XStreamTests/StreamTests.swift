//
//  XStreamTests.swift
//  XStreamTests
//
//  Created by Daniel Tartaglia on 9/3/16.
//  Copyright © 2016 Daniel Tartaglia. All rights reserved.
//

import XCTest
@testable import XStream

class StreamTests: XCTestCase {

	func testAddingListinerStartsProducer() {
		var started: Bool = false
		let producer = AnyProducer<Void>(start: { _ in started = true }, stop: { })
		let listener = AnyListener<Void>(next: { _ in }, complete: { }, error: { _ in })

		let stream = Stream(producer: producer)
		stream.addListener(listener)
		
		XCTAssert(started == true)
	}
	
	func testAddingTwoListnersOnlyStartsProducerOnce() {
		var startCount: Int = 0
		let producer = AnyProducer<Void>(start: { _ in startCount += 1 }, stop: { })
		let listener = AnyListener<Void>(next: { _ in }, complete: { }, error: { _ in })
		
		let stream = Stream(producer: producer)
		stream.addListener(listener)
		stream.addListener(listener)

		XCTAssert(startCount == 1)
	}
	
	func testRemovingLastListnerStopsProducer() {
		let expectation = self.expectationWithDescription("testRemovingLastListnerStopsProducer")
		var stopCount: Int = 0
		let producer = AnyProducer<Void>(start: { _ in }, stop: { stopCount += 1; expectation.fulfill() })
		let listener = AnyListener<Void>(next: { _ in }, complete: { }, error: { _ in })
		let stream = Stream(producer: producer)
		let token1 = stream.addListener(listener)
		let token2 = stream.addListener(listener)
		
		stream.removeListener(token1)
		stream.removeListener(token2)

		self.waitForExpectationsWithTimeout(0.2) { _ in
			XCTAssert(stopCount == 1)
		}
	}
	
	func testSwapListenerDoesNotRestartProducer() {
		var startCount: Int = 0
		var stopCount: Int = 0
		let producer = AnyProducer<Void>(start: { _ in startCount += 1 }, stop: { stopCount += 1 })
		let listener = AnyListener<Void>(next: { _ in }, complete: { }, error: { _ in })
		let stream = Stream(producer: producer)
		let token = stream.addListener(listener)
		
		stream.removeListener(token)
		stream.addListener(listener)
		
		XCTAssert(startCount == 1)
		XCTAssert(stopCount == 0)
	}
	
	func testPeriodicProducer() {
		let expectation = self.expectationWithDescription("testPeriodicStream")
		let producer = PeriodicProducer(period: 0.2)
		let listener = AnyListener<Int>(next: { val in
			if val == 3 {
				expectation.fulfill()
			}
			
		}, complete: { }, error: { _ in })

		producer.start(listener)

		delay(0.8) { 
			producer.stop()
		}

		self.waitForExpectationsWithTimeout(1.0) { _ in
			producer.stop()
		}
	}
}
