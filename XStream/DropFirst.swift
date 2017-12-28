//
//  DropFirst.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/4/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import Foundation


extension Stream
{
	/// Ignores the first `count` events from the input stream, and then after that starts forwarding events from the input stream to the output stream.
	public func dropFirst(_ n: Int) -> Stream {
		let op = DropFirstOperator(count: n, inStream: self)
		return Stream(producer: op)
	}
}


private
final class DropFirstOperator<T>: Listener, Producer
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
	
	func start<L : Listener>(for listener: L) where ProducerValue == L.ListenerValue {
		outStream = AnyListener(listener)
		removeToken = inStream.add(listener: self)
		dropped = 0
	}
	
	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		outStream = nil
	}
	
	func next(_ value: ListenerValue) {
		if dropped < max {
			dropped += 1
		}
		else {
			outStream?.next(value)
		}
	}
	
	func complete() {
		outStream?.complete()
	}
	
	func error(_ error: Error) {
		outStream?.error(error)
	}
	
}
