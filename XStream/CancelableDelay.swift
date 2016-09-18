//
//  CancelableDelay.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/4/16.
//  Copyright © 2016 Daniel Tartaglia. MIT License.
//

import Foundation


typealias dispatch_cancelable_closure = (_ cancel : Bool) -> ()

func delay(_ time:TimeInterval, closure:@escaping () -> Void) ->  dispatch_cancelable_closure? {
	
	func dispatch_later(_ clsr:@escaping () -> Void) {
		DispatchQueue.main.asyncAfter(
			deadline: DispatchTime.now() + Double(Int64(time * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: clsr)
	}
	
	var closure: (() -> Void)? = closure
	var cancelableClosure:dispatch_cancelable_closure?
	
	let delayedClosure:dispatch_cancelable_closure = { cancel in
		if let clsr = closure {
			if (cancel == false) {
				DispatchQueue.main.async(execute: clsr);
			}
		}
		closure = nil
		cancelableClosure = nil
	}
	
	cancelableClosure = delayedClosure
	
	dispatch_later {
		if let delayedClosure = cancelableClosure {
			delayedClosure(false)
		}
	}
	
	return cancelableClosure;
}

func cancel_delay(_ closure:dispatch_cancelable_closure?) {
	if closure != nil {
		closure!(true)
	}
}
