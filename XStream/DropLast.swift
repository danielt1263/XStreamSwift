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
	/// Returns a Stream containing all but the specified number of final
	/// events.
	///
	/// The stream must be finite. If the number of events to drop exceeds
	/// the number of events in the stream, the result is an empty
	/// stream.
	///
	/// - Parameter n: The number of events to drop off the end of the
	///   stream. `n` must be greater than or equal to zero.
	/// - Returns: A Stream leaving off the specified number of elements.
	///
	/// - Complexity: O(*n*), where *n* is the length of the sequence.
	public func dropLast(_ n: Int) -> Stream {
		precondition(n >= 0)
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
