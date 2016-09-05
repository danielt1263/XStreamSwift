//
//  Map.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/4/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import Foundation


extension Stream
{
	public func map<U>(project: (Value) throws -> U) -> Stream<U> {
		let op = MapOperator(project: project, inStream: self)
		return Stream<U>(producer: op)
	}
}

class MapOperator<T, U>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = U
	
	let inStream: Stream<T>
	var removeToken: Stream<T>.RemoveToken?
	var outStream: AnyListener<U>?
	let project: (T) throws -> U
	
	init(project: (T) throws -> U, inStream: Stream<T>) {
		self.inStream = inStream
		self.project = project
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
			outStream?.next(try project(value))
		}
		catch {
			outStream?.error(error)
		}
	}
	
	func complete() { outStream?.complete() }
	
	func error(err: ErrorType) { outStream?.error(err) }

}
