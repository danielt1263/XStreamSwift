//
//  Listener.swift
//  PeopleCRMSwift
//
//  Created by Daniel Tartaglia on 9/3/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import Foundation


public
protocol Listener
{
	associatedtype ListenerValue

	func next(_ value: ListenerValue)
	func complete()
	func error(_ error: Error)
}


public
final class AnyListener<T>: Listener
{
	public typealias ListenerValue = T

	public convenience init<L: Listener>(_ listener: L) where L.ListenerValue == ListenerValue {
		self.init(next: listener.next, complete: listener.complete, error: listener.error)
	}
	
	init(next: @escaping (ListenerValue) -> Void, complete: @escaping () -> Void, error: @escaping (Error) -> Void) {
		_next = next
		_error = error
		_complete = complete
	}
	
	public func next(_ value: ListenerValue) { _next(value) }
	public func complete() { _complete() }
	public func error(_ error: Error) { _error(error) }
	
	private let _next: (T) -> Void
	private let _complete: () -> Void
	private let _error: (Error) -> Void
}
