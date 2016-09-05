//
//  EndWhen.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/4/16.
//  Copyright © 2016 Daniel Tartaglia. All rights reserved.
//

import Foundation


extension Stream
{
	public func endWhen<U>(other: Stream<U>) -> Stream<Value> {
		let op = EndWhenOperator(other: other, inStream: self)
		return Stream<Value>(producer: op)
	}
}


class OtherListener<U>: Listener
{
	typealias ListenerValue = U
	
	var callback: () -> Void = { }

	func next(value: ListenerValue) {
		callback()
	}
	
	func complete() {
		callback()
	}

	func error(err: ErrorType) {
		
	}
}

class EndWhenOperator<T, U>: Listener, Producer
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
	
	func start<L : Listener where ProducerValue == L.ListenerValue>(listener: L) {
		outStream = AnyListener(listener)
		removeToken = inStream.addListener(self)
		otherRemoveToken = otherStream.addListener(otherListener)
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
