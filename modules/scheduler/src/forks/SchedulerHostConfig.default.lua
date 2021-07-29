-- upstream: https://github.com/facebook/react/blob/5474a83e258b497584bed9df95de1d554bc53f89/packages/scheduler/src/forks/SchedulerHostConfig.default.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
]]

local Packages = script.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)

local console = require(Packages.Shared).console

-- ROBLOX deviation: getCurrentTime will always map to `tick` in Luau
local getCurrentTime = function()
	-- Return a result in milliseconds
	return os.clock() * 1000
end

-- ROBLOX deviation: The implementation below is the "naive" implementation,
-- which is used in upstream when certain browser features are missing. It's
-- insufficient for our use case, since it does not respect the frame time
-- boundary

-- local setTimeout = LuauPolyfill.setTimeout
-- local clearTimeout = LuauPolyfill.clearTimeout

-- local exports = {}
-- exports.getCurrentTime = getCurrentTime

-- local _callback = nil
-- local _timeoutID = nil

-- local function _flushCallback()
-- 	if _callback ~= nil then
-- 		-- ROBLOX deviation: YOLO flag for disabling pcall
-- 		local ok, result
-- 		if not _G.__YOLO__ then
-- 			ok, result = pcall(function()
-- 				local currentTime = getCurrentTime()
-- 				local hasRemainingTime = true
-- 				_callback(hasRemainingTime, currentTime)
-- 				_callback = nil
-- 			end)
-- 		else
-- 			ok = true
-- 			local currentTime = getCurrentTime()
-- 			local hasRemainingTime = true
-- 			_callback(hasRemainingTime, currentTime)
-- 			_callback = nil
-- 		end

-- 		if not ok then
-- 			setTimeout(_flushCallback, 0)
-- 			error(result)
-- 		end
-- 	end
-- end

-- local function requestHostCallback(cb)
-- 	if _callback ~= nil then
-- 		-- Protect against re-entrancy.
-- 		setTimeout(requestHostCallback, 0, cb)
-- 	else
-- 		_callback = cb
-- 		setTimeout(_flushCallback, 0)
-- 	end
-- end

-- exports.requestHostCallback = requestHostCallback
-- exports.cancelHostCallback = function()
-- 	_callback = nil
-- end
-- exports.requestHostTimeout = function(cb, ms)
-- 	_timeoutID = setTimeout(cb, ms)
-- end
-- exports.cancelHostTimeout = function()
-- 	clearTimeout(_timeoutID)
-- end
-- exports.shouldYieldToHost = function()
-- 	return false
-- end
-- exports.requestPaint = function()
-- end
-- exports.forceFrameRate = function()
-- end

-- return exports

-- ROBLOX deviation: This module in React exports a different implementation if
-- it detects certain APIs from the DOM interface. We instead attempt to
-- approximate that behavior so that we can access features like dividing work
-- according to frame time

-- Capture local references to native APIs, in case a polyfill overrides them.
local setTimeout = LuauPolyfill.setTimeout
local clearTimeout = LuauPolyfill.clearTimeout

local isMessageLoopRunning = false
local scheduledHostCallback = nil
local taskTimeoutID = -1

-- Scheduler periodically yields in case there is other work on the main
-- thread, like user events. By default, it yields multiple times per frame.
-- It does not attempt to align with frame boundaries, since most tasks don't
-- need to be frame aligned; for those that do, use requestAnimationFrame.
local yieldInterval = 5
local deadline = 0



-- ROBLOX deviation: Removed some logic around browser functionality that's not
-- present in the roblox engine
local function shouldYieldToHost()
	return getCurrentTime() >= deadline
end

-- Since we yield every frame regardless, `requestPaint` has no effect.
local function requestPaint()
end

local function forceFrameRate(fps)
	if fps < 0 or fps > 125 then
		console.warn(
			"forceFrameRate takes a positive int between 0 and 125, " ..
			"forcing frame rates higher than 125 fps is not supported"
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
		local ok, result = pcall(function()
			local hasMoreWork = scheduledHostCallback(
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

				-- ROBLOX TODO: Use task api once it's stabilized
				setTimeout(performWorkUntilDeadline, 0)
				-- ROBLOX FIXME: What's the proper combination of task.defer and
				-- task.delay that makes this optimal?
				-- (task :: any).delay(0, performWorkUntilDeadline)
			end
		end)

		if not ok then
			-- If a scheduler task throws, exit the current browser task so the
			-- error can be observed.
			-- ROBLOX TODO: Use task api once it's stabilized
			setTimeout(performWorkUntilDeadline, 0)
			-- ROBLOX deviation: Use task api instead of message channel
			-- (task :: any).delay(0, performWorkUntilDeadline)
			error(result)
		end
	else
		isMessageLoopRunning = false
	end
end

local function requestHostCallback(callback)
	scheduledHostCallback = callback
	if not isMessageLoopRunning then
		isMessageLoopRunning = true

		-- ROBLOX TODO: Use task api once it's stabilized
		setTimeout(performWorkUntilDeadline, 0)
		-- ROBLOX deviation: Use task api instead of message channel
		-- (task :: any).delay(0, performWorkUntilDeadline)
	end
end

local function cancelHostCallback()
	scheduledHostCallback = nil
end

local function requestHostTimeout(callback, ms)
	taskTimeoutID = setTimeout(function()
		callback(getCurrentTime())
	end, ms);
end

local function cancelHostTimeout()
	clearTimeout(taskTimeoutID)
	taskTimeoutID = -1
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
