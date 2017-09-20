//
//  Flatten.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/6/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import Foundation


extension StreamConvertable where Value: StreamConvertable
{
	public func flatten() -> Stream<Value.Value> {
		let op = FlattenOperator<Value>(inStream: self.asStream())
		return Stream(producer: op)
	}
}


private
final class FlattenOperator<T: StreamConvertable>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = T.Value

	private let inStream: Stream<T>
	private var removeToken: Stream<T>.RemoveToken?
	private var outStream: AnyListener<T.Value>?
	private var innerStream: Stream<T.Value>?
	private var innerListener: FlattenListener<T.Value>?
	private var innerRemoveToken: Stream<T.Value>.RemoveToken?
	private var open: Bool = true
	
	init(inStream: Stream<T>) {
		self.inStream = inStream
	}
	
	func start<L : Listener>(for listener: L) where ProducerValue == L.ListenerValue {
		outStream = AnyListener(listener)
		removeToken = inStream.add(listener: self)
		open = true
	}
	
	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		outStream = nil
	}
	
	func next(_ value: ListenerValue) {
		let newStream = value.asStream()
		removeInner()
		guard let outStream = outStream else { return }
		innerStream = newStream
		innerListener = FlattenListener<T.Value>(outStream: outStream, finished: self.less)
		innerRemoveToken = newStream.add(listener: AnyListener(innerListener!))
	}
	
	func complete() {
		open = false
		less()
	}
	
	func error(_ error: Error) {
		removeInner()
		outStream?.error(error)
	}
	
	private func removeInner() {
		guard let innerRemoveToken = innerRemoveToken else { return }
		innerStream?.removeListener(innerRemoveToken)
		innerStream = nil
		innerListener = nil
		self.innerRemoveToken = nil
	}
	
	private func less() {
		if open == false && innerStream == nil {
			outStream?.complete()
		}
	}
}


private
final class FlattenListener<T>: Listener
{
	private let outStream: AnyListener<T>
	private let finished: () -> Void
	
	typealias ListenerValue = T

	init(outStream: AnyListener<T>, finished: @escaping () -> Void) {
		self.outStream = outStream
		self.finished = finished
	}
	
	func next(_ value: ListenerValue) {
		outStream.next(value)
	}
	
	func complete() {
		finished()
	}
	
	func error(_ error: Error) {
		outStream.error(error)
	}
}
