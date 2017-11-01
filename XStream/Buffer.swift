//
//  Buffer.swift
//  XStream
//
//  Created by Daniel Tartaglia on 4/14/17.
//  Copyright © 2017 Daniel Tartaglia. All rights reserved.
//

import Foundation


extension Stream
{
	public func buffer<S: StreamConvertable>(boundary: S) -> Stream<[Value]> {
		let op = BufferOperator<Value, S.Value>(inStream: self, boundary: boundary.asStream())
		return Stream<[Value]>(producer: op)
	}
}


private
final class BufferOperator<T, U>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = [T]

	private let inStream: Stream<T>
	private var removeToken: Stream<T>.RemoveToken?
	private var outStream: AnyListener<ProducerValue>?
	private let boundary: Stream<U>
	private var boundaryToken: Stream<U>.RemoveToken?
	private var boundaryListener: AnyListener<U>?
	private var buffer: [T] = []

	init(inStream: Stream<T>, boundary: Stream<U>) {
		self.inStream = inStream
		self.boundary = boundary
	}

	func start<L: Listener>(for listener: L) where ProducerValue == L.ListenerValue {
		outStream = AnyListener(listener)
		removeToken = inStream.add(listener: self)
		boundaryListener = AnyListener<U>(next: { _ in
			self.outStream?.next(self.buffer)
			self.buffer = []
		})
		boundaryToken = boundary.add(listener: boundaryListener!)
	}

	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		if let boundaryToken = boundaryToken {
			boundary.removeListener(boundaryToken)
			self.boundaryToken = nil
		}
		outStream = nil
	}

	func next(_ value: ListenerValue) {
		buffer.append(value)
	}

	func complete() {
		outStream?.next(buffer)
		outStream?.complete()
	}

	func error(_ error: Error) {
		buffer = []
		outStream?.error(error)
	}
}
