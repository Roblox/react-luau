-- ROBLOX upstream: https://github.com/facebook/react/blob/5474a83e258b497584bed9df95de1d554bc53f89/packages/scheduler/src/forks/SchedulerHostConfig.default.js
--!strict
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
]]

local Packages = script.Parent.Parent.Parent
local ReactGlobals = require(Packages.ReactGlobals)
local LuauPolyfill = require(Packages.LuauPolyfill)
type Error = LuauPolyfill.Error
local Object = LuauPolyfill.Object
local Shared = require(Packages.Shared)
local console = Shared.console
local errorToString = Shared.errorToString
local describeError = Shared.describeError
local SafeFlags = require(Packages.SafeFlags)

-- ROBLOX deviation: getCurrentTime will always map to `tick` in Luau
local getCurrentTime = function()
	-- Return a result in milliseconds
	return os.clock() * 1000
end

-- ROBLOX deviation: This module in React exports a different implementation if
-- it detects certain APIs from the DOM interface. We instead attempt to
-- approximate that behavior so that we can access features like dividing work
-- according to frame time

-- Capture local references to native APIs, in case a polyfill overrides them.
local setTimeout = LuauPolyfill.setTimeout
local clearTimeout = LuauPolyfill.clearTimeout

local isMessageLoopRunning = false
local scheduledHostCallback: ((boolean, number) -> boolean) | nil = nil
local taskTimeoutID = Object.None

local GetFIntReactSchedulerYieldInterval =
	SafeFlags.createGetFInt("ReactSchedulerYieldInterval2", 15)
local FIntReactSchedulerDesiredFrameRate =
	SafeFlags.createGetFInt("ReactSchedulerDesiredFrameRate", 60)()
local FIntReactSchedulerMinimumFrameRate =
	SafeFlags.createGetFInt("ReactSchedulerMinFrameRate", 30)()
local FFlagReactSchedulerEnableDeferredWork =
	SafeFlags.createGetFFlag("ReactSchedulerEnableDeferredWork")()
local FFlagReactSchedulerSetFrameMarkerOnHeartbeatEnd =
	SafeFlags.createGetFFlag("ReactSchedulerSetFrameMarkerOnHeartbeatEnd")()
local FFlagReactSchedulerSetTargetMsByHeartbeatDelta =
	SafeFlags.createGetFFlag("ReactSchedulerSetTargetMsByHeartbeatDelta")()
local FIntReactSchedulerNumberOfLookbackFrames =
	SafeFlags.createGetFInt("ReactSchedulerNumberOfLookbackFrames", 1)()
local FFlagReactSchedulerLookbackUseRingBuffer =
	SafeFlags.createGetFFlag("ReactSchedulerLookbackUseRingBuffer")()

-- ROBLOX deviation: support deferred re-entrants before yielding to the next frame
local isDeferred = false
local frameStartTime = 0
local desiredMillisecondsPerFrame = 1000 / FIntReactSchedulerDesiredFrameRate
local maxMillisecondsPerFrame = 1000 / FIntReactSchedulerMinimumFrameRate
local targetMillisecondsPerFrame = desiredMillisecondsPerFrame
local averageMillisecondsPerFrame = targetMillisecondsPerFrame

local heartbeatConection: RBXScriptConnection? = nil
local lookbackBuffer = if FFlagReactSchedulerLookbackUseRingBuffer
	then table.create(FIntReactSchedulerNumberOfLookbackFrames)
	else nil :: never
local lookbackIndex = 1

local function createHeartbeatConnection()
	if heartbeatConection then
		heartbeatConection:Disconnect()
	end
	heartbeatConection = game:GetService("RunService").Heartbeat
		:Connect(function(step: number)
			if FIntReactSchedulerNumberOfLookbackFrames > 1 then
				if FFlagReactSchedulerLookbackUseRingBuffer then
					lookbackBuffer[lookbackIndex] = step * 1000
					lookbackIndex = (
						lookbackIndex % FIntReactSchedulerNumberOfLookbackFrames
					) + 1
					local totalFrameTime = 0
					local totalFrames = FIntReactSchedulerNumberOfLookbackFrames
					for i = 1, totalFrames do
						if lookbackBuffer[i] == nil then
							totalFrames = i - 1
							break
						end
						totalFrameTime += lookbackBuffer[i]
					end
					averageMillisecondsPerFrame = totalFrameTime / totalFrames
				else
					local nFrames = FIntReactSchedulerNumberOfLookbackFrames
					averageMillisecondsPerFrame = (
						averageMillisecondsPerFrame * (nFrames - 1) + step * 1000
					) / nFrames
				end
				targetMillisecondsPerFrame = math.clamp(
					averageMillisecondsPerFrame,
					desiredMillisecondsPerFrame,
					maxMillisecondsPerFrame
				)
			else
				targetMillisecondsPerFrame = math.clamp(
					step * 1000,
					desiredMillisecondsPerFrame,
					maxMillisecondsPerFrame
				)
			end
		end)
