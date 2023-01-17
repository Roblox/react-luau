-- ROBLOX upstream: https://github.com/facebook/react/blob/142d4f1c00c66f3d728177082dbc027fd6335115/packages/react-reconciler/src/ReactProfilerTimer.new.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

local Packages = script.Parent.Parent

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber

local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
local enableProfilerTimer = ReactFeatureFlags.enableProfilerTimer
local enableProfilerCommitHooks = ReactFeatureFlags.enableProfilerCommitHooks

local ReactWorkTags = require(script.Parent.ReactWorkTags)
local Profiler = ReactWorkTags.Profiler

-- Intentionally not named imports because Rollup would use dynamic dispatch for
-- CommonJS interop named imports.
local Scheduler = require(Packages.Scheduler)

local now = Scheduler.unstable_now

export type ProfilerTimer = {
	getCommitTime: () -> number,
	recordCommitTime: () -> (),
	startProfilerTimer: (Fiber) -> (),
	stopProfilerTimerIfRunning: (Fiber) -> (),
	stopProfilerTimerIfRunningAndRecordDelta: (Fiber) -> (),
	-- ...
}

local commitTime: number = 0
local layoutEffectStartTime: number = -1
local profilerStartTime: number = -1
local passiveEffectStartTime: number = -1

function getCommitTime(): number
	return commitTime
end

function recordCommitTime(): ()
	if not enableProfilerTimer then
		return
	end
	commitTime = now()
end

function startProfilerTimer(fiber: Fiber): ()
	if not enableProfilerTimer then
		return
	end

	profilerStartTime = now()

	-- ROBLOX deviation: JS can compare null/undefined to 0, but Lua can't
	if fiber.actualStartTime ~= nil and (fiber.actualStartTime :: number) < 0 then
		fiber.actualStartTime = now()
	end
end

function stopProfilerTimerIfRunning(fiber: Fiber): ()
	if not enableProfilerTimer then
		return
	end
	profilerStartTime = -1
end

function stopProfilerTimerIfRunningAndRecordDelta(
	fiber: Fiber,
	overrideBaseTime: boolean
): ()
	if not enableProfilerTimer then
		return
	end

	if profilerStartTime >= 0 then
		local elapsedTime_ = now() - profilerStartTime
		fiber.actualDuration += elapsedTime_
		if overrideBaseTime then
			fiber.selfBaseDuration = elapsedTime_
		end
		profilerStartTime = -1
	end
end

function recordLayoutEffectDuration(fiber: Fiber): ()
	if not enableProfilerTimer or not enableProfilerCommitHooks then
		return
	end

	if layoutEffectStartTime >= 0 then
		local elapsedTime_ = now() - layoutEffectStartTime

		layoutEffectStartTime = -1

		-- Store duration on the next nearest Profiler ancestor.
		local parentFiber = fiber.return_
		while parentFiber ~= nil do
			if parentFiber.tag == Profiler then
				local parentStateNode = parentFiber.stateNode
				parentStateNode.effectDuration += elapsedTime_
				break
			end
			parentFiber = parentFiber.return_
		end
	end
end

function recordPassiveEffectDuration(fiber: Fiber): ()
	if not enableProfilerTimer or not enableProfilerCommitHooks then
		return
	end

	if passiveEffectStartTime >= 0 then
		local elapsedTime_ = now() - passiveEffectStartTime

		passiveEffectStartTime = -1

		-- Store duration on the next nearest Profiler ancestor.
		local parentFiber = fiber.return_
		while parentFiber ~= nil do
			if parentFiber.tag == Profiler then
				local parentStateNode = parentFiber.stateNode
				if parentStateNode ~= nil then
					-- Detached fibers have their state node cleared out.
					-- In this case, the return pointer is also cleared out,
					-- so we won't be able to report the time spent in this Profiler's subtree.
					parentStateNode.passiveEffectDuration += elapsedTime_
				end
				break
			end
			parentFiber = parentFiber.return_
		end
	end
end

function startLayoutEffectTimer(): ()
	if not enableProfilerTimer or not enableProfilerCommitHooks then
		return
	end
	layoutEffectStartTime = now()
end

function startPassiveEffectTimer(): ()
	if not enableProfilerTimer or not enableProfilerCommitHooks then
		return
	end
	passiveEffectStartTime = now()
end

function transferActualDuration(fiber: Fiber): ()
	-- Transfer time spent rendering these children so we don't lose it
	-- after we rerender. This is used as a helper in special cases
	-- where we should count the work of multiple passes.
	local child = fiber.child
	while child do
		fiber.actualDuration += child.actualDuration
		child = child.sibling
	end
end

return {
	getCommitTime = getCommitTime,
	recordCommitTime = recordCommitTime,
	recordLayoutEffectDuration = recordLayoutEffectDuration,
	recordPassiveEffectDuration = recordPassiveEffectDuration,
	startLayoutEffectTimer = startLayoutEffectTimer,
	startPassiveEffectTimer = startPassiveEffectTimer,
	startProfilerTimer = startProfilerTimer,
	stopProfilerTimerIfRunning = stopProfilerTimerIfRunning,
	stopProfilerTimerIfRunningAndRecordDelta = stopProfilerTimerIfRunningAndRecordDelta,
	transferActualDuration = transferActualDuration,
}
