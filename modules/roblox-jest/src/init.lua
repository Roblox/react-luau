--!nolint LocalShadowPedantic
local FakeTimers = require(script.FakeTimers)
local Module = require(script.Module)

-- override require from now to make sure Matchers are
-- hitting the Module's cache
local require = Module.requireOverride
local InteractionTracingMatchers = require(script.Matchers.interactionTracingMatchers)
local RobloxJest = {
	Matchers = {
		toErrorDev = require(script.Matchers.toErrorDev),
		toWarnDev = require(script.Matchers.toWarnDev),
		toLogDev = require(script.Matchers.toLogDev),
		toContainNoInteractions = InteractionTracingMatchers.toContainNoInteractions,
		toHaveBeenLastNotifiedOfInteraction = InteractionTracingMatchers.toHaveBeenLastNotifiedOfInteraction,
		toHaveBeenLastNotifiedOfWork = InteractionTracingMatchers.toHaveBeenLastNotifiedOfWork,
		toMatchInteraction = InteractionTracingMatchers.toMatchInteraction,
		toMatchInteractions = InteractionTracingMatchers.toMatchInteractions,
	},

	resetModules = Module.resetModules,
	mock = Module.mock,
	unmock = Module.unmock,

	-- ROBLOX TODO: use roblox-jest fake timers impl and delete these
	useFakeTimers = FakeTimers.useFakeTimers,
	useRealTimers = FakeTimers.useRealTimers,
	runAllTimers = FakeTimers.runAllTimers,
	advanceTimersByTime = FakeTimers.advanceTimersByTime,
	now = FakeTimers.now,
	resetFakeTimers = FakeTimers.reset,
	getTimerCount = FakeTimers.getTimerCount,

	testEnv = {
		require = Module.requireOverride,
		delay = FakeTimers.delayOverride,
		tick = FakeTimers.tickOverride,
		task = FakeTimers.taskOverride,
	},
}

return RobloxJest
