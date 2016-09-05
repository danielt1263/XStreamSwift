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
	public func fold<U>(initial: U, combine: (U, Value) throws -> U) -> MemoryStream<U> {
		let op = FoldOperator(initial: initial, combine: combine, inStream: self)
		return MemoryStream<U>(producer: op)
	}
}

class FoldOperator<T, U>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = U

	let inStream: Stream<ListenerValue>
	var removeToken: Stream<ListenerValue>.RemoveToken?
	var outStream: AnyListener<ProducerValue>?
	let combine: (U, T) throws -> U
	let initial: U
	var acc: U
	
	init(initial: U, combine: (U, T) throws -> U, inStream: Stream<T>) {
		self.inStream = inStream
		self.combine = combine
		self.initial = initial
		self.acc = initial
	}
	
	func start<L : Listener where ProducerValue == L.ListenerValue>(listener: L) {
		outStream = AnyListener(listener)
		acc = initial
		outStream!.next(acc)
		removeToken = inStream.addListener(self)
	}
	
	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		outStream = nil
		acc = initial
	}
	
	func next(value: ListenerValue) {
		do {
			acc = try combine(acc, value)
			outStream?.next(acc)
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
