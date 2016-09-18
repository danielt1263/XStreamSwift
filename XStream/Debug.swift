//
//  Debug.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/17/16.
//  Copyright © 2016 Daniel Tartaglia. All rights reserved.
//

import Foundation


extension Stream
{
	public func debug(spy: @escaping (Value) throws -> Void) -> Stream {
		let op = DebugOperator(spy: spy, inStream: self)
		return Stream(producer: op)
	}
}


private
final class DebugOperator<T>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = T
	
	let inStream: Stream<T>
	var removeToken: Stream<T>.RemoveToken?
	var outStream: AnyListener<T>?
	let spy: (T) throws -> Void
	
	init(spy: @escaping (T) throws -> Void, inStream: Stream<T>) {
		self.inStream = inStream
		self.spy = spy
	}
	
	func start<L: Listener>(for listener: L) where ProducerValue == L.ListenerValue {
		outStream = AnyListener(listener)
		removeToken = inStream.add(listener: self)
	}
	
	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		outStream = nil
	}

	func next(_ value: ListenerValue) {
		do {
			try spy(value)
			outStream?.next(value)
		}
		catch {
			outStream?.error(error)
		}
	}

	func complete() { outStream?.complete() }
	
	func error(_ error: Error) { outStream?.error(error) }

}
