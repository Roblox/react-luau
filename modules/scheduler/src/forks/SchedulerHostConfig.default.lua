-- ROBLOX upstream: https://github.com/facebook/react/blob/5474a83e258b497584bed9df95de1d554bc53f89/packages/scheduler/src/forks/SchedulerHostConfig.default.js
--!strict
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
]]

local Packages = script.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
type Error = LuauPolyfill.Error
local Object = LuauPolyfill.Object
local Shared = require(Packages.Shared)
local console = Shared.console
local errorToString = Shared.errorToString
local describeError = Shared.describeError

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

-- Scheduler periodically yields in case there is other work on the main
-- thread, like user events. By default, it yields multiple times per frame.
-- It does not attempt to align with frame boundaries, since most tasks don't
-- need to be frame aligned; for those that do, use requestAnimationFrame.
local yieldInterval = 15
local deadline = 0

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

				-- ROBLOX FIXME: What's the proper combination of task.defer and
				-- task.delay that makes this optimal?
				task.delay(0, performWorkUntilDeadline)
			end
			return nil
		end
		if not _G.__YOLO__ then
			ok, result = xpcall(doWork, describeError)
		else
			result = doWork()
			ok = true
		end

		if not ok then
			-- If a scheduler task throws, exit the current coroutine so the
			-- error can be observed.
			task.delay(0, performWorkUntilDeadline)

			-- ROBLOX FIXME: the top-level Luau VM handler doesn't deal with
			-- non-string errors, so massage it until VM support lands
			error(errorToString(result :: any))
		end
	else
		isMessageLoopRunning = false
	end
end

local function requestHostCallback(callback)
	scheduledHostCallback = callback
	if not isMessageLoopRunning then
		isMessageLoopRunning = true

		task.delay(0, performWorkUntilDeadline)
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
}
