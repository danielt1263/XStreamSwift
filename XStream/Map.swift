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
	/// Transforms each event from the input Stream through a `transform` function, to get a Stream that emits those transformed events.
	public func map<U>(_ transform: @escaping (Value) throws -> U) -> Stream<U> {
		let op = MapOperator(transform: transform, inStream: self)
		return Stream<U>(producer: op)
	}
}

private
final class MapOperator<T, U>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = U
	
	let inStream: Stream<T>
	var removeToken: Stream<T>.RemoveToken?
	var outStream: AnyListener<U>?
	let transform: (T) throws -> U
	
	init(transform: @escaping (T) throws -> U, inStream: Stream<T>) {
		self.inStream = inStream
		self.transform = transform
	}
	
	func start<L : Listener>(for listener: L) where ProducerValue == L.ListenerValue {
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
			outStream?.next(try transform(value))
		}
		catch {
			outStream?.error(error)
		}
	}
	
	func complete() { outStream?.complete() }
	
	func error(_ error: Error) { outStream?.error(error) }

}
