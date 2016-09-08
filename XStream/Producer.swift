//
//  Producer.swift
//  PeopleCRMSwift
//
//  Created by Daniel Tartaglia on 9/3/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import Foundation


public
protocol Producer: class
{
	associatedtype ProducerValue

	func start<L: Listener where ProducerValue == L.ListenerValue>(listener: L)
	func stop()
}


public
final class AnyProducer<T>: Producer
{
	public typealias ProducerValue = T
	public typealias ListenerType = AnyListener<T>
	
	init<P: Producer where P.ProducerValue == ProducerValue>(_ producer: P) {
		_start = producer.start
		_stop = producer.stop
	}

	public init(start: (ListenerType) -> Void, stop: () -> Void = { }) {
		_start = start
		_stop = stop
	}

	public func start<L: Listener where ProducerValue == L.ListenerValue>(listener: L) {
		_start(ListenerType(listener))
	}
	
	public func stop() {
		_stop()
	}
	
	private let _start: (ListenerType) -> Void
	private let _stop: () -> Void
}
