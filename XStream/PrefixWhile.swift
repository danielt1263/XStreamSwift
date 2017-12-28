//
//  PrefixWhile.swift
//  XStream
//
//  Created by Daniel Tartaglia on 12/28/17.
//  Copyright © 2017 Daniel Tartaglia. MIT License.
//

import Foundation


extension Stream
{
	/// Returns a Stream containing the initial, consecutive events that
	/// satisfy the given predicate.
	///
	/// If `predicate` matches every event in the stream, the resulting
	/// stream contains every event of the stream.
	///
	/// - Parameter predicate: A closure that takes a value of the stream as
	///   its argument and returns a Boolean value indicating whether the
	///   value should be included in the result.
	/// - Returns: A stream that emits the initial, consecutive elements that
	///   satisfy `predicate`.
	public func prefix(while predicate: @escaping (Value) throws -> Bool) -> Stream {
		let op = PrefixWhileOperator(predicate: predicate, inStream: self)
		return Stream(producer: op)
	}
}


private
final class PrefixWhileOperator<T>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = T

	let inStream: Stream<T>
	var removeToken: Stream<T>.RemoveToken?
	var outStream: AnyListener<T>?
	let predicate: (T) throws -> Bool
	var active = true

	init(predicate: @escaping (T) throws -> Bool, inStream: Stream<T>) {
		self.inStream = inStream
		self.predicate = predicate
	}

	func start<L : Listener>(for listener: L) where ProducerValue == L.ListenerValue {
		outStream = AnyListener(listener)
		removeToken = inStream.add(listener: self)
		active = true
	}

	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		outStream = nil
	}

	func next(_ value: ListenerValue) {
		do {
			if active {
				if try predicate(value) {
					outStream?.next(value)
				}
				else {
					active = false
					outStream?.complete()
				}
			}
		}
		catch {
			outStream?.error(error)
		}
	}

	func complete() {
		outStream?.complete()
	}

	func error(_ error: Error) {
		outStream?.error(error)
	}

}
