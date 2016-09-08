//
//  StartWith.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/4/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import Foundation


extension Stream
{
	/// Prepends the given `initial` value to the sequence of events emitted by the input stream. The returned stream is a `MemoryStream`, which means it is already `remember()`'d.
	public func startWith(initial: Value) -> MemoryStream<Value> {
		let op = StartWithOperator(value: initial, inStream: self)
		return MemoryStream(producer: op)
	}
}


class StartWithOperator<T>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = T
	
	let inStream: Stream<T>
	var removeToken: Stream<T>.RemoveToken?
	var outStream: AnyListener<T>?
	var value: T
	
	init(value: T, inStream: Stream<T>) {
		self.inStream = inStream
		self.value = value
	}
	
	func start<L : Listener where ProducerValue == L.ListenerValue>(listener: L) {
		outStream = AnyListener(listener)
		outStream!.next(value)
		removeToken = inStream.addListener(self)
	}
	
	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		outStream = nil
	}
	
	func next(value: ListenerValue) {
		outStream?.next(value)
	}
	
	func complete() {
		outStream?.complete()
	}
	
	func error(err: ErrorType) {
		outStream?.error(err)
	}
	
}
