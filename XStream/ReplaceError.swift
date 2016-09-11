//
//  ReplaceError.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/11/16.
//  Copyright © 2016 Daniel Tartaglia. All rights reserved.
//

import Foundation


extension Stream
{
	/** Replaces an error with another stream.
	
	When (and if) an error happens on the input stream, instead of forwarding that error to the output stream, *replaceError* will call the `replace` function which returns the stream that the output stream will replicate. And, in case that new stream also emits an error, `replace` will be called again to get another stream to start replicating.
	*/
	public func replaceError(replace: (err: ErrorType) throws -> Stream) -> Stream {
		let op = ReplaceErrorOperator(replace: replace, inStream: self)
		return Stream(producer: op)
	}
}

private
class ReplaceErrorOperator<T>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = T
	
	var inStream: Stream<ListenerValue>
	var removeToken: Stream<ListenerValue>.RemoveToken?
	var outStream: AnyListener<ProducerValue>?
	let replace: (error: ErrorType) throws -> Stream<ProducerValue>
	
	init(replace: (error: ErrorType) throws -> Stream<ProducerValue>, inStream: Stream<ListenerValue>) {
		self.inStream = inStream
		self.replace = replace
	}
	
	func start<L: Listener where ProducerValue == L.ListenerValue>(listener: L) {
		outStream = AnyListener(listener)
		removeToken = inStream.addListener(self)
	}
	
	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		outStream = nil
	}

	func next(value: ListenerValue) {
		outStream?.next(value)
	}
	
	func complete() {
		outStream?.complete()
	}

	func error(err: ErrorType) {
		guard let removeToken = removeToken else { return }
		do {
			inStream.removeListener(removeToken)
			inStream = try replace(error: err)
			self.removeToken = inStream.addListener(self)
		}
		catch {
			outStream?.error(err)
		}
	}

}
