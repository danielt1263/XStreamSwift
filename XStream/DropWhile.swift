//
//  DropWhile.swift
//  XStream
//
//  Created by Daniel Tartaglia on 12/28/17.
//  Copyright © 2017 Daniel Tartaglia. MIT License.
//

import Foundation


extension Stream
{
	/// Returns a Stream that skips events while `predicate` returns
	/// `true` and emits the remaining events.
	///
	/// - Parameter predicate: A closure that takes an value of the
	///   Stream as its argument and returns `true` if the value should
	///   be skipped or `false` if it should be included. Once the predicate
	///   returns `false` it will not be called again.
	public func drop(while predicate: @escaping (Value) throws -> Bool) -> Stream {
		let op = DropWhileOperator(predicate: predicate, inStream: self)
		return Stream(producer: op)
	}
}


private
final class DropWhileOperator<T>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = T

	let inStream: Stream<T>
	var removeToken: Stream<T>.RemoveToken?
	var outStream: AnyListener<T>?
	let predicate: (T) throws -> Bool
	var dropping = true

	init(predicate: @escaping (T) throws -> Bool, inStream: Stream<T>) {
		self.inStream = inStream
		self.predicate = predicate
	}

	func start<L : Listener>(for listener: L) where ProducerValue == L.ListenerValue {
		outStream = AnyListener(listener)
		removeToken = inStream.add(listener: self)
		dropping = true
	}

	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		outStream = nil
	}

	func next(_ value: ListenerValue) {
		do {
			if try !dropping || predicate(value) == false {
				outStream?.next(value)
				dropping = false
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
