//
//  Prefix.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/4/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import Foundation


extension Stream
{
	/// Returns a Stream, up to the specified maximum length, containing
	/// the initial events of the stream.
	///
	/// If the maximum length exceeds the number of events in the stream,
	/// the result contains all the events in the stream.
	///
	/// - Parameter maxLength: The maximum number of events to emit.
	///   `maxLength` must be greater than or equal to zero.
	/// - Returns: A Stream starting at the beginning of this stream
	///   with at most `maxLength` elements.
	public func prefix(_ maxLength: Int) -> Stream {
		precondition(maxLength >= 0)
		let op = PrefixOperator(maxLength: maxLength, inStream: self)
		return Stream(producer: op)
	}
}


private
final class PrefixOperator<T>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = T
	
	let inStream: Stream<T>
	var removeToken: Stream<T>.RemoveToken?
	var outStream: AnyListener<T>?
	let max: Int
	var taken = 0
	
	init(maxLength: Int, inStream: Stream<T>) {
		self.inStream = inStream
		self.max = maxLength
	}
	
	func start<L : Listener>(for listener: L) where ProducerValue == L.ListenerValue {
		outStream = AnyListener(listener)
		removeToken = inStream.add(listener: self)
		taken = 0
	}
	
	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		outStream = nil
	}
	
	func next(_ value: ListenerValue) {
		outStream?.next(value)
		taken += 1
		if taken == max {
			outStream?.complete()
		}
	}
	
	func complete() { outStream?.complete() }
	
	func error(_ error: Error) { outStream?.error(error) }

}
