//
//  MemoryStream.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/3/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import Foundation


public
final class MemoryStream<T>: Stream<T>
{
	/// Creates a new Stream given a Producer.
	public override init<P: Producer where P.ProducerValue == Value>(producer: P) {
		super.init(producer: AnyProducer(producer))
	}
	
	override func next(value: Value) {
		lastValue = value
		nextCalled = true
		super.next(value)
	}
	
	override func add(listener: ListenerType) -> RemoveToken {
		if let value = lastValue where nextCalled {
			listener.next(value)
		}
		let result = super.add(listener)
		return result
	}

	private var lastValue: Value? = nil
	private var nextCalled = false
	
}
