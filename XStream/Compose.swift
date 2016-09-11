//
//  Compose.swift
//  XStream
//
//  Created by Daniel Tartaglia on 9/11/16.
//  Copyright © 2016 Daniel Tartaglia. All rights reserved.
//

import Foundation


extension Stream
{
	/** Passes the input stream to a custom operator, to produce an output stream.
	
	*compose* is a handy way of using an existing function in a chained style. Instead of writing `outStream = f(inStream)` you can write `outStream = inStream.compose(f)`.
	*/
	public
	func compose<U>(fn: (Stream) -> Stream<U>) -> Stream<U> {
		return fn(self)
	}
}
