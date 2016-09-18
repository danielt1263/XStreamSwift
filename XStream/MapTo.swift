//
//  MapTo.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/4/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import Foundation


extension Stream
{
	/// It's like `map`, but always transforms each input event to the same constant value on the output Stream.
	public func mapTo<U>(_ value: U) -> Stream<U> {
		let op = MapToOperator(value: value, inStream: self)
		return Stream<U>(producer: op)
	}
}


private
final class MapToOperator<T, U>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = U
	
	let inStream: Stream<T>
	var removeToken: Stream<T>.RemoveToken?
	var outStream: AnyListener<U>?
	let toValue: U
	
	init(value: U, inStream: Stream<T>) {
		self.inStream = inStream
		self.toValue = value
	}
	
	func start<L : Listener>(for listener: L) where ProducerValue == L.ListenerValue {
		outStream = AnyListener(listener)
		removeToken = inStream.add(listener: self)
	}
	
	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		outStream = nil
	}
	
	func next(_ value: ListenerValue) {
		outStream?.next(toValue)
	}
	
	func complete() { outStream?.complete() }
	
	func error(_ error: Error) { outStream?.error(error) }
	
}
