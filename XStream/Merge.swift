//
//  Merge.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/7/16.
//  Copyright © 2016 Daniel Tartaglia. All rights reserved.
//

import Foundation


extension Stream
{
	public convenience init(streams: [Stream<T>]) {
		let producer = MergeProducer<T>(inStreams: streams)
		self.init(producer: producer)
	}
}


extension SequenceType where Generator.Element: StreamConvertable
{
	public func merge() -> Stream<Generator.Element.Value> {
		let producer = MergeProducer(inStreams: self.map { $0.asStream() })
		return Stream<Generator.Element.Value>(producer: producer)
	}
}


private
final class MergeProducer<T>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = T
	
	let inStreams: [Stream<T>]
	var outStream: AnyListener<T>?
	var removeTokens: [Stream<T>.RemoveToken] = []
	var activeCount: Int = 0
	
	init(inStreams: [Stream<T>]) {
		self.inStreams = inStreams
	}
	
	func start<L: Listener where ProducerValue == L.ListenerValue>(listener: L) {
		outStream = AnyListener(listener)
		activeCount = inStreams.count
		for stream in inStreams {
			removeTokens.append(stream.add(AnyListener(self)))
		}
	}
	
	func stop() {
		for (stream, token) in zip(inStreams, removeTokens) {
			stream.removeListener(token)
		}
		outStream = nil
	}

	func next(value: ListenerValue) {
		outStream?.next(value)
	}
	
	func complete() {
		activeCount -= 1
		if activeCount == 0 {
			outStream?.complete()
		}
	}
	
	func error(err: ErrorType) {
		outStream?.error(err)
	}

}
