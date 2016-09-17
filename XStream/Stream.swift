//
//  Stream.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/3/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import Foundation


public
protocol StreamConvertable
{
	associatedtype Value
	
	func asStream() -> Stream<Value>
}


public
class Stream<T>: StreamConvertable
{
	public typealias Value = T
	public typealias ListenerType = AnyListener<Value>

	/// Creates a Stream that does nothing. It never emits any event.
	public convenience init() {
		self.init(producer: AnyProducer<Value>(start: { _ in }, stop: { }))
	}
	
	/// Creates a Stream that immediately emits the "complete" notification when started, and that's it.
	open static func emptyStream<Value>() -> Stream<Value> {
		let producer = AnyProducer<Value>(start: { $0.complete() }, stop: { })
		return Stream<Value>(producer: producer)
	}
	
	/// Creates a Stream that immediately emits an "error" notification with the value you passed as the `error` argument when the stream starts, and that's it.
	public convenience init(error: Error) {
		self.init(producer: AnyProducer<Value>(start: { $0.error(error) }, stop: { }))
	}
	
	/// Creates a Stream that immediately emits the arguments that you give to of, then completes.
	public convenience init(of args: Value...) {
		self.init(producer: FromArrayProducer(array: args))
	}
	
	/// Converts an array to a stream. The returned stream will emit synchronously all the items in the array, and then complete.
	public convenience init(fromArray array: [Value]) {
		self.init(producer: FromArrayProducer(array: array))
	}
	
	/// Creates a new Stream given a Producer.
	public init<P: Producer>(producer: P) where P.ProducerValue == Value {
		self.producer = AnyProducer<Value>(producer)
	}
	
	public typealias RemoveToken = String
	
	/// Adds a Listener to the Stream.
	open func add<L: Listener>(listener: L) -> RemoveToken where Value == L.ListenerValue {
		return _add(AnyListener(listener))
	}
	
	/// Removes a Listener from the Stream, assuming the Listener was added to it.
	open func removeListener(_ token: RemoveToken) {
		remove(token)
	}

	open func asStream() -> Stream<Value> {
		return self
	}

	func next(_ value: Value) {
		debugListener?.next(value)
		notify { $0.next(value) }
	}
	
	func complete() {
		debugListener?.complete()
		notify { $0.complete() }
		tearDown()
	}
	
	func error(_ error: Error) {
		debugListener?.error(error)
		notify { $0.error(error) }
		tearDown()
	}
	
	func _add(_ listener: ListenerType) -> RemoveToken {
		guard ended == false else { return "" }
		let removeToken = UUID().uuidString
		listeners[removeToken] = listener
		if listeners.count == 1 {
			if let stopID = stopID {
				cancel_delay(stopID)
			}
			else {
				producer.start(for: AnyListener(next: self.next, complete: self.complete, error: self.error))
			}
		}
		return removeToken
	}
	
	private let producer: AnyProducer<Value>
	private var listeners: [String: ListenerType] = [:]
	private var debugListener: ListenerType? = nil
	private var ended = false
	private var stopID: dispatch_cancelable_closure? = nil
	
	private func notify(_ fn: (ListenerType) -> Void) {
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
	
	private func remove(_ token: RemoveToken) {
		listeners.removeValue(forKey: token)
		if listeners.count == 0 {
			stopID = delay(0.1) {
				self.producer.stop()
			}
		}
	}
}

/// Creates a stream that periodically emits incremental numbers, every `period` seconds.
public func periodicStream(_ period: TimeInterval) -> Stream<Int> {
	return Stream(producer: PeriodicProducer(period: period))
}

let noListener = AnyListener<Void>(next: { _ in }, complete: { }, error: { _ in })
