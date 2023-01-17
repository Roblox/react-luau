--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/d17086c7c813402a550d15a2f56dc43f1dbd1735/packages/react-reconciler/src/SchedulerWithReactIntegration.new.js
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
local Array = LuauPolyfill.Array

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
export type ReactPriorityLevel = ReactInternalTypes.ReactPriorityLevel

-- Intentionally not named imports because Rollup would use dynamic dispatch for
-- CommonJS interop named imports.
local Scheduler = require(Packages.Scheduler)
-- local __interactionsRef = require(Packages.Scheduler.tracing).__interactionsRef
local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
-- local enableSchedulerTracing = ReactFeatureFlags.enableSchedulerTracing
local decoupleUpdatePriorityFromScheduler =
	ReactFeatureFlags.decoupleUpdatePriorityFromScheduler
local invariant = require(Packages.Shared).invariant
local describeError = require(Packages.Shared).describeError
local ReactFiberLane = require(script.Parent.ReactFiberLane)
local SyncLanePriority = ReactFiberLane.SyncLanePriority
local getCurrentUpdateLanePriority = ReactFiberLane.getCurrentUpdateLanePriority
local setCurrentUpdateLanePriority = ReactFiberLane.setCurrentUpdateLanePriority

local Scheduler_runWithPriority = Scheduler.unstable_runWithPriority
local Scheduler_scheduleCallback = Scheduler.unstable_scheduleCallback
local Scheduler_cancelCallback = Scheduler.unstable_cancelCallback
local Scheduler_shouldYield = Scheduler.unstable_shouldYield
local Scheduler_requestPaint = Scheduler.unstable_requestPaint
local Scheduler_now = Scheduler.unstable_now
local Scheduler_getCurrentPriorityLevel = Scheduler.unstable_getCurrentPriorityLevel
local Scheduler_ImmediatePriority = Scheduler.unstable_ImmediatePriority
local Scheduler_UserBlockingPriority = Scheduler.unstable_UserBlockingPriority
local Scheduler_NormalPriority = Scheduler.unstable_NormalPriority
local Scheduler_LowPriority = Scheduler.unstable_LowPriority
local Scheduler_IdlePriority = Scheduler.unstable_IdlePriority

-- deviation: Instead of defining these here, we require them from a small file
-- with _just_ these constant definitions; it helps us avoid a circular require
-- issue with `ReactFiberLanes`
local ReactFiberSchedulerPriorities =
	require(script.Parent["ReactFiberSchedulerPriorities.roblox"])
local ImmediatePriority = ReactFiberSchedulerPriorities.ImmediatePriority
local UserBlockingPriority = ReactFiberSchedulerPriorities.UserBlockingPriority
local NormalPriority = ReactFiberSchedulerPriorities.NormalPriority
local LowPriority = ReactFiberSchedulerPriorities.LowPriority
local IdlePriority = ReactFiberSchedulerPriorities.IdlePriority
local NoPriority = ReactFiberSchedulerPriorities.NoPriority

-- deviation: common types
type Array<T> = { [number]: T }

-- deviation: pre-declare functions
local flushSyncCallbackQueueImpl

-- if enableSchedulerTracing)
--   -- Provide explicit error message when production+profiling bundle of e.g.
--   -- react-dom is used with production (non-profiling) bundle of
--   -- scheduler/tracing
--   invariant(
--     __interactionsRef ~= nil and __interactionsRef.current ~= nil,
--     'It is not supported to run the profiling version of a renderer (for ' +
--       'example, `react-dom/profiling`) without also replacing the ' +
--       '`scheduler/tracing` module with `scheduler/tracing-profiling`. Your ' +
--       'bundler might have a setting for aliasing both modules. Learn more at ' +
--       'https://reactjs.org/link/profiling',
--   )
-- end

export type SchedulerCallback = (isSync: boolean) -> SchedulerCallback | nil

-- ROBLOX deviation START: don't allow extension unless we need to
-- type SchedulerCallbackOptions = { timeout: number?, ... };
type SchedulerCallbackOptions = { timeout: number? }
-- ROBLOX deviation END
local fakeCallbackNode = {}

local shouldYield = Scheduler_shouldYield
local requestPaint
-- Fall back gracefully if we're running an older version of Scheduler.
if Scheduler_requestPaint ~= nil then
	requestPaint = Scheduler_requestPaint
else
	requestPaint = function() end
end

