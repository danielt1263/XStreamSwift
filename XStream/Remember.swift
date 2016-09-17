//
//  Remember.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/13/16.
//  Copyright © 2016 Daniel Tartaglia. All rights reserved.
//

import Foundation


extension Stream
{
	/// Returns an output stream that behaves like the input stream, but also remembers the most recent event that happens on the input stream, so that a newly added listener will immediately receive that memorised event.
	public func remember() -> Stream<Value> {
		let op = RememberOperator(inStream: self)
		return MemoryStream(producer: op)
	}
}


private
final class RememberOperator<T>: Producer
{
	typealias ProducerValue = T

	let inStream: Stream<T>
	var removeToken: Stream<T>.RemoveToken?
	var outStream: AnyListener<T>?

	init(inStream: Stream<T>) {
		self.inStream = inStream
	}
	
	func start<L : Listener>(for listener: L) where T == L.ListenerValue {
		outStream = AnyListener(listener)
		removeToken = inStream.add(listener: listener)
	}
	
	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		outStream = nil
	}
}
