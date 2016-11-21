//
//  Debuonce.swift
//  XStream
//
//  Created by Daniel Tartaglia on 11/21/16.
//  Copyright © 2016 Daniel Tartaglia. All rights reserved.
//

import Foundation


extension Stream
{
	/// Delays events until a certain amount of silence has passed. If that timespan of silence is not met the event is dropped.
	public func debounce(interval: TimeInterval) -> Stream {
		let op = DebounceOperator(interval: interval, inStream: self)
		return Stream(producer: op)
	}
}


private
final class DebounceOperator<T>: Listener, Producer
{
	typealias ListenerValue = T
	typealias ProducerValue = T

	init(interval: TimeInterval, inStream: Stream<T>) {
		self.inStream = inStream
		self.interval = interval
	}

	func start<L : Listener>(for listener: L) where ProducerValue == L.ListenerValue {
		outStream = AnyListener(listener)
		removeToken = inStream.add(listener: self)
	}

	func stop() {
		guard let removeToken = removeToken else { return }
		inStream.removeListener(removeToken)
		outStream = nil
		timer?.invalidate()
	}

	func next(_ value: ListenerValue) {
		timer?.invalidate()
		if #available(iOS 10.0, *) {
			timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
				self?.outStream?.next(value)
			}
		} else {
			nextValue = value
			timer = Timer(timeInterval: interval, target: self, selector: #selector(DebounceOperator<T>.timerFired), userInfo: nil, repeats: false)
		}
	}

	func complete() { }

	func error(_ error: Error) {
		timer?.invalidate()
		outStream?.error(error)
	}

	private let inStream: Stream<T>
	private var removeToken: Stream<T>.RemoveToken?
	private var outStream: AnyListener<T>?
	private let interval: TimeInterval
	private weak var timer: Timer?
	private var nextValue: T?

	@objc
	private func timerFired(timer: Timer) {
		guard let nextValue = nextValue else { return }
		outStream?.next(nextValue)
	}

}
