//
//  Stream.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/3/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import Foundation


public
class Stream<T>
{
	public typealias Value = T
	public typealias ListenerType = AnyListener<Value>

	/// Creates a Stream that does nothing. It never emits any event.
	public convenience init() {
		self.init(producer: AnyProducer<T>(start: { _ in }, stop: { }))
	}
	
	/// Creates a Stream that immediately emits the "complete" notification when started, and that's it.
	public static func emptyStream<T>() -> Stream<T> {
		let producer = AnyProducer<T>(start: { $0.complete() }, stop: { })
		return Stream<T>(producer: producer)
	}
	
	/// Creates a Stream that immediately emits an "error" notification with the value you passed as the `error` argument when the stream starts, and that's it.
	public convenience init(error: ErrorType) {
		self.init(producer: AnyProducer<T>(start: { $0.error(error) }, stop: { }))
	}
	
	/// Converts an array to a stream. The returned stream will emit synchronously all the items in the array, and then complete.
	public convenience init(fromArray array: [Value]) {
		self.init(producer: FromArrayProducer(array: array))
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
	
	func add(listener: ListenerType) -> RemoveToken {
		guard ended == false else { return "" }
		let removeToken = NSUUID().UUIDString
		listeners[removeToken] = listener
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
	
	private let producer: AnyProducer<Value>
	private var listeners: [String: ListenerType] = [:]
	private var debugListener: ListenerType? = nil
	private var ended = false
	private var stopID: dispatch_cancelable_closure? = nil
	
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
	
	private func remove(token: RemoveToken) {
		listeners.removeValueForKey(token)
		if listeners.count == 0 {
			stopID = delay(0.1) {
				self.producer.stop()
			}
		}
	}
}

/// Creates a stream that periodically emits incremental numbers, every `period` seconds.
public func periodicStream(period: NSTimeInterval) -> Stream<Int> {
	return Stream(producer: PeriodicProducer(period: period))
}

let noListener = AnyListener<Void>(next: { _ in }, complete: { }, error: { _ in })