local syncQueue: Array<SchedulerCallback>? = nil
local immediateQueueCallbackNode: any? = nil
local isFlushingSyncQueue: boolean = false
local initialTimeMs: number = Scheduler_now()

-- -- If the initial timestamp is reasonably small, use Scheduler's `now` directly.
-- -- This will be the case for modern browsers that support `performance.now`. In
-- -- older browsers, Scheduler falls back to `Date.now`, which returns a Unix
-- -- timestamp. In that case, subtract the module initialization time to simulate
-- -- the behavior of performance.now and keep our times small enough to fit
-- -- within 32 bits.
-- -- TODO: Consider lifting this into Scheduler.
-- ROBLOX FIXME: properly account for ms vs s from tick
-- local now = initialTimeMs < 10000
--   and Scheduler_now
--   or function()
--     return Scheduler_now() - initialTimeMs
--   end

-- deviation: Roblox uses `tick` under the hood, which is more like the unix
-- timestamp behavior referenced above
local function now(): number
	return Scheduler_now() - initialTimeMs
end

local function getCurrentPriorityLevel(): ReactPriorityLevel
	local currentPriorityLevel = Scheduler_getCurrentPriorityLevel()
	if currentPriorityLevel == Scheduler_ImmediatePriority then
		return ImmediatePriority
	elseif currentPriorityLevel == Scheduler_UserBlockingPriority then
		return UserBlockingPriority
	elseif currentPriorityLevel == Scheduler_NormalPriority then
		return NormalPriority
	elseif currentPriorityLevel == Scheduler_LowPriority then
		return LowPriority
	elseif currentPriorityLevel == Scheduler_IdlePriority then
		return IdlePriority
	else
		invariant(false, "Unknown priority level.")
		-- deviation: FIXME: Luau needs explicit return here
		return NoPriority
	end
end

function reactPriorityToSchedulerPriority(reactPriorityLevel)
	if reactPriorityLevel == ImmediatePriority then
		return Scheduler_ImmediatePriority
	elseif reactPriorityLevel == UserBlockingPriority then
		return Scheduler_UserBlockingPriority
	elseif reactPriorityLevel == NormalPriority then
		return Scheduler_NormalPriority
	elseif reactPriorityLevel == LowPriority then
		return Scheduler_LowPriority
	elseif reactPriorityLevel == IdlePriority then
		return Scheduler_IdlePriority
	else
		invariant(false, "Unknown priority level.")
		-- deviation: return appeases Luau
		return nil
	end
end

-- ROBLOX FIXME Luau: should be T... but hits CLI-50289: failure to unify
local function runWithPriority<T...>(
	reactPriorityLevel: ReactPriorityLevel,
	fn: () -> T...
): ...any
	local priorityLevel = reactPriorityToSchedulerPriority(reactPriorityLevel)
	return Scheduler_runWithPriority(priorityLevel, fn)
end

local function scheduleCallback(
	reactPriorityLevel: ReactPriorityLevel,
	callback: SchedulerCallback,
	options: SchedulerCallbackOptions | nil
)
	local priorityLevel = reactPriorityToSchedulerPriority(reactPriorityLevel)
	return Scheduler_scheduleCallback(priorityLevel, callback, options)
end

local function scheduleSyncCallback(callback: SchedulerCallback)
	-- Push this callback into an internal queue. We'll flush these either in
	-- the next tick, or earlier if something calls `flushSyncCallbackQueue`.
	if syncQueue == nil then
		syncQueue = { callback }
		-- Flush the queue in the next tick, at the earliest.
		immediateQueueCallbackNode = Scheduler_scheduleCallback(
			Scheduler_ImmediatePriority,
			flushSyncCallbackQueueImpl
		)
	else
		-- Push onto existing queue. Don't need to schedule a callback because
		-- we already scheduled one when we created the queue.
		local coercedSyncQueue = syncQueue
		table.insert(coercedSyncQueue, callback)
	end
	return fakeCallbackNode
end

local function cancelCallback(callbackNode: any)
	if callbackNode ~= fakeCallbackNode then
		Scheduler_cancelCallback(callbackNode)
	end
end

local function flushSyncCallbackQueue(): boolean
	if immediateQueueCallbackNode ~= nil then
		local node = immediateQueueCallbackNode
		immediateQueueCallbackNode = nil
		Scheduler_cancelCallback(node)
	end
	return flushSyncCallbackQueueImpl()
end

