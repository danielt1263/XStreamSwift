//
//  Suffix.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/4/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import Foundation


extension Stream
{
	/// Returns a Stream, that emits up to the given maximum length, containing the
	/// final events of the stream.
	///
	/// The stream must be finite. If the maximum length exceeds the number
	/// of events in the stream, the result contains all the events in
	/// the stream.
	///
	/// - Parameter maxLength: The maximum number of events to emit. The
	///   value of `maxLength` must be greater than or equal to zero.
	/// - Returns: A stream terminating at the end of this stream with
	///   at most `maxLength` elements.
	public func suffix(_ maxLength: Int) -> Stream {
		precondition(maxLength >= 0)
		let op = SuffixOperator(maxLength: maxLength, inStream: self)
		return Stream(producer: op)
	}
}


private
final class SuffixOperator<T>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = T
	
	let inStream: Stream<T>
	var removeToken: Stream<T>.RemoveToken?
	var outStream: AnyListener<T>?
	let max: Int
	var last = [T]()
	
	init(maxLength: Int, inStream: Stream<T>) {
		self.inStream = inStream
		max = maxLength
	}
	
	func start<L : Listener>(for listener: L) where ProducerValue == L.ListenerValue {
		outStream = AnyListener(listener)
		removeToken = inStream.add(listener: self)
		last = []
	}
	
	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		outStream = nil
	}
	
	func next(_ value: ListenerValue) {
		last.append(value)
		if last.count > max {
			last.removeFirst()
		}
	}
	
	func complete() {
		for value in last {
			outStream?.next(value)
		}
		outStream?.complete()
	}
	
	func error(_ error: Error) { outStream?.error(error) }
	
}
