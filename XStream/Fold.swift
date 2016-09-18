//
//  Fold.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/4/16.
//  Copyright © 2016 Daniel Tartaglia. All rights reserved.
//

import Foundation


extension Stream
{
	/**
	"Folds" the stream onto itself.

	Combines events from the past throughout the entire execution of the input stream, allowing you to accumulate them together. It's essentially like `reduce`. The returned stream is a MemoryStream, which means it is already `remember()`'d.

	The output stream starts by emitting `initial` which you give as argument. Then, when an event happens on the input stream, it is combined with the seed value through the `combine` function, and the output value is emitted on the output stream. `fold` remembers the output value as `accumulator`, and then when a new input event `value` happens, `accumulator` will be combined with that to produce the new `accumulator` and so forth.
	*/
	public func fold<U>(_ initialResult: U, _ nextPartialResult: @escaping (U, Value) throws -> U) -> Stream<U> {
		let op = FoldOperator(initialResult, nextPartialResult, inStream: self)
		return MemoryStream<U>(producer: op)
	}
}

private
final class FoldOperator<T, U>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = U

	let inStream: Stream<ListenerValue>
	var removeToken: Stream<ListenerValue>.RemoveToken?
	var outStream: AnyListener<ProducerValue>?
	let nextPartialResult: (U, T) throws -> U
	let initialResult: U
	var accumulator: U

	init(_ initialResult: U, _ nextPartialResult: @escaping (U, T) throws -> U, inStream: Stream<T>) {
		self.inStream = inStream
		self.nextPartialResult = nextPartialResult
		self.initialResult = initialResult
		self.accumulator = initialResult
	}

	func start<L : Listener>(for listener: L) where ProducerValue == L.ListenerValue {
		outStream = AnyListener(listener)
		accumulator = initialResult
		outStream!.next(accumulator)
		removeToken = inStream.add(listener: self)
	}

	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		outStream = nil
		accumulator = initialResult
	}

	func next(_ value: ListenerValue) {
		do {
			accumulator = try nextPartialResult(accumulator, value)
			outStream?.next(accumulator)
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
