local initializeScheduler = require(script.Scheduler)

local function onlyInTestError(functionName: string)
	return function()
		error(functionName .. " is only available in tests, not in production")
	end
end

local Scheduler = initializeScheduler(--[[ no host config, use default ]])
local Tracing = require(script.Tracing)
local TracingSubscriptions = require(script.TracingSubscriptions)
-- ROBLOX deviation export Tracing type from the package exports to avoid direct file access
export type Interaction = Tracing.Interaction

local exports = {
    getJestMatchers = Scheduler.getJestMatcher,
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
    unstable_flushAllWithoutAsserting = onlyInTestError("unstable_flushAllWithoutAsserting"),
    unstable_flushAll = onlyInTestError("unstable_flushAll"),
    unstable_flushNumberOfYields = onlyInTestError("unstable_flushNumberOfYields"),
    unstable_clearYields = onlyInTestError("unstable_clearYields"),
    unstable_advanceTime = onlyInTestError("unstable_advanceTime"),
    unstable_flushExpired = onlyInTestError("unstable_flushExpired"),
    unstable_yieldValue = onlyInTestError("unstable_yieldValue"),

    tracing = {
        unstable_wrap = onlyInTestError("unstable_wrap"),
        __interactionsRef = {},
        __subscriberRef = {}
    }
}

for k, v in pairs(Tracing) do
    exports.tracing.k = v
end
for k, v in pairs(TracingSubscriptions) do
    exports.tracing.k = v
end

return exports