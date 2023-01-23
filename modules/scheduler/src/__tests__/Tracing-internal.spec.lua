-- ROBLOX upstream: https://github.com/facebook/react/blob/9abc2785cb070148d64fae81e523246b90b92016/packages/scheduler/src/__tests__/Tracing-test.internal.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @jest-environment node
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

describe("Tracing", function()
	local SchedulerTracing
	local ReactFeatureFlags

	local advanceTimeBy
	local currentTime

	local function loadModules(config)
		local enableSchedulerTracing = config.enableSchedulerTracing
		jest.resetModules()
		jest.useFakeTimers()

		currentTime = os.time

		advanceTimeBy = jest.advanceTimersByTime

		ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
		ReactFeatureFlags.enableSchedulerTracing = enableSchedulerTracing

		SchedulerTracing = require(Packages.Scheduler).tracing
	end

	describe("enableSchedulerTracing enabled", function()
		beforeEach(function()
			loadModules({ enableSchedulerTracing = true })
		end)

		it("should return the value of a traced function", function()
			jestExpect(
				SchedulerTracing.unstable_trace("arbitrary", currentTime(), function()
					return 123
				end)
			).toBe(123)
		end)

		it("should return the value of a clear function", function()
			jestExpect(SchedulerTracing.unstable_clear(function()
				return 123
			end)).toBe(123)
		end)

		it("should return the value of a wrapped function", function()
			local wrapped
			SchedulerTracing.unstable_trace("arbitrary", currentTime(), function()
				wrapped = SchedulerTracing.unstable_wrap(function()
					return 123
				end)
			end)
			jest.runAllTimers()

			jestExpect(wrapped()).toBe(123)
		end)

		it("should pass arguments through to a wrapped function", function()
			local wrapped
			local done = false
			SchedulerTracing.unstable_trace("arbitrary", currentTime(), function()
				wrapped = SchedulerTracing.unstable_wrap(function(param1, param2)
					jestExpect(param1).toBe("foo")
					jestExpect(param2).toBe("bar")
					done = true
				end)
			end)
			wrapped("foo", "bar")
			jest.runAllTimers()
			jestExpect(done).toBe(true)
		end)

		it("should return an empty set when outside of a traced event", function()
			jestExpect(SchedulerTracing.unstable_getCurrent()).toContainNoInteractions()
		end)

		it(
			"should report the traced interaction from within the trace callback",
			function()
				local done = false
				advanceTimeBy(100)

				SchedulerTracing.unstable_trace("some event", currentTime(), function()
					local interactions = SchedulerTracing.unstable_getCurrent()
					jestExpect(interactions).toMatchInteractions({
						{ name = "some event", timestamp = 100 },
					})

					done = true
				end)

				jestExpect(done).toBe(true)
			end
		)

		it(
			"should report the traced interaction from within wrapped callbacks",
			function()
				local done = false
				local wrappedIndirection

				local function indirection()
					local interactions = SchedulerTracing.unstable_getCurrent()
					jestExpect(interactions).toMatchInteractions({
						{ name = "some event", timestamp = 100 },
					})

					done = true
				end

				advanceTimeBy(100)

				SchedulerTracing.unstable_trace("some event", currentTime(), function()
					wrappedIndirection = SchedulerTracing.unstable_wrap(indirection)
				end)

				advanceTimeBy(50)

				wrappedIndirection()
				jestExpect(done).toBe(true)
			end
		)

		it("should clear the interaction stack for traced callbacks", function()
			local innerTestReached = false

			SchedulerTracing.unstable_trace("outer event", currentTime(), function()
				jestExpect(SchedulerTracing.unstable_getCurrent()).toMatchInteractions({
					{ name = "outer event" },
				})

				SchedulerTracing.unstable_clear(function()
					jestExpect(SchedulerTracing.unstable_getCurrent()).toMatchInteractions({})

					SchedulerTracing.unstable_trace(
						"inner event",
						currentTime(),
						function()
							jestExpect(SchedulerTracing.unstable_getCurrent()).toMatchInteractions({
								{ name = "inner event" },
							})

							innerTestReached = true
						end
					)
				end)

				jestExpect(SchedulerTracing.unstable_getCurrent()).toMatchInteractions({
					{ name = "outer event" },
				})
			end)

			jestExpect(innerTestReached).toBe(true)
		end)

		it("should clear the interaction stack for wrapped callbacks", function()
			local innerTestReached = false
			local wrappedIndirection

			local indirection = jest.fn(function()
				jestExpect(SchedulerTracing.unstable_getCurrent()).toMatchInteractions({
					{ name = "outer event" },
				})

				SchedulerTracing.unstable_clear(function()
					jestExpect(SchedulerTracing.unstable_getCurrent()).toMatchInteractions({})

					SchedulerTracing.unstable_trace(
						"inner event",
						currentTime(),
						function()
							jestExpect(SchedulerTracing.unstable_getCurrent()).toMatchInteractions({
								{ name = "inner event" },
							})

							innerTestReached = true
						end
					)
				end)

				jestExpect(SchedulerTracing.unstable_getCurrent()).toMatchInteractions({
					{ name = "outer event" },
				})
			end)

			SchedulerTracing.unstable_trace("outer event", currentTime(), function()
				wrappedIndirection = SchedulerTracing.unstable_wrap(indirection)
			end)

			wrappedIndirection()

			jestExpect(innerTestReached).toBe(true)
		end)

		it("should support nested traced events", function()
			local done = false
			advanceTimeBy(100)

			local innerIndirectionTraced = false
			local outerIndirectionTraced = false

			local function innerIndirection()
				local interactions = SchedulerTracing.unstable_getCurrent()
				jestExpect(interactions).toMatchInteractions({
					{ name = "outer event", timestamp = 100 },
					{ name = "inner event", timestamp = 150 },
				})

				innerIndirectionTraced = true
			end

			local function outerIndirection()
				local interactions = SchedulerTracing.unstable_getCurrent()
				jestExpect(interactions).toMatchInteractions({
					{ name = "outer event", timestamp = 100 },
				})

				outerIndirectionTraced = true
			end

			SchedulerTracing.unstable_trace("outer event", currentTime(), function()
				-- Verify the current traced event
				local interactions = SchedulerTracing.unstable_getCurrent()
				jestExpect(interactions).toMatchInteractions({
					{ name = "outer event", timestamp = 100 },
				})

				advanceTimeBy(50)

				local wrapperOuterIndirection =
					SchedulerTracing.unstable_wrap(outerIndirection)

				local wrapperInnerIndirection
				local innerEventTraced = false

				-- Verify that a nested event is properly traced
				SchedulerTracing.unstable_trace("inner event", currentTime(), function()
					interactions = SchedulerTracing.unstable_getCurrent()
					jestExpect(interactions).toMatchInteractions({
						{ name = "outer event", timestamp = 100 },
						{ name = "inner event", timestamp = 150 },
					})

					-- Verify that a wrapped outer callback is properly traced
					wrapperOuterIndirection()
					jestExpect(outerIndirectionTraced).toBe(true)

					wrapperInnerIndirection =
						SchedulerTracing.unstable_wrap(innerIndirection)

					innerEventTraced = true
				end)

				jestExpect(innerEventTraced).toBe(true)

				-- Verify that the original event is restored
				interactions = SchedulerTracing.unstable_getCurrent()
				jestExpect(interactions).toMatchInteractions({
					{ name = "outer event", timestamp = 100 },
				})

				-- Verify that a wrapped nested callback is properly traced
				wrapperInnerIndirection()
				jestExpect(innerIndirectionTraced).toBe(true)

				done = true
			end)
			jestExpect(done).toBe(true)
		end)

		describe("error handling", function()
			it(
				"should reset state appropriately when an error occurs in a trace callback",
				function()
					local done = false
					advanceTimeBy(100)

					SchedulerTracing.unstable_trace(
						"outer event",
						currentTime(),
						function()
							jestExpect(function()
								SchedulerTracing.unstable_trace(
									"inner event",
									currentTime(),
									function()
										error("intentional")
									end
								)
							end).toThrow()

							jestExpect(SchedulerTracing.unstable_getCurrent()).toMatchInteractions({
								{ name = "outer event", timestamp = 100 },
							})

							done = true
						end
					)
					jestExpect(done).toBe(true)
				end
			)

			it(
				"should reset state appropriately when an error occurs in a wrapped callback",
				function()
					local done = false
					advanceTimeBy(100)

					SchedulerTracing.unstable_trace(
						"outer event",
						currentTime(),
						function()
							local wrappedCallback

							SchedulerTracing.unstable_trace(
								"inner event",
								currentTime(),
								function()
									wrappedCallback = SchedulerTracing.unstable_wrap(
										function()
											error("intentional")
										end
									)
								end
							)

							-- ROBLOX deviation: unstable_wrap returns a table with a __call metamethod so it can have a cancel field
							jestExpect(function()
								wrappedCallback()
							end).toThrow()

							jestExpect(SchedulerTracing.unstable_getCurrent()).toMatchInteractions({
								{ name = "outer event", timestamp = 100 },
							})

							done = true
						end
					)
					jestExpect(done).toBe(true)
				end
			)
		end)

		describe("advanced integration", function()
			it("should return a unique threadID per request", function()
				jestExpect(SchedulerTracing.unstable_getThreadID()).never.toBe(
					SchedulerTracing.unstable_getThreadID()
				)
			end)

			it(
				"should expose the current set of interactions to be externally manipulated",
				function()
					SchedulerTracing.unstable_trace(
						"outer event",
						currentTime(),
						function()
							jestExpect(SchedulerTracing.__interactionsRef.current).toBe(
								SchedulerTracing.unstable_getCurrent()
							)

							SchedulerTracing.__interactionsRef.current = Set.new({
								{ name = "override event" },
							})

							jestExpect(SchedulerTracing.unstable_getCurrent()).toMatchInteractions({
								{ name = "override event" },
							})
						end
					)
				end
			)

			it("should expose a subscriber ref to be externally manipulated", function()
				SchedulerTracing.unstable_trace("outer event", currentTime(), function()
					jestExpect(SchedulerTracing.__subscriberRef).toEqual({
						current = nil,
					})
				end)
			end)
		end)
	end)

	describe("enableSchedulerTracing disabled", function()
		beforeEach(function()
			loadModules({ enableSchedulerTracing = false })
		end)

		it("should return the value of a traced function", function()
			jestExpect(
				SchedulerTracing.unstable_trace("arbitrary", currentTime(), function()
					return 123
				end)
			).toBe(123)
		end)

		it("should return the value of a wrapped function", function()
			local wrapped
			SchedulerTracing.unstable_trace("arbitrary", currentTime(), function()
				wrapped = SchedulerTracing.unstable_wrap(function()
					return 123
				end)
			end)
			jestExpect(wrapped()).toBe(123)
		end)

		it("should return nil for traced interactions", function()
			jestExpect(SchedulerTracing.unstable_getCurrent()).toBe(nil)
		end)

		it("should execute traced callbacks", function()
			local done = false
			SchedulerTracing.unstable_trace("some event", currentTime(), function()
				jestExpect(SchedulerTracing.unstable_getCurrent()).toBe(nil)

				done = true
			end)
			jestExpect(done).toBe(true)
		end)

		it("should return the value of a clear function", function()
			jestExpect(SchedulerTracing.unstable_clear(function()
				return 123
			end)).toBe(123)
		end)

		it("should execute wrapped callbacks", function()
			local done = false
			local wrappedCallback = SchedulerTracing.unstable_wrap(function()
				jestExpect(SchedulerTracing.unstable_getCurrent()).toBe(nil)

				done = true
			end)

			wrappedCallback()
			jestExpect(done).toBe(true)
		end)

		describe("advanced integration", function()
			it("should not create unnecessary objects", function()
				jestExpect(SchedulerTracing.__interactionsRef).toBe(nil)
			end)
		end)
	end)
end)
