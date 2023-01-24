--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/efd8f6442d1aa7c4566fe812cba03e7e83aaccc3/packages/scheduler/index.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local initializeScheduler = require(script.Scheduler)

local function onlyInTestError(functionName: string)
	return function()
		error(functionName .. " is only available in tests, not in production")
	end
end

local Scheduler = initializeScheduler(nil --[[ no host config, use default ]])
local Tracing = require(script.Tracing)
local TracingSubscriptions = require(script.TracingSubscriptions)
-- ROBLOX deviation export Tracing type from the package exports to avoid direct file access
export type Interaction = Tracing.Interaction

-- Enables `act` to use mock scheduling logic when running tests. Since there
-- are numerous testing scenarios in which we call `require` on the Roact
-- library _before_ we bootstrap tests, we expose an additional global to toggle
-- this explicilty
if _G.__ROACT_17_MOCK_SCHEDULER__ then
	return require(script.unstable_mock)
end

local exports = {
	unstable_ImmediatePriority = Scheduler.unstable_ImmediatePriority,
	unstable_UserBlockingPriority = Scheduler.unstable_UserBlockingPriority,
	unstable_NormalPriority = Scheduler.unstable_NormalPriority,
	unstable_IdlePriority = Scheduler.unstable_IdlePriority,
	unstable_LowPriority = Scheduler.unstable_LowPriority,
	unstable_runWithPriority = Scheduler.unstable_runWithPriority,
	unstable_next = Scheduler.unstable_next,
	unstable_scheduleCallback = Scheduler.unstable_scheduleCallback,
	unstable_cancelCallback = Scheduler.unstable_cancelCallback,
	unstable_wrapCallback = Scheduler.unstable_wrapCallback,
	unstable_getCurrentPriorityLevel = Scheduler.unstable_getCurrentPriorityLevel,
	unstable_shouldYield = Scheduler.unstable_shouldYield,
	unstable_requestPaint = Scheduler.unstable_requestPaint,
	unstable_continueExecution = Scheduler.unstable_continueExecution,
	unstable_pauseExecution = Scheduler.unstable_pauseExecution,
	unstable_getFirstCallbackNode = Scheduler.unstable_getFirstCallbackNode,
	unstable_now = Scheduler.unstable_now,
	unstable_forceFrameRate = Scheduler.unstable_forceFrameRate,
	unstable_flushAllWithoutAsserting = onlyInTestError(
		"unstable_flushAllWithoutAsserting"
	) :: any,
	unstable_flushAll = onlyInTestError("unstable_flushAll"),
	unstable_flushNumberOfYields = onlyInTestError("unstable_flushNumberOfYields"),
	unstable_clearYields = onlyInTestError("unstable_clearYields") :: any,
	unstable_flushUntilNextPaint = onlyInTestError("unstable_clearYields"),
	unstable_advanceTime = onlyInTestError("unstable_advanceTime"),
	unstable_flushExpired = onlyInTestError("unstable_flushExpired"),
	unstable_yieldValue = onlyInTestError("unstable_yieldValue"),

	tracing = {
		unstable_wrap = onlyInTestError("unstable_wrap"),
		__interactionsRef = {},
		__subscriberRef = {},
	},
}

-- ROBLOX FIXME Luau: need to fix CLI-56768 to remove any cast
for k, v in Tracing :: any do
	exports.tracing[k] = v
end
for k, v in TracingSubscriptions :: any do
	exports.tracing[k] = v
end

return exports
