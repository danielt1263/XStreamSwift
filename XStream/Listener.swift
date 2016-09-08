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

	func next(value: ListenerValue)
	func complete()
	func error(err: ErrorType)
}


public
final class AnyListener<T>: Listener
{
	public typealias ListenerValue = T

	init<L: Listener where L.ListenerValue == ListenerValue>(_ l: L) {
		_next = l.next
		_error = l.error
		_complete = l.complete
	}
	
	init(next: (ListenerValue) -> Void, complete: () -> Void, error: (ErrorType) -> Void) {
		_next = next
		_error = error
		_complete = complete
	}
	
	public func next(value: ListenerValue) { _next(value) }
	public func complete() { _complete() }
	public func error(err: ErrorType) { _error(err) }
	
	private let _next: (T) -> Void
	private let _complete: () -> Void
	private let _error: (ErrorType) -> Void
}
