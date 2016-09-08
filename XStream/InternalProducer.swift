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
	
	func start<L : Listener where ProducerValue == L.ListenerValue>(listener: L) {
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
	
	init(period: NSTimeInterval) {
		timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
		
		let interval = period * NSTimeInterval(NSEC_PER_SEC)
		dispatch_source_set_timer(timer, dispatch_time( DISPATCH_TIME_NOW, Int64(interval)), UInt64(interval), 0)
	}
	
	func start<L : Listener where ProducerValue == L.ListenerValue>(listener: L) {
		dispatch_source_set_event_handler(timer) {
			listener.next(self.count)
			self.count += 1
		}
		dispatch_resume(timer)
	}
	
	func stop() {
		dispatch_suspend(timer)
		count = 0
	}
	
	private var count = 0
	private var timer: dispatch_source_t
}
