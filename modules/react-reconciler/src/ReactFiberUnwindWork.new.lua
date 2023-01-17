--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-reconciler/src/ReactFiberUnwindWork.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Packages = script.Parent.Parent

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
local ReactFiberLane = require(script.Parent.ReactFiberLane)
type Lanes = ReactFiberLane.Lanes
local ReactFiberSuspenseComponent =
	require(script.Parent["ReactFiberSuspenseComponent.new"])
type SuspenseState = ReactFiberSuspenseComponent.SuspenseState

local resetMutableSourceWorkInProgressVersions =
	require(script.Parent["ReactMutableSource.new"]).resetWorkInProgressVersions
local ReactWorkTags = require(script.Parent.ReactWorkTags)
-- local {ReactFiberFlags.DidCapture, ReactFiberFlags.NoFlags, ReactFiberFlags.ShouldCapture} = require(script.Parent.ReactFiberFlags)
local ReactFiberFlags = require(script.Parent.ReactFiberFlags)
local ReactTypeOfMode = require(script.Parent.ReactTypeOfMode)

local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
local enableSuspenseServerRenderer = ReactFeatureFlags.enableSuspenseServerRenderer
local enableProfilerTimer = ReactFeatureFlags.enableProfilerTimer

local ReactFiberHostContext = require(script.Parent["ReactFiberHostContext.new"])
local popHostContainer = ReactFiberHostContext.popHostContainer
local popHostContext = ReactFiberHostContext.popHostContext
local popSuspenseContext =
	require(script.Parent["ReactFiberSuspenseContext.new"]).popSuspenseContext
local resetHydrationState =
	require(script.Parent["ReactFiberHydrationContext.new"]).resetHydrationState
local ReactFiberContext = require(script.Parent["ReactFiberContext.new"])
local isLegacyContextProvider = ReactFiberContext.isContextProvider
local popLegacyContext = ReactFiberContext.popContext
local popTopLevelLegacyContextObject = ReactFiberContext.popTopLevelContextObject
local popProvider = require(script.Parent["ReactFiberNewContext.new"]).popProvider
-- ROBLOX FIXME: this causes a circular require
local popRenderLanesRef
local popRenderLanes = function(...)
	if not popRenderLanesRef then
		popRenderLanesRef =
			require(script.Parent["ReactFiberWorkLoop.new"]).popRenderLanes
	end
	return popRenderLanesRef(...)
end
local transferActualDuration =
	require(script.Parent["ReactProfilerTimer.new"]).transferActualDuration

local invariant = require(Packages.Shared).invariant

