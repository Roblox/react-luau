-- ROBLOX upstream: https://github.com/facebook/react/blob/5474a83e258b497584bed9df95de1d554bc53f89/packages/scheduler/src/forks/SchedulerHostConfig.mock.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
* @flow
]]

local exports = {}

local currentTime: number = 0
local scheduledCallback: ((boolean, number) -> ()) | nil = nil
local scheduledTimeout: ((number) -> ()) | nil = nil
local timeoutTime: number = -1
local yieldedValues: { [number]: any } | nil = nil
local expectedNumberOfYields: number = -1
local didStop: boolean = false
local isFlushing: boolean = false
local needsPaint: boolean = false
local shouldYieldForPaint: boolean = false
local Packages = script.Parent.Parent.Parent
local console = require(Packages.Shared).console
local ConsolePatchingDev = require(Packages.Shared).ConsolePatchingDev
local disabledLog = ConsolePatchingDev.disabledLog

exports.requestHostCallback = function(callback: (boolean) -> ())
	scheduledCallback = callback
end

exports.cancelHostCallback = function()
	scheduledCallback = nil
end

exports.requestHostTimeout = function(callback: (number) -> (), ms: number)
	scheduledTimeout = callback
	timeoutTime = currentTime + ms
end

exports.cancelHostTimeout = function()
	scheduledTimeout = nil
	timeoutTime = -1
end

exports.shouldYieldToHost = function(): boolean
	-- deviation: widening type to workaround Luau shortcomings
	-- https://jira.rbx.com/browse/CLI-35978
	local values: any = yieldedValues
	if
		(
			expectedNumberOfYields ~= -1
			and values ~= nil
			and #values >= expectedNumberOfYields
		) or (shouldYieldForPaint and needsPaint)
	then
		-- We yielded at least as many values as expected. Stop flushing.
		didStop = true
		return true
	end

	return false
end

exports.getCurrentTime = function(): number
	return currentTime
end

exports.forceFrameRate = function()
	-- No-op
end

exports.reset = function()
	if isFlushing then
		error("Cannot reset while already flushing work.")
	end

	currentTime = 0
	scheduledCallback = nil
	scheduledTimeout = nil
	timeoutTime = -1
	yieldedValues = nil
	expectedNumberOfYields = -1
	didStop = false
	isFlushing = false
	needsPaint = false
end

-- Should only be used via an assertion helper that inspects the yielded values.
exports.unstable_flushNumberOfYields = function(count: number)
	if isFlushing then
		error("Already flushing work.")
	end

	if scheduledCallback ~= nil then
		local cb = scheduledCallback
		expectedNumberOfYields = count
		isFlushing = true

		local ok, result = pcall(function()
			local hasMoreWork = true
			repeat
				hasMoreWork = cb(true, currentTime)
			until not hasMoreWork or didStop

			if not hasMoreWork then
				scheduledCallback = nil
			end
		end)

		expectedNumberOfYields = -1
		didStop = false
		isFlushing = false

		if not ok then
			error(result)
		end
	end
end

exports.unstable_flushUntilNextPaint = function()
	if isFlushing then
		error("Already flushing work.")
	end

	if scheduledCallback ~= nil then
		local cb = scheduledCallback
		shouldYieldForPaint = true
		needsPaint = false
		isFlushing = true
		-- ROBLOX try
		local ok, result = pcall(function()
			local hasMoreWork = true
			repeat
				hasMoreWork = cb(true, currentTime)
			until not hasMoreWork or didStop

			if not hasMoreWork then
				scheduledCallback = nil
			end
		end)

		-- ROBLOX finally
		shouldYieldForPaint = false
		didStop = false
		isFlushing = false

		if not ok then
			error(result)
		end
	end
end

exports.unstable_flushExpired = function()
	if isFlushing then
		error("Already flushing work.")
	end
	if scheduledCallback ~= nil then
		isFlushing = true
		local ok, result = pcall(function()
			-- deviation: widening type to workaround Luau shortcomings
			-- https://jira.rbx.com/browse/CLI-35978
			local callback: any = scheduledCallback
			local hasMoreWork = callback(false, currentTime)
			if not hasMoreWork then
				scheduledCallback = nil
			end
		end)

		isFlushing = false

		if not ok then
			error(result)
		end
	end
end

exports.unstable_flushAllWithoutAsserting = function(): boolean
	-- Returns false if no work was flushed.
	if isFlushing then
		error("Already flushing work.")
	end
	if scheduledCallback ~= nil then
		local cb = scheduledCallback
		isFlushing = true
		local ok, result = pcall(function()
			local hasMoreWork = true
			repeat
				hasMoreWork = cb(true, currentTime)
			until not hasMoreWork

			if not hasMoreWork then
				scheduledCallback = nil
			end
		end)

		isFlushing = false

		if not ok then
			error(result)
		end

		return true
	else
		return false
	end
end

exports.unstable_clearYields = function(): { [number]: any }
	if yieldedValues == nil then
		return {}
	end
	local values = yieldedValues
	yieldedValues = nil
	return values
end

exports.unstable_flushAll = function()
	if yieldedValues ~= nil then
		error(
			"Log is not empty. Assert on the log of yielded values before "
				.. "flushing additional work."
		)
	end
	exports.unstable_flushAllWithoutAsserting()
	if yieldedValues ~= nil then
		error(
			"While flushing work, something yielded a value. Use an "
				.. "assertion helper to assert on the log of yielded values, e.g. "
				.. "expect(Scheduler).toFlushAndYield([...])"
		)
	end
end

exports.unstable_yieldValue = function(value: any)
	-- eslint-disable-next-line react-internal/no-production-logging
	if console.log == disabledLog then
		-- If console.log has been patched, we assume we're in render
		-- replaying and we ignore any values yielding in the second pass.
		return
	end
	if yieldedValues == nil then
		yieldedValues = { value }
	else
		-- deviation: widening type to workaround Luau shortcomings
		-- https://jira.rbx.com/browse/CLI-35978
		local values: any = yieldedValues
		table.insert(values, value)
	end
end

exports.unstable_advanceTime = function(ms: number)
	-- eslint-disable-next-line react-internal/no-production-logging
	if console.log == disabledLog then
		-- If console.log has been patched, we assume we're in render
		-- replaying and we ignore any time advancing in the second pass.
		return
	end
	currentTime += ms

	if scheduledTimeout ~= nil and timeoutTime <= currentTime then
		-- deviation: widening type to workaround Luau shortcomings
		-- https://jira.rbx.com/browse/CLI-35978
		local timeout: any = scheduledTimeout
		timeout(currentTime)
		timeoutTime = -1
		scheduledTimeout = nil
	end
end

exports.requestPaint = function()
	needsPaint = true
end

return exports
