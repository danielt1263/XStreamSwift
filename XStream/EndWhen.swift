//
//  EndWhen.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/4/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import Foundation


extension Stream
{
	/**
	Uses another stream to determine when to complete the current stream.

	When the given `other` stream emits an event or completes, the output stream will complete. Before that happens, the output stream will behaves like the input stream.
	*/
	public func endWhen<U>(_ other: Stream<U>) -> Stream<Value> {
		let op = EndWhenOperator(other: other, inStream: self)
		return Stream<Value>(producer: op)
	}
}

private
final class OtherListener<U>: Listener
{
	typealias ListenerValue = U

	var callback: () -> Void = { }

	func next(_ value: ListenerValue) {
		callback()
	}

	func complete() {
		callback()
	}

	func error(_ error: Error) {

	}
}

private
final class EndWhenOperator<T, U>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = T

	let inStream: Stream<T>
	var removeToken: Stream<T>.RemoveToken?
	var outStream: AnyListener<T>?
	let otherStream: Stream<U>
	let otherListener: OtherListener<U>
	var otherRemoveToken: Stream<U>.RemoveToken?

	init(other: Stream<U>, inStream: Stream<T>) {
		self.inStream = inStream
		self.otherStream = other
		self.otherListener = OtherListener()
	}

	func start<L : Listener>(for listener: L) where ProducerValue == L.ListenerValue {
		outStream = AnyListener(listener)
		removeToken = inStream.add(listener: self)
		otherRemoveToken = otherStream.add(listener: otherListener)
		self.otherListener.callback = {
			self.outStream?.complete()
		}
	}

	func stop() {
		guard let removeToken = removeToken else { return }
		guard let otherRemoveToken = otherRemoveToken else { return }

		inStream.removeListener(removeToken)
		outStream = nil
		otherStream.removeListener(otherRemoveToken)
	}

	func next(_ value: ListenerValue) {
		outStream?.next(value)
	}

	func complete() {
		outStream?.complete()
	}

	func error(_ error: Error) {
		outStream?.error(error)
	}
	
}
