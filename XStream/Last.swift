//
//  Last.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/4/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import Foundation


extension Stream
{
	/// When the input stream completes, the output stream will emit the last event emitted by the input stream, and then will also complete.
	public func last() -> Stream {
		let op = LastOperator(inStream: self)
		return Stream(producer: op)
	}
}


class LastOperator<T>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = T
	
	let inStream: Stream<T>
	var removeToken: Stream<T>.RemoveToken?
	var outStream: AnyListener<T>?
	var last: T?
	
	init(inStream: Stream<T>) {
		self.inStream = inStream
	}
	
	func start<L : Listener where ProducerValue == L.ListenerValue>(listener: L) {
		outStream = AnyListener(listener)
		removeToken = inStream.addListener(self)
	}
	
	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		outStream = nil
	}
	
	func next(value: ListenerValue) {
		last = value
	}
	
	func complete() {
		if let last = last {
			outStream?.next(last)
		}
		outStream?.complete()
	}
	
	func error(err: ErrorType) { outStream?.error(err) }
	
}
