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
	/// Returns a Stream containing all but the given number of initial
	/// events.
	///
	/// If the number of events to drop exceeds the number of events in
	/// the stream, the result is an empty stream.
	///
	/// - Parameter n: The number of elements to drop from the beginning of
	///   the sequence. `n` must be greater than or equal to zero.
	/// - Returns: A Stream starting after the specified number of
	///   elements.
	public func dropFirst(_ n: Int) -> Stream {
		precondition(n >= 0)
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
