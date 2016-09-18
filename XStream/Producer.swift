//
//  Producer.swift
//  PeopleCRMSwift
//
//  Created by Daniel Tartaglia on 9/3/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import Foundation


public
protocol Producer
{
	associatedtype ProducerValue

	func start<L: Listener>(for listener: L) where ProducerValue == L.ListenerValue
	func stop()
}


public
final class AnyProducer<T>: Producer
{
	public typealias ProducerValue = T
	public typealias ListenerType = AnyListener<T>
	
	public convenience init<P: Producer>(_ producer: P) where P.ProducerValue == ProducerValue {
		self.init(start: { producer.start(for: $0) }, stop: producer.stop)
	}

	public init(start: @escaping (ListenerType) -> Void, stop: @escaping () -> Void = { }) {
		_start = start
		_stop = stop
	}

	public func start<L: Listener>(for listener: L) where ProducerValue == L.ListenerValue {
		_start(AnyListener(listener))
	}
	
	public func stop() {
		_stop()
	}
	
	private let _start: (ListenerType) -> Void
	private let _stop: () -> Void
}
