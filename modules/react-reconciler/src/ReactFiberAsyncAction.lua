--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/ReactFiberAsyncAction.js
--[[*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]

local ReactFiberLane = require(script.Parent.ReactFiberLane)
type Lane = ReactFiberLane.Lane

local NoLane = ReactFiberLane.NoLane
local claimNextTransitionLane = ReactFiberLane.claimNextTransitionLane

local currentEntangledListeners: { () -> ...any }? = nil
local currentEntangledPendingCount = 0
local currentEntangledLane: Lane = NoLane
local currentEntangledActionThenable: any = nil
local currentEventTransitionLane: Lane = NoLane

-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/ReactFiberRootScheduler.js#L697-L723
-- ROBLOX DEVIATION: React 17 has no FiberRootScheduler. This action-local
-- module owns the shared event cache until the modern scheduler is ported.
local function requestTransitionLane(_transition: any): Lane
	if currentEventTransitionLane == NoLane then
		currentEventTransitionLane = if currentEntangledLane ~= NoLane
			then currentEntangledLane
			else claimNextTransitionLane()
	end
	return currentEventTransitionLane
end

local function pingEntangledActionScope()
	currentEntangledPendingCount -= 1
	if currentEntangledPendingCount ~= 0 then
		return
	end

	local entangledThenable = currentEntangledActionThenable
	if entangledThenable ~= nil then
		entangledThenable.status = "fulfilled"
	end

	local listeners = currentEntangledListeners
	currentEntangledListeners = nil
	currentEntangledLane = NoLane
	currentEntangledActionThenable = nil

	if listeners ~= nil then
		for _, listener in listeners do
			listener()
		end
	end
end

local function entangleAsyncAction(transition: any, thenable: any): any
	if currentEntangledListeners == nil then
		local entangledListeners = {}
		currentEntangledListeners = entangledListeners
		currentEntangledPendingCount = 0
		currentEntangledLane = requestTransitionLane(transition)
		currentEntangledActionThenable = {
			status = "pending",
			value = nil,
			andThen = function(_self, resolve)
				table.insert(entangledListeners, resolve)
			end,
		}
	end

	currentEntangledPendingCount += 1
	thenable:andThen(pingEntangledActionScope, pingEntangledActionScope)
	return thenable
end

local function chainThenableValue<T>(thenable: any, result: T): any
	local listeners = {}
	local thenableWithOverride = {
		status = "pending",
		value = nil,
		reason = nil,
		andThen = function(_self, resolve)
			table.insert(listeners, resolve)
		end,
	}

	thenable:andThen(function()
		thenableWithOverride.status = "fulfilled"
		thenableWithOverride.value = result
		for _, listener in listeners do
			listener(result)
		end
	end, function(error_)
		thenableWithOverride.status = "rejected"
		thenableWithOverride.reason = error_
		for _, listener in listeners do
			listener()
		end
	end)

	return thenableWithOverride
end

return {
	chainThenableValue = chainThenableValue,
	entangleAsyncAction = entangleAsyncAction,
	peekEntangledActionLane = function(): Lane
		return currentEntangledLane
	end,
	peekEntangledActionThenable = function(): any
		return currentEntangledActionThenable
	end,
	requestTransitionLane = requestTransitionLane,
	resetCurrentEventTransitionLane = function()
		currentEventTransitionLane = NoLane
	end,
}
