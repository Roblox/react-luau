--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/96ac799eace5d989de3b4f80e6414e94a08ff77a/packages/react-reconciler/src/ReactFiberRoot.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Set = LuauPolyfill.Set
local Map = LuauPolyfill.Map

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
type FiberRoot = ReactInternalTypes.FiberRoot
type SuspenseHydrationCallbacks = ReactInternalTypes.SuspenseHydrationCallbacks
local ReactRootTags = require(script.Parent.ReactRootTags)
type RootTag = ReactRootTags.RootTag

local ReactFiberHostConfig = require(script.Parent.ReactFiberHostConfig)
local noTimeout = ReactFiberHostConfig.noTimeout
local supportsHydration = ReactFiberHostConfig.supportsHydration
local ReactFiber = require(script.Parent["ReactFiber.new"])
local createHostRootFiber = ReactFiber.createHostRootFiber
local ReactFiberLane = require(script.Parent.ReactFiberLane)
local NoLanes = ReactFiberLane.NoLanes
local NoLanePriority = ReactFiberLane.NoLanePriority
local NoTimestamp = ReactFiberLane.NoTimestamp
local createLaneMap = ReactFiberLane.createLaneMap
local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
local enableSchedulerTracing = ReactFeatureFlags.enableSchedulerTracing
local enableSuspenseCallback = ReactFeatureFlags.enableSuspenseCallback
-- ROBLOX deviation: import from tracing from Scheduler export to avoid direct file access
local Scheduler = require(Packages.Scheduler).tracing
local unstable_getThreadID = Scheduler.unstable_getThreadID
local ReactUpdateQueue = require(script.Parent["ReactUpdateQueue.new"])
local initializeUpdateQueue = ReactUpdateQueue.initializeUpdateQueue
local LegacyRoot = ReactRootTags.LegacyRoot
local BlockingRoot = ReactRootTags.BlockingRoot
local ConcurrentRoot = ReactRootTags.ConcurrentRoot

local exports = {}

local function FiberRootNode(containerInfo, tag, hydrate)
	-- ROBLOX performance: See if this kind of object init is faster in Luau
	local rootNode = {
		tag = tag,
		containerInfo = containerInfo,
		pendingChildren = nil,
		-- ROBLOX TODO: this isn't typesafe upstream
		current = (nil :: any) :: Fiber,
		pingCache = nil,
		finishedWork = nil,
		timeoutHandle = noTimeout,
		context = nil,
		pendingContext = nil,
		hydrate = hydrate,
		callbackNode = nil,
		callbackPriority = NoLanePriority,
		eventTimes = createLaneMap(NoLanes),
		expirationTimes = createLaneMap(NoTimestamp),

		pendingLanes = NoLanes,
		suspendedLanes = NoLanes,
		pingedLanes = NoLanes,
		expiredLanes = NoLanes,
		mutableReadLanes = NoLanes,
		finishedLanes = NoLanes,

		entangledLanes = NoLanes,
		entanglements = createLaneMap(NoLanes),
	}

	if supportsHydration then
		rootNode.mutableSourceEagerHydrationData = nil
	end

	if enableSchedulerTracing then
		rootNode.interactionThreadID = unstable_getThreadID()
		rootNode.memoizedInteractions = Set.new()
		rootNode.pendingInteractionMap = Map.new()
	end
	if enableSuspenseCallback then
		rootNode.hydrationCallbacks = nil
	end

	if _G.__DEV__ then
		if tag == BlockingRoot then
			rootNode._debugRootType = "createBlockingRoot()"
		elseif tag == ConcurrentRoot then
			rootNode._debugRootType = "createRoot()"
		elseif tag == LegacyRoot then
			rootNode._debugRootType = "createLegacyRoot()"
		end
	end

	return rootNode
end

exports.createFiberRoot = function(
	containerInfo: any,
	tag: RootTag,
	hydrate: boolean,
	hydrationCallbacks: SuspenseHydrationCallbacks?
): FiberRoot
	local root: FiberRoot = FiberRootNode(containerInfo, tag, hydrate)
	if enableSuspenseCallback then
		root.hydrationCallbacks = hydrationCallbacks
	end

	-- Cyclic construction. This cheats the type system right now because
	-- stateNode is any.
	local uninitializedFiber = createHostRootFiber(tag)
	root.current = uninitializedFiber
	uninitializedFiber.stateNode = root

	initializeUpdateQueue(uninitializedFiber)

	return root
end

return exports
