//
//  Filter.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/5/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import Foundation


extension Stream
{
	public func filter(includeElement: (Value) throws -> Bool) -> Stream {
		let op = FilterOperator(includeElement: includeElement, inStream: self)
		return Stream(producer: op)
	}
}


class FilterOperator<T>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = T
	
	let inStream: Stream<T>
	var removeToken: Stream<T>.RemoveToken?
	var outStream: AnyListener<T>?
	let includeElement: (T) throws -> Bool
	
	init(includeElement: (T) throws -> Bool, inStream: Stream<T>) {
		self.inStream = inStream
		self.includeElement = includeElement
	}
	
	func start<L : Listener where ProducerValue == L.ListenerValue>(listener: L) {
		outStream = AnyListener(listener)
		removeToken = inStream.addListener(self)
	}
	
	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		outStream = nil
	}
	
	func next(value: ListenerValue) {
		do {
			if try includeElement(value) {
				outStream?.next(value)
			}
		}
		catch {
			outStream?.error(error)
		}
	}
	
	func complete() { outStream?.complete() }
	
	func error(err: ErrorType) { outStream?.error(err) }
	
}
