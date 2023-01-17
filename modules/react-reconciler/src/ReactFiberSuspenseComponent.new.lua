--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/1faf9e3dd5d6492f3607d5c721055819e4106bc6/packages/react-reconciler/src/ReactFiberSuspenseComponent.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Packages = script.Parent.Parent

local ReactTypes = require(Packages.Shared)
type ReactNodeList = ReactTypes.ReactNodeList
type Wakeable = ReactTypes.Wakeable

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
local ReactFiberHostConfig = require(script.Parent.ReactFiberHostConfig)
type SuspenseInstance = ReactFiberHostConfig.SuspenseInstance
local ReactFiberLane = require(script.Parent.ReactFiberLane)
type Lane = ReactFiberLane.Lane
local ReactWorkTags = require(script.Parent.ReactWorkTags)
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local SuspenseListComponent = ReactWorkTags.SuspenseListComponent
local ReactFiberFlags = require(script.Parent.ReactFiberFlags)
local NoFlags = ReactFiberFlags.NoFlags
local DidCapture = ReactFiberFlags.DidCapture
local isSuspenseInstancePending = ReactFiberHostConfig.isSuspenseInstancePending
local isSuspenseInstanceFallback = ReactFiberHostConfig.isSuspenseInstanceFallback

-- deviation: Common types
type Set<T> = { [T]: boolean }

export type SuspenseProps = {
	children: ReactNodeList?,
	fallback: ReactNodeList?,

	-- TODO: Add "unstable_" prefix?
	suspenseCallback: (Set<Wakeable>?) -> any,

	unstable_expectedLoadTime: number?,
}

-- A nil SuspenseState represents an unsuspended normal Suspense boundary.
-- A non-null SuspenseState means that it is blocked for one reason or another.
-- - A non-null dehydrated field means it's blocked pending hydration.
--   - A non-null dehydrated field can use isSuspenseInstancePending or
--     isSuspenseInstanceFallback to query the reason for being dehydrated.
-- - A nil dehydrated field means it's blocked by something suspending and
--   we're currently showing a fallback instead.
export type SuspenseState = {
	-- If this boundary is still dehydrated, we store the SuspenseInstance
	-- here to indicate that it is dehydrated (flag) and for quick access
	-- to check things like isSuspenseInstancePending.
	dehydrated: SuspenseInstance?,
	-- Represents the lane we should attempt to hydrate a dehydrated boundary at.
	-- OffscreenLane is the default for dehydrated boundaries.
	-- NoLane is the default for normal boundaries, which turns into "normal" pri.
	retryLane: Lane,
}

-- deviation: Can't use literals for types
-- export type SuspenseListTailMode = 'collapsed' | 'hidden' | void
export type SuspenseListTailMode = string?

export type SuspenseListRenderState = {
	isBackwards: boolean,
	-- The currently rendering tail row.
	rendering: Fiber?,
	-- The absolute time when we started rendering the most recent tail row.
	renderingStartTime: number,
	-- The last of the already rendered children.
	last: Fiber?,
	-- Remaining rows on the tail of the list.
	tail: Fiber?,
	-- Tail insertions setting.
	tailMode: SuspenseListTailMode,
}

local exports = {}

exports.shouldCaptureSuspense =
	function(workInProgress: Fiber, hasInvisibleParent: boolean): boolean
		-- If it was the primary children that just suspended, capture and render the
		-- fallback. Otherwise, don't capture and bubble to the next boundary.
		local nextState: SuspenseState? = workInProgress.memoizedState
		if nextState then
			if nextState.dehydrated ~= nil then
				-- A dehydrated boundary always captures.
				return true
			end
			return false
		end
		local props = workInProgress.memoizedProps
		-- In order to capture, the Suspense component must have a fallback prop.
		if props.fallback == nil then
			return false
		end
		-- Regular boundaries always capture.
		if props.unstable_avoidThisFallback ~= true then
			return true
		end
		-- If it's a boundary we should avoid, then we prefer to bubble up to the
		-- parent boundary if it is currently invisible.
		if hasInvisibleParent then
			return false
		end
		-- If the parent is not able to handle it, we must handle it.
		return true
	end

exports.findFirstSuspended = function(row: Fiber): Fiber?
	local node = row
	while node ~= nil do
		if node.tag == SuspenseComponent then
			local state: SuspenseState? = node.memoizedState
			if state then
				local dehydrated: SuspenseInstance? = state.dehydrated
				if
					dehydrated == nil
					or isSuspenseInstancePending(dehydrated)
					or isSuspenseInstanceFallback(dehydrated)
				then
					return node
				end
			end
		elseif
			node.tag == SuspenseListComponent
			-- revealOrder undefined can't be trusted because it don't
			-- keep track of whether it suspended or not.
			and node.memoizedProps.revealOrder ~= nil
		then
			local didSuspend = bit32.band(node.flags, DidCapture) ~= NoFlags
			if didSuspend then
				return node
			end
		elseif node.child ~= nil then
			node.child.return_ = node
			node = node.child
			continue
		end
		if node == row then
			return nil
		end
		while node.sibling == nil do
			if node.return_ == nil or node.return_ == row then
				return nil
			end
			-- ROBLOX FIXME Luau: Luau narrowing doesn't understand this loop until nil pattern
			node = node.return_ :: Fiber
		end
		-- ROBLOX FIXME Luau: Luau narrowing doesn't understand this loop until nil pattern
		(node.sibling :: Fiber).return_ = node.return_
		node = node.sibling :: Fiber
	end
	return nil
end

return exports
