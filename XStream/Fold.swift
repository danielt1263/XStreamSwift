//
//  Fold.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/4/16.
//  Copyright © 2016 Daniel Tartaglia. All rights reserved.
//

import Foundation
import Swift

extension Stream
{
	/**
	"Folds" the stream onto itself.

	Combines events from the past throughout the entire execution of the input stream, allowing you to accumulate them together. It's essentially like `reduce`. The returned stream is a MemoryStream, which means it is already `remember()`'d.

	The output stream starts by emitting `initial` which you give as argument. Then, when an event happens on the input stream, it is combined with the seed value through the `combine` function, and the output value is emitted on the output stream. `fold` remembers the output value as `accumulator`, and then when a new input event `value` happens, `accumulator` will be combined with that to produce the new `accumulator` and so forth.
	*/
	public func fold<U>(initial: U, combine: (U, Value) throws -> U) -> MemoryStream<U> {
		let op = FoldOperator(initial: initial, combine: combine, inStream: self)
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
	let combine: (U, T) throws -> U
	let initial: U
	var accumulator: U

	init(initial: U, combine: (U, T) throws -> U, inStream: Stream<T>) {
		self.inStream = inStream
		self.combine = combine
		self.initial = initial
		self.accumulator = initial
	}

	func start<L : Listener where ProducerValue == L.ListenerValue>(listener: L) {
		outStream = AnyListener(listener)
		accumulator = initial
		outStream!.next(accumulator)
		removeToken = inStream.addListener(self)
	}

	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		outStream = nil
		accumulator = initial
	}

	func next(value: ListenerValue) {
		do {
			accumulator = try combine(accumulator, value)
			outStream?.next(accumulator)
		}
		catch {
			outStream?.error(error)
		}
	}

	func complete() {
		outStream?.complete()
	}

	func error(err: ErrorType) {
		outStream?.error(err)
	}
}
