//
//  DropLast.swift
//  XStream
//
//  Created by Daniel Tartaglia on 12/28/17.
//  Copyright © 2017 Daniel Tartaglia. MIT License.
//

import Foundation


extension Stream
{
	/// Forwards events from the input stream to the output stream with a buffer of `count` events. Completes when the input stream completes with the result that the output stream will not produce the last `n` elements.
	public func dropLast(_ n: Int) -> Stream {
		let op = DropLastOperator(count: n, inStream: self)
		return Stream(producer: op)
	}
}


private
final class DropLastOperator<T>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = T

	let inStream: Stream<T>
	var removeToken: Stream<T>.RemoveToken?
	var outStream: AnyListener<T>?
	let max: Int
	var buffer = [T]()

	init(count: Int, inStream: Stream<T>) {
		self.inStream = inStream
		self.max = count
	}

	func start<L : Listener>(for listener: L) where ProducerValue == L.ListenerValue {
		outStream = AnyListener(listener)
		removeToken = inStream.add(listener: self)
		buffer = []
	}

	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		outStream = nil
	}

	func next(_ value: ListenerValue) {
		buffer.insert(value, at: 0)
		if buffer.count > max {
			outStream?.next(buffer.popLast()!)
		}
	}

	func complete() {
		outStream?.complete()
	}

	func error(_ error: Error) {
		outStream?.error(error)
	}

}