flushSyncCallbackQueueImpl = function()
	if not isFlushingSyncQueue and syncQueue ~= nil then
		-- Prevent re-entrancy.
		isFlushingSyncQueue = true
		local i = 1
		if decoupleUpdatePriorityFromScheduler then
			local previousLanePriority = getCurrentUpdateLanePriority()
			-- ROBLOX deviation: YOLO flag for disabling pcall
			local ok = true
			local result
			if not _G.__YOLO__ then
				-- ROBLOX performance: hoist non-throwables out of try{} to eliminate anon function
				local isSync = true
				local queue = syncQueue

				setCurrentUpdateLanePriority(SyncLanePriority)
				ok, result = xpcall(
					runWithPriority,
					describeError,
					ImmediatePriority,
					-- ROBLOX FIXME Luau: Luau sees this as returning void, but then sees an explicit return in runWithPriority and errors
					function(): ...any
						for index, callback in queue do
							i = index
							repeat
								-- ROBLOX FIXME Luau: Luau doesn't understand loop until nil construct
								callback = callback(isSync) :: any
							until callback == nil
						end
					end
				)
				syncQueue = nil
			else
				ok = true
				local isSync = true
				local queue = syncQueue

				setCurrentUpdateLanePriority(SyncLanePriority)
				-- ROBLOX FIXME Luau: Luau sees this as returning void, but then sees an explicit return in runWithPriority and errors
				runWithPriority(ImmediatePriority, function(): ...any
					for index, callback in queue do
						i = index
						repeat
							-- ROBLOX FIXME Luau: Luau doesn't understand loop until nil construct
							callback = callback(isSync) :: any
						until callback == nil
						i += 1
					end
				end)
				syncQueue = nil
			end

			-- finally
			setCurrentUpdateLanePriority(previousLanePriority)
			isFlushingSyncQueue = false

			if not ok then
				-- If something throws, leave the remaining callbacks on the queue.
				if syncQueue ~= nil then
					syncQueue = Array.slice(syncQueue, i + 1)
				end
				-- Resume flushing in the next tick
				Scheduler_scheduleCallback(
					Scheduler_ImmediatePriority,
					flushSyncCallbackQueue
				)
				error(result)
			end
		else
			-- ROBLOX deviation: YOLO flag for disabling pcall
			local ok, result
			if not _G.__YOLO__ then
				-- ROBLOX performance: hoist non-throwables out of try{} to eliminate anon function
				local isSync = true
				local queue = syncQueue

				ok, result = xpcall(
					runWithPriority,
					describeError,
					ImmediatePriority,
					-- ROBLOX FIXME Luau: Luau sees this as returning void, but then sees an explicit return in runWithPriority and errors
					function(): ...any
						for index, callback in queue do
							i = index
							repeat
								-- ROBLOX FIXME Luau: Luau doesn't understand loop until nil construct
								callback = callback(isSync) :: any
							until callback == nil
						end
					end
				)
				syncQueue = nil
			else
				ok = true
				local isSync = true
				local queue = syncQueue
				-- ROBLOX FIXME Luau: Luau sees this as returning void, but then sees an explicit return in runWithPriority and errors
				runWithPriority(ImmediatePriority, function(): ...any
					for index, callback in queue do
						i = index
						repeat
							-- ROBLOX FIXME Luau: Luau doesn't understand loop until nil construct
							callback = callback(isSync) :: any
						until callback == nil
					end
				end)
				syncQueue = nil
			end

			-- finally
			isFlushingSyncQueue = false

			if not ok then
				-- If something throws, leave the remaining callbacks on the queue.
				if syncQueue ~= nil then
					syncQueue = Array.slice(syncQueue, i + 1)
				end
				-- Resume flushing in the next tick
				Scheduler_scheduleCallback(
					Scheduler_ImmediatePriority,
					flushSyncCallbackQueue
				)
				error(result)
			end
		end
		return true
	else
		return false
	end
end

return {
	ImmediatePriority = ImmediatePriority,
	UserBlockingPriority = UserBlockingPriority,
	NormalPriority = NormalPriority,
	LowPriority = LowPriority,
	IdlePriority = IdlePriority,
	NoPriority = NoPriority,

	getCurrentPriorityLevel = getCurrentPriorityLevel,
	flushSyncCallbackQueue = flushSyncCallbackQueue,
	runWithPriority = runWithPriority,
	scheduleCallback = scheduleCallback,
	scheduleSyncCallback = scheduleSyncCallback,
	cancelCallback = cancelCallback,
	now = now,
	requestPaint = requestPaint,
	shouldYield = shouldYield,
}
