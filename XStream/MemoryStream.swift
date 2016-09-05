//
//  MemoryStream.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/3/16.
//  Copyright © 2016 Daniel Tartaglia. All rights reserved.
//

import Foundation


public final
class MemoryStream<T>
{
	public typealias Value = T
	public typealias ListenerType = AnyListener<Value>

	/// Creates a Stream that does nothing. It never emits any event.
	public init() {
		producer = AnyProducer<T>(start: { _ in }, stop: { })
	}
	
	/// Creates a new Stream given a Producer.
	public init<P: Producer where P.ProducerValue == Value>(producer: P) {
		self.producer = AnyProducer(producer)
	}
	
	public typealias RemoveToken = String

	/// Adds a Listener to the Stream.
	public func addListener<L: Listener where Value == L.ListenerValue>(listener: L) -> RemoveToken {
		return add(AnyListener(listener))
	}
	
	/// Removes a Listener from the Stream, assuming the Listener was added to it.
	public func removeListener(token: RemoveToken) {
		remove(token)
	}
	
	func next(value: Value) {
		debugListener?.next(value)
		lastValue = value
		nextCalled = true
		notify { $0.next(value) }
	}
	
	func complete() {
		debugListener?.complete()
		notify { $0.complete() }
		tearDown()
	}
	
	func error(err: ErrorType) {
		debugListener?.error(err)
		notify { $0.error(err) }
		tearDown()
	}
	
	private let producer: AnyProducer<Value>
	private var listeners: [String: ListenerType] = [:]
	private var debugListener: ListenerType?
	private var ended = false
	private var stopID: dispatch_cancelable_closure?
	private var lastValue: Value?
	private var nextCalled = false

	private func notify(@noescape fn: (ListenerType) -> Void) {
		for listener in listeners.values {
			fn(listener)
		}
	}
	
	private func tearDown() {
		guard listeners.isEmpty == false else { return }
		producer.stop()
		listeners = [:]
		ended = true
	}
	
	private func add(listener: ListenerType) -> RemoveToken {
		guard ended == false else { return "" }
		let removeToken = NSUUID().UUIDString
		listeners[removeToken] = listener
		if let value = lastValue where nextCalled {
			listener.next(value)
		}
		if listeners.count == 1 {
			if let stopID = stopID {
				cancel_delay(stopID)
			}
			else {
				producer.start(AnyListener(next: self.next, complete: self.complete, error: self.error))
			}
		}
		return removeToken
	}
	
	private func remove(token: RemoveToken) {
		listeners.removeValueForKey(token)
		if listeners.count == 0 {
			stopID = delay(0.1) {
				self.producer.stop()
			}
		}
	}

}
