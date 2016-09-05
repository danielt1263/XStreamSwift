//
//  Drop.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/4/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import Foundation


extension Stream
{
	public func drop(count: Int) -> Stream {
		let op = DropOperator(count: count, inStream: self)
		return Stream(producer: op)
	}
}


class DropOperator<T>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = T
	
	let inStream: Stream<T>
	var removeToken: Stream<T>.RemoveToken?
	var outStream: AnyListener<T>?
	let max: Int
	var dropped = 0
	
	init(count: Int, inStream: Stream<T>) {
		self.inStream = inStream
		self.max = count
	}
	
	func start<L : Listener where ProducerValue == L.ListenerValue>(listener: L) {
		outStream = AnyListener(listener)
		removeToken = inStream.addListener(self)
		dropped = 0
	}
	
	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		outStream = nil
	}
	
	func next(value: ListenerValue) {
		if dropped < max {
			dropped += 1
		}
		else {
			outStream?.next(value)
		}
	}
	
	func complete() { outStream?.complete() }
	
	func error(err: ErrorType) { outStream?.error(err) }
	
}
