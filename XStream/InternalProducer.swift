//
//  InternalProducer.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/3/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import Foundation


final class FromArrayProducer<T>: Producer
{
	typealias ProducerValue = T
	
	init(array: [T]) {
		self.array = array
	}
	
	func start<L : Listener>(for listener: L) where ProducerValue == L.ListenerValue {
		for item in array {
			listener.next(item)
		}
		listener.complete()
	}
	
	func stop() { }
	
	private let array: [T]
}


final class PeriodicProducer: Producer
{
	typealias ProducerValue = Int
	
	init(period: TimeInterval) {
		timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global(qos: .userInitiated))
		let timeInterval = DispatchTimeInterval.milliseconds(Int(period * 1000.0))
		let start = DispatchTime.now() + timeInterval
		timer.schedule(deadline: start, repeating: timeInterval)
	}
	
	func start<L : Listener>(for listener: L) where ProducerValue == L.ListenerValue {
		timer.setEventHandler {
			listener.next(self.count)
			self.count += 1
		}
		timer.resume()
	}
	
	func stop() {
		timer.suspend()
		count = 0
	}
	
	private var count = 0
	private var timer: DispatchSourceTimer
}