end

if FFlagReactSchedulerSetTargetMsByHeartbeatDelta then
	createHeartbeatConnection()
end

local function setFrameMarker()
	frameStartTime = getCurrentTime()
end

-- Scheduler periodically yields in case there is other work on the main
-- thread, like user events. By default, it yields multiple times per frame.
-- It does not attempt to align with frame boundaries, since most tasks don't
-- need to be frame aligned; for those that do, use requestAnimationFrame.
local yieldInterval = GetFIntReactSchedulerYieldInterval()
local deadline = 0

type SchedulerFlags = {
	yieldInterval: number?,
	deferredWork: boolean?,
	heartbeatFrameMarker: boolean?,
	targetMsByHeartbeatDelta: boolean?,
	numberOfLookbackFrames: number?,
	lookbackUseRingBuffer: boolean?,
}

local function setSchedulerFlags(flags: SchedulerFlags)
	if flags.yieldInterval ~= nil then
		yieldInterval = flags.yieldInterval
	end
	if flags.deferredWork ~= nil then
		FFlagReactSchedulerEnableDeferredWork = flags.deferredWork
	end
	if flags.heartbeatFrameMarker ~= nil then
		FFlagReactSchedulerSetFrameMarkerOnHeartbeatEnd = flags.heartbeatFrameMarker
	end
	if flags.targetMsByHeartbeatDelta ~= nil then
		FFlagReactSchedulerSetTargetMsByHeartbeatDelta = flags.targetMsByHeartbeatDelta
		if flags.targetMsByHeartbeatDelta then
			createHeartbeatConnection()
		else
			if heartbeatConection then
				heartbeatConection:Disconnect()
				heartbeatConection = nil
				targetMillisecondsPerFrame = desiredMillisecondsPerFrame -- reset to default
			end
		end
	end
	if flags.numberOfLookbackFrames ~= nil then
		FIntReactSchedulerNumberOfLookbackFrames = flags.numberOfLookbackFrames
	end
	if flags.lookbackUseRingBuffer ~= nil then
		FFlagReactSchedulerLookbackUseRingBuffer = flags.lookbackUseRingBuffer
	end
end

local function getSchedulerFlags(): SchedulerFlags
	return {
		yieldInterval = yieldInterval,
		deferredWork = FFlagReactSchedulerEnableDeferredWork,
		heartbeatFrameMarker = FFlagReactSchedulerSetFrameMarkerOnHeartbeatEnd,
		targetMsByHeartbeatDelta = FFlagReactSchedulerSetTargetMsByHeartbeatDelta,
		numberOfLookbackFrames = FIntReactSchedulerNumberOfLookbackFrames,
		lookbackUseRingBuffer = FFlagReactSchedulerLookbackUseRingBuffer,
	}
end

local function doesBudgetRemain(): boolean
	local timeElapsed = getCurrentTime() - frameStartTime
	local budget = targetMillisecondsPerFrame - timeElapsed
	return budget > yieldInterval
end

-- ROBLOX deviation: Removed some logic around browser functionality that's not
-- present in the roblox engine
local function shouldYieldToHost()
	return getCurrentTime() >= deadline
end

-- Since we yield every frame regardless, `requestPaint` has no effect.
local function requestPaint() end

local function forceFrameRate(fps)
	if fps < 0 or fps > 125 then
		console.warn(
			"forceFrameRate takes a positive int between 0 and 125, "
				.. "forcing frame rates higher than 125 fps is not supported"
		)
		return
	end
	if fps > 0 then
		yieldInterval = math.floor(1000 / fps)
	else
		-- reset the framerate
		yieldInterval = 5
	end
end

