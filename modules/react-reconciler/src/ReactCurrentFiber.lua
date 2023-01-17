--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/b0cb137bcbd3a11d8eff3c2229cd6b8379d29785/packages/react-reconciler/src/ReactCurrentFiber.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local __DEV__ = _G.__DEV__ :: boolean
local Packages = script.Parent.Parent

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber

local ReactSharedInternals = require(Packages.Shared).ReactSharedInternals
local ReactFiberComponentStack = require(script.Parent.ReactFiberComponentStack)
local getStackByFiberInDevAndProd = ReactFiberComponentStack.getStackByFiberInDevAndProd
local getComponentName = require(Packages.Shared).getComponentName

local ReactDebugCurrentFrame = ReactSharedInternals.ReactDebugCurrentFrame

-- deviation: Pre-declare type of exports, including values we'll initialize
type Exports = {
	current: Fiber | nil,
	isRendering: boolean,
	-- remaining functions declare their own types
	[string]: any,
}

local exports: Exports = {
	current = nil,
	isRendering = false,
}

exports.getCurrentFiberOwnerNameInDevOrNull = function(): string?
	if __DEV__ then
		if exports.current == nil then
			return nil
		end
		-- ROBLOX FIXME Luau: Luau doesn't understand guard above
		local owner = (exports.current :: Fiber)._debugOwner
		if owner then
			return getComponentName(owner.type)
		end
	end
	return nil
end

local function getCurrentFiberStackInDev(): string
	if __DEV__ then
		if exports.current == nil then
			return ""
		end
		-- Safe because if current fiber exists, we are reconciling,
		-- and it is guaranteed to be the work-in-progress version.
		-- ROBLOX FIXME Luau: Luau doesn't understand guard above
		return getStackByFiberInDevAndProd(exports.current :: Fiber)
	end
	return ""
end

exports.resetCurrentFiber = function(): ()
	if __DEV__ then
		-- ROBLOX FIXME Luau: Expected type table, got 'ReactDebugCurrentFrame | { setExtraStackFrame: () -> () }' instead
		(ReactDebugCurrentFrame :: any).getCurrentStack = nil
		exports.current = nil
		exports.isRendering = false
	end
end

exports.setCurrentFiber = function(fiber: Fiber): ()
	if __DEV__ then
		-- ROBLOX FIXME Luau: Expected type table, got 'ReactDebugCurrentFrame | { setExtraStackFrame: () -> () }' instead
		(ReactDebugCurrentFrame :: any).getCurrentStack = getCurrentFiberStackInDev
		exports.current = fiber
		exports.isRendering = false
	end
end

exports.setIsRendering = function(rendering: boolean): ()
	if __DEV__ then
		exports.isRendering = rendering
	end
end

exports.getIsRendering = function(): boolean
	if __DEV__ then
		return exports.isRendering
	end
	return false
end

return exports