local function unwindWork(workInProgress: Fiber, renderLanes: Lanes): Fiber?
	if workInProgress.tag == ReactWorkTags.ClassComponent then
		local Component = workInProgress.type
		if isLegacyContextProvider(Component) then
			popLegacyContext(workInProgress)
		end
		local flags = workInProgress.flags
		if bit32.band(flags, ReactFiberFlags.ShouldCapture) ~= 0 then
			workInProgress.flags = bit32.bor(
				bit32.band(flags, bit32.bnot(ReactFiberFlags.ShouldCapture)),
				ReactFiberFlags.DidCapture
			)
			if
				enableProfilerTimer
				and bit32.band(workInProgress.mode, ReactTypeOfMode.ProfileMode)
					~= ReactTypeOfMode.NoMode
			then
				transferActualDuration(workInProgress)
			end
			return workInProgress
		end
		return nil
	elseif workInProgress.tag == ReactWorkTags.HostRoot then
		popHostContainer(workInProgress)
		popTopLevelLegacyContextObject(workInProgress)
		resetMutableSourceWorkInProgressVersions()
		local flags = workInProgress.flags
		invariant(
			bit32.band(flags, ReactFiberFlags.DidCapture) == ReactFiberFlags.NoFlags,
			"The root failed to unmount after an error. This is likely a bug in "
				.. "React. Please file an issue."
		)
		workInProgress.flags = bit32.bor(
			bit32.band(flags, bit32.bnot(ReactFiberFlags.ShouldCapture)),
			ReactFiberFlags.DidCapture
		)
		return workInProgress
	elseif workInProgress.tag == ReactWorkTags.HostComponent then
		-- TODO: popHydrationState
		popHostContext(workInProgress)
		return nil
	elseif workInProgress.tag == ReactWorkTags.SuspenseComponent then
		popSuspenseContext(workInProgress)
		if enableSuspenseServerRenderer then
			local suspenseState = workInProgress.memoizedState
			if suspenseState ~= nil and suspenseState.dehydrated ~= nil then
				invariant(
					workInProgress.alternate ~= nil,
					"Threw in newly mounted dehydrated component. This is likely a bug in "
						.. "React. Please file an issue."
				)
				resetHydrationState()
			end
		end
		local flags = workInProgress.flags
		if bit32.band(flags, ReactFiberFlags.ShouldCapture) ~= 0 then
			workInProgress.flags = bit32.bor(
				bit32.band(flags, bit32.bnot(ReactFiberFlags.ShouldCapture)),
				ReactFiberFlags.DidCapture
			)
			-- Captured a suspense effect. Re-render the boundary.
			if
				enableProfilerTimer
				and (
					bit32.band(workInProgress.mode, ReactTypeOfMode.ProfileMode)
					~= ReactTypeOfMode.NoMode
				)
			then
				transferActualDuration(workInProgress)
			end
			return workInProgress
		end
		return nil
	elseif workInProgress.tag == ReactWorkTags.SuspenseListComponent then
		popSuspenseContext(workInProgress)
		-- SuspenseList doesn't actually catch anything. It should've been
		-- caught by a nested boundary. If not, it should bubble through.
		return nil
	elseif workInProgress.tag == ReactWorkTags.HostPortal then
		popHostContainer(workInProgress)
		return nil
	elseif workInProgress.tag == ReactWorkTags.ContextProvider then
		popProvider(workInProgress)
		return nil
	elseif
		workInProgress.tag == ReactWorkTags.OffscreenComponent
		or workInProgress.tag == ReactWorkTags.LegacyHiddenComponent
	then
		popRenderLanes(workInProgress)
		return nil
	else
		return nil
	end
end

function unwindInterruptedWork(interruptedWork: Fiber)
	if interruptedWork.tag == ReactWorkTags.ClassComponent then
		-- ROBLOX deviation: Lua doesn't support properties on functions
		local childContextTypes
		if typeof(interruptedWork.type) == "table" then
			childContextTypes = interruptedWork.type.childContextTypes
		end
		if childContextTypes ~= nil then
			popLegacyContext(interruptedWork)
		end
	elseif interruptedWork.tag == ReactWorkTags.HostRoot then
		popHostContainer(interruptedWork)
		popTopLevelLegacyContextObject(interruptedWork)
		resetMutableSourceWorkInProgressVersions()
	elseif interruptedWork.tag == ReactWorkTags.HostComponent then
		popHostContext(interruptedWork)
	elseif interruptedWork.tag == ReactWorkTags.HostPortal then
		popHostContainer(interruptedWork)
	elseif interruptedWork.tag == ReactWorkTags.SuspenseComponent then
		popSuspenseContext(interruptedWork)
	elseif interruptedWork.tag == ReactWorkTags.SuspenseListComponent then
		popSuspenseContext(interruptedWork)
	elseif interruptedWork.tag == ReactWorkTags.ContextProvider then
		popProvider(interruptedWork)
	elseif
		interruptedWork.tag == ReactWorkTags.OffscreenComponent
		or interruptedWork.tag == ReactWorkTags.LegacyHiddenComponent
	then
		popRenderLanes(interruptedWork)
		return
	else -- default
		return
	end
end

return {
	unwindWork = unwindWork,
	unwindInterruptedWork = unwindInterruptedWork,
}
