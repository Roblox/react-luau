--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/b87aabdfe1b7461e7331abb3601d9e6bb27544bc/packages/shared/ReactErrorUtils.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local invariant = require(script.Parent.invariant)
local invokeGuardedCallbackImpl = require(script.Parent.invokeGuardedCallbackImpl)

-- deviation: preemptively declare function
local clearCaughtError

-- Used by Fiber to simulate a try-catch.
local hasError = false
local caughtError = nil

-- Used by event system to capture/rethrow the first error.
local hasRethrowError = false
local rethrowError = nil
local reporter = {
	onError = function(err)
		hasError = true
		caughtError = err
	end,
}
local exports = {}

--[[*
* Call a function while guarding against errors that happens within it.
* Returns an error if it throws, otherwise nil.
*
* In production, this is implemented using a try-catch. The reason we don't
* use a try-catch directly is so that we can swap out a different
* implementation in DEV mode.
*
* @param {String} name of the guard to use for logging or debugging
* @param {Function} func The function to invoke
* @param {*} context The context to use when calling the function
* @param {...*} args Arguments for function
]]
exports.invokeGuardedCallback = function(...)
	hasError = false
	caughtError = nil
	-- deviation: passing in reporter directly
	invokeGuardedCallbackImpl(reporter, ...)
end

--[[*
* Same as invokeGuardedCallback, but instead of returning an error, it stores
* it in a global so it can be rethrown by `rethrowCaughtError` later.
* TODO: See if caughtError and rethrowError can be unified.
*
* @param {String} name of the guard to use for logging or debugging
* @param {Function} func The function to invoke
* @param {*} context The context to use when calling the function
* @param {...*} args Arguments for function
]]
exports.invokeGuardedCallbackAndCatchFirstError = function(...)
	-- deviation: instead of the weird `this` indirection, pass varargs through
	exports.invokeGuardedCallback(...)

	if hasError then
		local err = clearCaughtError()

		if not hasRethrowError then
			hasRethrowError = true
			rethrowError = err
		end
	end
end

--[[*
* During execution of guarded functions we will capture the first error which
* we will rethrow to be handled by the top level error handler.
]]
exports.rethrowCaughtError = function()
	if hasRethrowError then
		local err = rethrowError
		hasRethrowError = false
		rethrowError = nil
		error(err)
	end
end

exports.hasCaughtError = function()
	return hasError
end

clearCaughtError = function()
	if hasError then
		local err = caughtError
		hasError = false
		caughtError = nil
		return err
	else
		invariant(
			false,
			"clearCaughtError was called but no error was captured. This error "
				.. "is likely caused by a bug in React. Please file an issue."
		)
		-- deviation: luau doesn't know that invariant throws, so we return nil
		return nil
	end
end
exports.clearCaughtError = clearCaughtError

return exports