local function performWorkUntilDeadline()
	if scheduledHostCallback ~= nil then
		local currentTime = getCurrentTime()
		-- Yield after `yieldInterval` ms, regardless of where we are in the vsync
		-- cycle. This means there's always time remaining at the beginning of
		-- the message event.
		deadline = currentTime + yieldInterval
		local hasTimeRemaining = true

		if
			FFlagReactSchedulerEnableDeferredWork
			and not FFlagReactSchedulerSetFrameMarkerOnHeartbeatEnd
		then
			if not isDeferred then
				frameStartTime = currentTime
			end
		end

		if FFlagReactSchedulerSetFrameMarkerOnHeartbeatEnd then
			-- We only want to set no time remaining if we are deferring work
			-- This ensures we run React at least once per frame if there's work
			-- While this helps avoid starving React, it doesn't guarantee it will
			if isDeferred then
				if not doesBudgetRemain() then
					hasTimeRemaining = false
				end
			end
		end

		local ok, result
		local function doWork()
			local hasMoreWork = (scheduledHostCallback :: any)(
				hasTimeRemaining,
				currentTime
			)
			if not hasMoreWork then
				isMessageLoopRunning = false
				scheduledHostCallback = nil
			else
				-- If there's more work, schedule the next message event at the end
				-- of the preceding one.

				-- ROBLOX deviation: Use task api instead of message channel;
				-- depending on whether or not we still have time to perform
				-- more work, either yield and defer till later this frame, or
				-- delay work till next frame

				if FFlagReactSchedulerEnableDeferredWork then
					if doesBudgetRemain() then
						-- Budget remains for more work this frame, defer
						isDeferred = true
						task.defer(performWorkUntilDeadline)
					else
						-- No budget remains for more work this frame, delay to next frame
						isDeferred = false
						task.delay(0, performWorkUntilDeadline)
						if FFlagReactSchedulerSetFrameMarkerOnHeartbeatEnd then
							task.defer(setFrameMarker)
						end
					end
				else
					task.delay(0, performWorkUntilDeadline)
				end
			end
			return nil
		end
		if not ReactGlobals.__YOLO__ then
			ok, result = xpcall(doWork, describeError)
		else
			result = doWork()
			ok = true
		end

		if not ok then
			-- If a scheduler task throws, exit the current coroutine so the
			-- error can be observed.
			task.delay(0, performWorkUntilDeadline)
			if FFlagReactSchedulerSetFrameMarkerOnHeartbeatEnd then
				task.defer(setFrameMarker)
			end

			-- ROBLOX FIXME: the top-level Luau VM handler doesn't deal with
			-- non-string errors, so massage it until VM support lands
			error(errorToString(result :: any))
		end
	else
		isMessageLoopRunning = false
	end
end

-- ROBLOX deviation: wrap performWorkUntilDeadline for cleaner MicroProfiler attribution
local function wrapPerformWorkWithCoroutine(performWork)
	local co = coroutine.create(function()
		while true do
			-- We wrap `performWork` with a coroutine so that it can yield internally
			-- but not implicitly yield the entire `co` coroutine
			local wrapped = coroutine.wrap(performWork)
			local ok, result = pcall(wrapped)
			coroutine.yield(ok, result)
		end
	end)

	return function()
		local _, ok, result = coroutine.resume(co)
		-- Propogate errors from `co` so that it always stays alive
		if not ok then
			error(result)
		end
	end
end
performWorkUntilDeadline = wrapPerformWorkWithCoroutine(performWorkUntilDeadline)

local function requestHostCallback(callback)
	scheduledHostCallback = callback
	if not isMessageLoopRunning then
		isMessageLoopRunning = true

		task.delay(0, performWorkUntilDeadline)
		if FFlagReactSchedulerSetFrameMarkerOnHeartbeatEnd then
			task.defer(setFrameMarker)
		end
	end
end

local function cancelHostCallback()
	scheduledHostCallback = nil
end

local function requestHostTimeout(callback, ms)
	taskTimeoutID = setTimeout(function()
		callback(getCurrentTime())
	end, ms)
end

local function cancelHostTimeout()
	clearTimeout(taskTimeoutID)
	taskTimeoutID = Object.None
end

return {
	requestHostCallback = requestHostCallback,
	cancelHostCallback = cancelHostCallback,
	requestHostTimeout = requestHostTimeout,
	cancelHostTimeout = cancelHostTimeout,
	shouldYieldToHost = shouldYieldToHost,
	requestPaint = requestPaint,
	getCurrentTime = getCurrentTime,
	forceFrameRate = forceFrameRate,
	setSchedulerFlags = setSchedulerFlags,
	getSchedulerFlags = getSchedulerFlags,
}
