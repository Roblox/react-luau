-- ROBLOX upstream: https://github.com/facebook/react/blob/9abc2785cb070148d64fae81e523246b90b92016/packages/scheduler/src/__tests__/TracingSubscriptions-test.internal.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local jestExpect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it
local jest = JestGlobals.jest
local LuauPolyfill = require(Packages.LuauPolyfill)
local Set = LuauPolyfill.Set

describe("TracingSubscriptions", function()
	local SchedulerTracing
	local ReactFeatureFlags
	local currentTime
	local onInteractionScheduledWorkCompleted
	local onInteractionTraced
	local onWorkCanceled
	local onWorkScheduled
	local onWorkStarted
	local onWorkStopped
	local throwInOnInteractionScheduledWorkCompleted
	local throwInOnInteractionTraced
	local throwInOnWorkCanceled
	local throwInOnWorkScheduled
	local throwInOnWorkStarted
	local throwInOnWorkStopped
	local firstSubscriber
	local secondSubscriber
	local firstEvent = { id = 0, name = "first", timestamp = 0 }
	local secondEvent = { id = 1, name = "second", timestamp = 0 }
	local threadID = 123
	local function loadModules(config)
		local enableSchedulerTracing = config.enableSchedulerTracing
		local autoSubscribe = (function()
			if config.autoSubscribe == nil then
				return true
			end
			return config.autoSubscribe
		end)()

		jest.resetModules()
		jest.useFakeTimers()

		currentTime = 0

		ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
		ReactFeatureFlags.enableSchedulerTracing = enableSchedulerTracing

		SchedulerTracing = require(Packages.Scheduler).tracing

		throwInOnInteractionScheduledWorkCompleted = false
		throwInOnInteractionTraced = false
		throwInOnWorkCanceled = false
		throwInOnWorkScheduled = false
		throwInOnWorkStarted = false
		throwInOnWorkStopped = false

		onInteractionScheduledWorkCompleted = jest.fn(function()
			if throwInOnInteractionScheduledWorkCompleted then
				error("Expected error onInteractionScheduledWorkCompleted")
			end
		end)
		onInteractionTraced = jest.fn(function()
			if throwInOnInteractionTraced then
				error("Expected error onInteractionTraced")
			end
		end)
		onWorkCanceled = jest.fn(function()
			if throwInOnWorkCanceled then
				error("Expected error onWorkCanceled")
			end
		end)
		onWorkScheduled = jest.fn(function()
			if throwInOnWorkScheduled then
				error("Expected error onWorkScheduled")
			end
		end)
		onWorkStarted = jest.fn(function()
			if throwInOnWorkStarted then
				error("Expected error onWorkStarted")
			end
		end)
		onWorkStopped = jest.fn(function()
			if throwInOnWorkStopped then
				error("Expected error onWorkStopped")
			end
		end)

		firstSubscriber = {
			onInteractionScheduledWorkCompleted = onInteractionScheduledWorkCompleted,
			onInteractionTraced = onInteractionTraced,
			onWorkCanceled = onWorkCanceled,
			onWorkScheduled = onWorkScheduled,
			onWorkStarted = onWorkStarted,
			onWorkStopped = onWorkStopped,
		}

		secondSubscriber = {
			onInteractionScheduledWorkCompleted = jest.fn(),
			onInteractionTraced = jest.fn(),
			onWorkCanceled = jest.fn(),
			onWorkScheduled = jest.fn(),
			onWorkStarted = jest.fn(),
			onWorkStopped = jest.fn(),
		}
		if autoSubscribe then
			SchedulerTracing.unstable_subscribe(firstSubscriber)
			SchedulerTracing.unstable_subscribe(secondSubscriber)
		end
	end
	describe("enabled", function()
		beforeEach(function()
			return loadModules({ enableSchedulerTracing = true })
		end)
		it(
			"should lazily subscribe to tracing and unsubscribe again if there are no external subscribers",
			function()
				loadModules({ enableSchedulerTracing = true, autoSubscribe = false })
				jestExpect(SchedulerTracing.__subscriberRef.current).toBe(nil)
				SchedulerTracing.unstable_subscribe(firstSubscriber)
				jestExpect(SchedulerTracing.__subscriberRef.current).toBeDefined()
				SchedulerTracing.unstable_subscribe(secondSubscriber)
				jestExpect(SchedulerTracing.__subscriberRef.current).toBeDefined()
				SchedulerTracing.unstable_unsubscribe(secondSubscriber)
				jestExpect(SchedulerTracing.__subscriberRef.current).toBeDefined()
				SchedulerTracing.unstable_unsubscribe(firstSubscriber)
				jestExpect(SchedulerTracing.__subscriberRef.current).toBe(nil)
			end
		)
		describe("error handling", function()
			it("should cover onInteractionTraced/onWorkStarted within", function()
				SchedulerTracing.unstable_trace(firstEvent.name, currentTime, function()
					local mock = jest.fn()

					-- It should call the callback before re-throwing
					throwInOnInteractionTraced = true
					jestExpect(function()
						return SchedulerTracing.unstable_trace(
							secondEvent.name,
							currentTime,
							mock,
							threadID
						)
					end).toThrow("Expected error onInteractionTraced")
					throwInOnInteractionTraced = false
					jestExpect(mock).toHaveBeenCalledTimes(1)
					throwInOnWorkStarted = true
					jestExpect(function()
						return SchedulerTracing.unstable_trace(
							secondEvent.name,
							currentTime,
							mock,
							threadID
						)
					end).toThrow("Expected error onWorkStarted")
					jestExpect(mock).toHaveBeenCalledTimes(2)

					-- It should restore the previous/outer interactions
					jestExpect(SchedulerTracing.unstable_getCurrent()).toMatchInteractions({
						firstEvent,
					})

					-- It should call other subscribers despite the earlier error
					jestExpect(secondSubscriber.onInteractionTraced).toHaveBeenCalledTimes(
						3
					)
					jestExpect(secondSubscriber.onWorkStarted).toHaveBeenCalledTimes(3)
				end)
			end)
			it("should cover onWorkStopped within trace", function()
				SchedulerTracing.unstable_trace(firstEvent.name, currentTime, function()
					local innerInteraction
					local mock = jest.fn(function()
						innerInteraction =
							SchedulerTracing.unstable_getCurrent()._array[2] --[[ ROBLOX adaptation: added 1 to array index ]]
					end)

					throwInOnWorkStopped = true

					jestExpect(function()
						return SchedulerTracing.unstable_trace(
							secondEvent.name,
							currentTime,
							mock
						)
					end).toThrow("Expected error onWorkStopped")
					throwInOnWorkStopped = false

					-- It should restore the previous/outer interactions
					jestExpect(SchedulerTracing.unstable_getCurrent()).toMatchInteractions({
						firstEvent,
					})

					-- It should update the interaction count so as not to interfere with subsequent calls
					jestExpect(innerInteraction.__count).toBe(0)

					-- It should call other subscribers despite the earlier error
					jestExpect(secondSubscriber.onWorkStopped).toHaveBeenCalledTimes(1)
				end)
			end)
			it("should cover onInteractionScheduledWorkCompleted within trace", function()
				SchedulerTracing.unstable_trace(firstEvent.name, currentTime, function()
					local mock = jest.fn()
					throwInOnInteractionScheduledWorkCompleted = true
					jestExpect(function()
						return SchedulerTracing.unstable_trace(
							secondEvent.name,
							currentTime,
							mock
						)
					end).toThrow(
						"Expected error onInteractionScheduledWorkCompleted"
					)
					throwInOnInteractionScheduledWorkCompleted = false
					jestExpect(SchedulerTracing.unstable_getCurrent()).toMatchInteractions({
						firstEvent,
					})
					jestExpect(secondSubscriber.onInteractionScheduledWorkCompleted).toHaveBeenCalledTimes(
						1
					)
				end)
			end)
			it("should cover the callback within trace", function()
				jestExpect(onWorkStarted).never.toHaveBeenCalled()
				jestExpect(onWorkStopped).never.toHaveBeenCalled()
				jestExpect(function()
					SchedulerTracing.unstable_trace(
						firstEvent.name,
						currentTime,
						function()
							error("Expected error callback")
						end
					)
				end).toThrow("Expected error callback")
				jestExpect(onWorkStarted).toHaveBeenCalledTimes(1)
				jestExpect(onWorkStopped).toHaveBeenCalledTimes(1)
			end)
			it("should cover onWorkScheduled within wrap", function()
				SchedulerTracing.unstable_trace(firstEvent.name, currentTime, function()
					-- ROBLOX FIXME: Array.from() polyfill doesn't recognize Set correctly
					local interaction = SchedulerTracing.unstable_getCurrent()._array[1] --[[ ROBLOX adaptation: added 1 to array index ]]
					local beforeCount = interaction.__count
					throwInOnWorkScheduled = true
					jestExpect(function()
						return SchedulerTracing.unstable_wrap(function() end)
					end).toThrow("Expected error onWorkScheduled")
					jestExpect(interaction.__count).toBe(beforeCount)
					jestExpect(secondSubscriber.onWorkScheduled).toHaveBeenCalledTimes(1)
				end)
			end)
			it("should cover onWorkStarted within wrap", function()
				local mock = jest.fn()
				local interaction, wrapped
				SchedulerTracing.unstable_trace(firstEvent.name, currentTime, function()
					-- ROBLOX FIXME: Array.from() polyfill doesn't recognize Set correctly
					interaction = SchedulerTracing.unstable_getCurrent()._array[1] --[[ ROBLOX adaptation: added 1 to array index ]]
					wrapped = SchedulerTracing.unstable_wrap(mock)
				end)
				jestExpect(interaction.__count).toBe(1)
				throwInOnWorkStarted = true
				jestExpect(function()
					wrapped()
				end).toThrow("Expected error onWorkStarted")
				jestExpect(mock).toHaveBeenCalledTimes(1)
				jestExpect(interaction.__count).toBe(0)
				jestExpect(secondSubscriber.onWorkStarted).toHaveBeenCalledTimes(2)
			end)
			it("should cover onWorkStopped within wrap", function()
				SchedulerTracing.unstable_trace(firstEvent.name, currentTime, function()
					-- ROBLOX FIXME: Array.from() polyfill doesn't recognize Set correctly
					local outerInteraction =
						SchedulerTracing.unstable_getCurrent()._array[1] --[[ ROBLOX adaptation: added 1 to array index ]]
					jestExpect(outerInteraction.__count).toBe(1)
					local wrapped
					local innerInteraction
					SchedulerTracing.unstable_trace(
						secondEvent.name,
						currentTime,
						function()
							-- ROBLOX FIXME: Array.from() polyfill doesn't recognize Set correctly
							innerInteraction =
								SchedulerTracing.unstable_getCurrent()._array[2] --[[ ROBLOX adaptation: added 1 to array index ]]
							jestExpect(outerInteraction.__count).toBe(1)
							jestExpect(innerInteraction.__count).toBe(1)
							wrapped = SchedulerTracing.unstable_wrap(jest.fn())
							jestExpect(outerInteraction.__count).toBe(2)
							jestExpect(innerInteraction.__count).toBe(2)
						end
					)
					jestExpect(outerInteraction.__count).toBe(2)
					jestExpect(innerInteraction.__count).toBe(1)
					throwInOnWorkStopped = true
					jestExpect(function()
						wrapped()
					end).toThrow("Expected error onWorkStopped")
					throwInOnWorkStopped = false
					jestExpect(SchedulerTracing.unstable_getCurrent()).toMatchInteractions({
						outerInteraction,
					})
					jestExpect(outerInteraction.__count).toBe(1)
					jestExpect(innerInteraction.__count).toBe(0)
					jestExpect(secondSubscriber.onWorkStopped).toHaveBeenCalledTimes(2)
				end)
			end)

			it("should cover the callback within wrap", function()
				jestExpect(onWorkStarted).never.toHaveBeenCalled()
				jestExpect(onWorkStopped).never.toHaveBeenCalled()

				local wrapped
				local interaction
				SchedulerTracing.unstable_trace(firstEvent.name, currentTime, function()
					-- ROBLOX FIXME: Array.from() polyfill doesn't recognize Set correctly
					interaction = SchedulerTracing.unstable_getCurrent()._array[1] --[[ ROBLOX adaptation: added 1 to array index ]]
					wrapped = SchedulerTracing.unstable_wrap(function()
						error("Expected error wrap")
					end)
				end)

				jestExpect(onWorkStarted).toHaveBeenCalledTimes(1)
				jestExpect(onWorkStopped).toHaveBeenCalledTimes(1)

				jestExpect(function()
					wrapped()
				end).toThrow("Expected error wrap")

				jestExpect(onWorkStarted).toHaveBeenCalledTimes(2)
				jestExpect(onWorkStopped).toHaveBeenCalledTimes(2)
				jestExpect(onWorkStopped).toHaveBeenLastNotifiedOfWork({ interaction })
			end)

			it("should cover onWorkCanceled within wrap", function()
				local interaction, wrapped
				SchedulerTracing.unstable_trace(firstEvent.name, currentTime, function()
					-- ROBLOX FIXME: Array.from() polyfill doesn't recognize Set correctly
					interaction = SchedulerTracing.unstable_getCurrent()._array[1] --[[ ROBLOX adaptation: added 1 to array index ]]
					wrapped = SchedulerTracing.unstable_wrap(jest.fn())
				end)
				jestExpect(interaction.__count).toBe(1)
				throwInOnWorkCanceled = true
				jestExpect(function()
					wrapped.cancel()
				end).toThrow("Expected error onWorkCanceled")
				jestExpect(onWorkCanceled).toHaveBeenCalledTimes(1)
				jestExpect(interaction.__count).toBe(0)
				jestExpect(onInteractionScheduledWorkCompleted).toHaveBeenLastNotifiedOfInteraction(
					firstEvent
				)
				jestExpect(secondSubscriber.onWorkCanceled).toHaveBeenCalledTimes(1)
			end)
		end)
		it("calls lifecycle methods for trace", function()
			jestExpect(onInteractionTraced).never.toHaveBeenCalled()
			jestExpect(onInteractionScheduledWorkCompleted).never.toHaveBeenCalled()
			SchedulerTracing.unstable_trace(firstEvent.name, currentTime, function()
				jestExpect(onInteractionTraced).toHaveBeenCalledTimes(1)
				jestExpect(onInteractionTraced).toHaveBeenLastNotifiedOfInteraction(
					firstEvent
				)
				jestExpect(onInteractionScheduledWorkCompleted).never.toHaveBeenCalled()
				jestExpect(onWorkStarted).toHaveBeenCalledTimes(1)
				jestExpect(onWorkStarted).toHaveBeenLastNotifiedOfWork(
					Set.new({ firstEvent }),
					threadID
				)
				jestExpect(onWorkStopped).never.toHaveBeenCalled()

				SchedulerTracing.unstable_trace(secondEvent.name, currentTime, function()
					jestExpect(onInteractionTraced).toHaveBeenCalledTimes(2)
					jestExpect(onInteractionTraced).toHaveBeenLastNotifiedOfInteraction(
						secondEvent
					)
					jestExpect(onInteractionScheduledWorkCompleted).never.toHaveBeenCalled()
					jestExpect(onWorkStarted).toHaveBeenCalledTimes(2)
					jestExpect(onWorkStarted).toHaveBeenLastNotifiedOfWork(
						Set.new({ firstEvent, secondEvent }),
						threadID
					)
					jestExpect(onWorkStopped).never.toHaveBeenCalled()
				end, threadID)
				jestExpect(onInteractionScheduledWorkCompleted).toHaveBeenCalledTimes(1)
				jestExpect(onInteractionScheduledWorkCompleted).toHaveBeenLastNotifiedOfInteraction(
					secondEvent
				)
				jestExpect(onWorkStopped).toHaveBeenCalledTimes(1)
				jestExpect(onWorkStopped).toHaveBeenLastNotifiedOfWork(
					Set.new({ firstEvent, secondEvent }),
					threadID
				)
			end, threadID)
			jestExpect(onInteractionScheduledWorkCompleted).toHaveBeenCalledTimes(2)
			jestExpect(onInteractionScheduledWorkCompleted).toHaveBeenLastNotifiedOfInteraction(
				firstEvent
			)
			jestExpect(onWorkScheduled).never.toHaveBeenCalled()
			jestExpect(onWorkCanceled).never.toHaveBeenCalled()
			jestExpect(onWorkStarted).toHaveBeenCalledTimes(2)
			jestExpect(onWorkStopped).toHaveBeenCalledTimes(2)
			jestExpect(onWorkStopped).toHaveBeenLastNotifiedOfWork(
				Set.new({ firstEvent }),
				threadID
			)
		end)
		it("calls lifecycle methods for wrap", function()
			local unwrapped = jest.fn()
			local wrapped
			SchedulerTracing.unstable_trace(firstEvent.name, currentTime, function()
				jestExpect(onInteractionTraced).toHaveBeenCalledTimes(1)
				jestExpect(onInteractionTraced).toHaveBeenLastNotifiedOfInteraction(
					firstEvent
				)
				SchedulerTracing.unstable_trace(secondEvent.name, currentTime, function()
					jestExpect(onInteractionTraced).toHaveBeenCalledTimes(2)
					jestExpect(onInteractionTraced).toHaveBeenLastNotifiedOfInteraction(
						secondEvent
					)
					wrapped = SchedulerTracing.unstable_wrap(unwrapped, threadID)
					jestExpect(onWorkScheduled).toHaveBeenCalledTimes(1)
					jestExpect(onWorkScheduled).toHaveBeenLastNotifiedOfWork(
						Set.new({ firstEvent, secondEvent }),
						threadID
					)
				end)
			end)
			jestExpect(onInteractionTraced).toHaveBeenCalledTimes(2)
			jestExpect(onInteractionScheduledWorkCompleted).never.toHaveBeenCalled()
			wrapped()
			jestExpect(unwrapped).toHaveBeenCalled()
			jestExpect(onWorkScheduled).toHaveBeenCalledTimes(1)
			jestExpect(onWorkCanceled).never.toHaveBeenCalled()
			jestExpect(onWorkStarted).toHaveBeenCalledTimes(3)
			jestExpect(onWorkStarted).toHaveBeenLastNotifiedOfWork(
				Set.new({ firstEvent, secondEvent }),
				threadID
			)
			jestExpect(onWorkStopped).toHaveBeenCalledTimes(3)
			jestExpect(onWorkStopped).toHaveBeenLastNotifiedOfWork(
				Set.new({ firstEvent, secondEvent }),
				threadID
			)
			jestExpect(onInteractionScheduledWorkCompleted
				.mock
				.calls
				[1] --[[ ROBLOX adaptation: added 1 to array index ]]
				[1] --[[ ROBLOX adaptation: added 1 to array index ]]).toMatchInteraction(
				firstEvent
			)
			jestExpect(onInteractionScheduledWorkCompleted
				.mock
				.calls
				[2] --[[ ROBLOX adaptation: added 1 to array index ]]
				[1] --[[ ROBLOX adaptation: added 1 to array index ]]).toMatchInteraction(
				secondEvent
			)
		end)
		it(
			"should call the correct interaction subscriber methods when a wrapped callback is canceled",
			function()
				local fnOne = jest.fn()
				local fnTwo = jest.fn()
				local wrappedOne, wrappedTwo
				SchedulerTracing.unstable_trace(firstEvent.name, currentTime, function()
					wrappedOne = SchedulerTracing.unstable_wrap(fnOne, threadID)
					SchedulerTracing.unstable_trace(
						secondEvent.name,
						currentTime,
						function()
							wrappedTwo = SchedulerTracing.unstable_wrap(fnTwo, threadID)
						end
					)
				end)
				jestExpect(onInteractionTraced).toHaveBeenCalledTimes(2)
				jestExpect(onInteractionScheduledWorkCompleted).never.toHaveBeenCalled()
				jestExpect(onWorkCanceled).never.toHaveBeenCalled()
				jestExpect(onWorkStarted).toHaveBeenCalledTimes(2)
				jestExpect(onWorkStopped).toHaveBeenCalledTimes(2)
				wrappedTwo:cancel()
				jestExpect(onInteractionScheduledWorkCompleted).toHaveBeenCalledTimes(1)
				jestExpect(onInteractionScheduledWorkCompleted).toHaveBeenLastNotifiedOfInteraction(
					secondEvent
				)
				jestExpect(onWorkCanceled).toHaveBeenCalledTimes(1)
				jestExpect(onWorkCanceled).toHaveBeenLastNotifiedOfWork(
					Set.new({ firstEvent, secondEvent }),
					threadID
				)
				wrappedOne:cancel()
				jestExpect(onInteractionScheduledWorkCompleted).toHaveBeenCalledTimes(2)
				jestExpect(onInteractionScheduledWorkCompleted).toHaveBeenLastNotifiedOfInteraction(
					firstEvent
				)
				jestExpect(onWorkCanceled).toHaveBeenCalledTimes(2)
				jestExpect(onWorkCanceled).toHaveBeenLastNotifiedOfWork(
					Set.new({ firstEvent }),
					threadID
				)
				jestExpect(fnOne).never.toHaveBeenCalled()
				jestExpect(fnTwo).never.toHaveBeenCalled()
			end
		)
		it(
			"should not end an interaction twice if wrap is used to schedule follow up work within another wrap",
			function()
				local wrappedOne, wrappedTwo
				local fnTwo = jest.fn()
				local fnOne = jest.fn(function()
					wrappedTwo = SchedulerTracing.unstable_wrap(fnTwo, threadID)
				end)
				SchedulerTracing.unstable_trace(firstEvent.name, currentTime, function()
					wrappedOne = SchedulerTracing.unstable_wrap(fnOne, threadID)
				end)
				jestExpect(onInteractionTraced).toHaveBeenCalledTimes(1)
				jestExpect(onInteractionScheduledWorkCompleted).never.toHaveBeenCalled()
				wrappedOne()
				jestExpect(onInteractionTraced).toHaveBeenCalledTimes(1)
				jestExpect(onInteractionScheduledWorkCompleted).never.toHaveBeenCalled()
				wrappedTwo()
				jestExpect(onInteractionTraced).toHaveBeenCalledTimes(1)
				jestExpect(onInteractionScheduledWorkCompleted).toHaveBeenCalledTimes(1)
				jestExpect(onInteractionScheduledWorkCompleted).toHaveBeenLastNotifiedOfInteraction(
					firstEvent
				)
			end
		)
		it(
			"should not decrement the interaction count twice if a wrapped function is run twice",
			function()
				local unwrappedOne = jest.fn()
				local unwrappedTwo = jest.fn()
				local wrappedOne, wrappedTwo
				SchedulerTracing.unstable_trace(firstEvent.name, currentTime, function()
					wrappedOne = SchedulerTracing.unstable_wrap(unwrappedOne, threadID)
					wrappedTwo = SchedulerTracing.unstable_wrap(unwrappedTwo, threadID)
				end)
				jestExpect(onInteractionTraced).toHaveBeenCalledTimes(1)
				jestExpect(onInteractionScheduledWorkCompleted).never.toHaveBeenCalled()
				wrappedOne()
				jestExpect(unwrappedOne).toHaveBeenCalledTimes(1)
				jestExpect(onInteractionTraced).toHaveBeenCalledTimes(1)
				jestExpect(onInteractionScheduledWorkCompleted).never.toHaveBeenCalled()
				wrappedOne()
				jestExpect(unwrappedOne).toHaveBeenCalledTimes(2)
				jestExpect(onInteractionTraced).toHaveBeenCalledTimes(1)
				jestExpect(onInteractionScheduledWorkCompleted).never.toHaveBeenCalled()
				wrappedTwo()
				jestExpect(onInteractionTraced).toHaveBeenCalledTimes(1)
				jestExpect(onInteractionScheduledWorkCompleted).toHaveBeenCalledTimes(1)
				jestExpect(onInteractionScheduledWorkCompleted).toHaveBeenLastNotifiedOfInteraction(
					firstEvent
				)
			end
		)
		it("should unsubscribe", function()
			SchedulerTracing.unstable_unsubscribe(firstSubscriber)
			SchedulerTracing.unstable_trace(firstEvent.name, currentTime, function() end)
			jestExpect(onInteractionTraced).never.toHaveBeenCalled()
		end)
	end)
	describe("disabled", function()
		beforeEach(function()
			return loadModules({ enableSchedulerTracing = false })
		end)

		it("TODO - we need at least one test for JestRoblox not to throw", function() end)

		-- TODO
	end)
end)
