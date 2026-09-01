--!strict
--[[*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Packages = script.Parent.Parent
local ReactGlobals = require(Packages.ReactGlobals)
local Error = require(Packages.LuauPolyfill).Error
local console = require(Packages.Shared).console
local ReactTypes = require(Packages.Shared)
type Thenable<T> = ReactTypes.Thenable<T>

local __DEV__ = ReactGlobals.__DEV__

-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/ReactFiberThenable.js#L31-L49
-- ROBLOX DEVIATION: This client-only port always uses the development object
-- shape. The production array shape is an allocation optimization rather than
-- a behavior difference.
export type ThenableState = {
	didWarnAboutUncachedPromise: boolean,
	thenables: { Thenable<any> },
}

-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/ReactFiberThenable.js#L51-L61
local SuspenseException = Error.new(
	"Suspense Exception: This is not a real error! It's an implementation "
		.. "detail of `use` to interrupt the current render. You must either "
		.. "rethrow it immediately, or move the `use` call outside of the "
		.. "`try/catch` block. Capturing without rethrowing will lead to "
		.. "unexpected behavior.\n\n"
		.. "To handle async errors, wrap your component in an error boundary, or "
		.. "call the promise's `.catch` method and pass the result to `use`."
)

local function noop() end

local function createThenableState(): ThenableState
	return {
		didWarnAboutUncachedPromise = false,
		thenables = {},
	}
end

local suspendedThenable: Thenable<any>? = nil
local needsToResetSuspendedThenableDEV = false
local thenableIndexCounter = 1
local thenableState: ThenableState? = nil

-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/ReactFiberThenable.js#L107-L289
-- ROBLOX DEVIATION: Roblox Promise-compatible thenables expose `andThen`.
-- Async debug information, act microtask accounting, async Client Component
-- loop detection, Actions, and commit-suspension resources are separate
-- features and are not part of this cached client Promise backport.
-- Roblox Promise cancellation does not notify ordinary `andThen` listeners,
-- so a Promise passed to use must settle normally and must not be canceled.
-- `status ~= nil` is broader than upstream's string-only custom status check;
-- the Luau Thenable type only admits string states. Async Client Components
-- are excluded, so rejected reasons omit `checkIfUseWrappedInAsyncCatch`.
-- Without Fiber-retained replay state, the uncached-Promise warning cannot see
-- replacements between attempts. React 17 also has no shell suspend counter,
-- so an uncached self-resolving Promise silently retries instead of reaching
-- React 19's infinite-ping error.
local function trackUsedThenable<T>(
	thenableState: ThenableState,
	thenable: Thenable<T>,
	index: number
): T
	local previous = thenableState.thenables[index]
	if previous == nil then
		thenableState.thenables[index] = thenable
	elseif previous ~= thenable then
		if __DEV__ and not thenableState.didWarnAboutUncachedPromise then
			thenableState.didWarnAboutUncachedPromise = true
			console.error(
				"A component was suspended by an uncached promise. Creating "
					.. "promises inside a Client Component or hook is not yet "
					.. "supported, except via a Suspense-compatible library or framework."
			)
		end

		thenable:andThen(noop, noop)
		thenable = previous :: Thenable<T>
	end

	if thenable.status == "fulfilled" then
		return thenable.value :: T
	elseif thenable.status == "rejected" then
		error(thenable.reason)
	elseif thenable.status ~= nil then
		thenable:andThen(noop, noop)
	else
		thenable.status = "pending"
		thenable:andThen(function(value: T)
			if thenable.status == "pending" then
				thenable.status = "fulfilled"
				thenable.value = value
			end
		end, function(reason: any)
			if thenable.status == "pending" then
				thenable.status = "rejected"
				thenable.reason = reason
			end
		end)
	end

	if thenable.status == "fulfilled" then
		return thenable.value :: T
	elseif thenable.status == "rejected" then
		error(thenable.reason)
	end

	suspendedThenable = thenable
	if __DEV__ then
		needsToResetSuspendedThenableDEV = true
	end
	error(SuspenseException)
end

-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/ReactFiberHooks.js#L1095-L1149
-- ROBLOX DEVIATION: Keep the per-component counters in this module because
-- ReactFiberHooks.new.lua is at Luau's local-register limit. Luau arrays are
-- one-indexed, so the first thenable occupies slot 1 instead of slot 0. React
-- 17 has no suspended-component replay dispatcher, so the post-use switch back
-- to a mount or update dispatcher is omitted.
local function useThenable<T>(thenable: Thenable<T>): T
	local index = thenableIndexCounter
	thenableIndexCounter += 1
	if thenableState == nil then
		thenableState = createThenableState()
	end
	return trackUsedThenable(thenableState :: ThenableState, thenable, index)
end

local function resetThenableState(): ()
	thenableIndexCounter = 1
	thenableState = nil
end

-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/ReactFiberThenable.js#L319-L350
local function getSuspendedThenable(): Thenable<any>
	if suspendedThenable == nil then
		error(
			Error.new(
				"Expected a suspended thenable. This is a bug in React. Please file an issue."
			)
		)
	end

	local thenable = suspendedThenable
	suspendedThenable = nil
	if __DEV__ then
		needsToResetSuspendedThenableDEV = false
	end
	return thenable :: Thenable<any>
end

local function checkIfUseWrappedInTryCatch(): boolean
	if __DEV__ and needsToResetSuspendedThenableDEV then
		needsToResetSuspendedThenableDEV = false
		return true
	end
	return false
end

return {
	SuspenseException = SuspenseException,
	checkIfUseWrappedInTryCatch = checkIfUseWrappedInTryCatch,
	createThenableState = createThenableState,
	getSuspendedThenable = getSuspendedThenable,
	resetThenableState = resetThenableState,
	trackUsedThenable = trackUsedThenable,
	useThenable = useThenable,
}
