-- ROBLOX upstream: https://github.com/facebook/react/blob/8af27aeedbc6b00bc2ef49729fc84f116c70a27c/packages/react-reconciler/src/__tests__/DebugTracing-test.internal.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @emails react-core
--  * @jest-environment node
--  */

-- local function spyOnDevAndProd(object, methodName, fake)
-- 	local originalMethods = originalObjects[tostring(object)]
-- 	if originalMethods == nil then
-- 		originalMethods = {}
-- 		originalObjects[tostring(object)] = originalMethods
-- 	end
-- 	originalMethods[methodName] = object[methodName]
-- 	object[methodName] = jest:fn(fake)
-- 	return object[methodName]
-- end

-- local function restoreDevAndProd()
-- 	for originalObjectString, originalObject in originalObjects do
-- 		for methodName, originalMethod in originalObjects[originalObjectString] do
-- 			originalObject[methodName] = originalMethod
-- 		end
-- 	end
-- 	originalObjects = nil
-- end

return function()
	local Packages = script.Parent.Parent.Parent
	local RobloxJest = require(Packages.Dev.RobloxJest)
	local JestGlobals = require(Packages.Dev.JestGlobals)
	local jestExpect = JestGlobals.expect
	local console = require(Packages.Shared).console
	local Promise = require(Packages.Promise)

	-- ROBLOX Test Noise: jest capabilities needed to spy on console
	describe("DebugTracing", function()
		local React
		local ReactTestRenderer
		local Scheduler
		beforeEach(function()
			RobloxJest.resetModules()

			-- ROBLOX deviation: upstream uses special comments to know which flags to flip. we do it manually.
			local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
			ReactFeatureFlags.enableDebugTracing = true
			ReactFeatureFlags.enableSchedulingProfiler = true
			ReactFeatureFlags.enableProfilerTimer = true
			ReactFeatureFlags.replayFailedUnitOfWorkWithInvokeGuardedCallback = true
			ReactFeatureFlags.enableSuspenseServerRenderer = true
			ReactFeatureFlags.decoupleUpdatePriorityFromScheduler = true
			React = require(Packages.React)
			ReactTestRenderer = require(Packages.Dev.ReactTestRenderer)
			Scheduler = require(Packages.Scheduler)

			-- local groups = {}

			-- ROBLOX deviation: we currently don't have a good way to intercept
			-- console.log, group, or groupEnd in a reasonably-aligned way

			-- spyOnDevAndProd(console, "log", function(message)
			-- 	table.insert(logs, "log: " .. message)
			-- end)
			-- spyOnDevAndProd(console, "group", function(message)
			-- 	table.insert(logs, "group: " .. message)
			-- 	table.insert(groups, message)
			-- end)
			-- spyOnDevAndProd(console, "groupEnd", function()
			-- 	local message = table.remove(groups, 1)
			-- 	table.insert(logs, "groupEnd: " .. message)
			-- end)
		end)

		-- @gate experimental
		it(
			"should not log anything for sync render without suspends or state updates",
			function()
				jestExpect(function()
					ReactTestRenderer.create(
						React.createElement(
							React.unstable_DebugTracingMode,
							nil,
							React.createElement("div")
						)
					)
				end).toLogDev({})
			end
		)

		-- @gate experimental
		it(
			"should not log anything for concurrent render without suspends or state updates",
			function()
				jestExpect(function()
					ReactTestRenderer.create(
						React.createElement(
							React.unstable_DebugTracingMode,
							nil,
							React.createElement("div")
						),
						{ unstable_isConcurrent = true }
					)
				end).toLogDev({})

				jestExpect(function()
					jestExpect(Scheduler).toFlushUntilNextPaint({})
				end).toLogDev({})
			end
		)

		-- ROBLOX FIXME: we never receive "Example resolved", might be a Promise emulation issue
		-- @gate experimental && build === 'development' && enableDebugTracing
		xit("should log sync render with suspense", function()
			-- ROBLOX deviation: evaera Prosmise.resolve doesn't match JS Promise, so we delay(0) to match
			local fakeSuspensePromise = Promise.delay(0):andThen(function()
				return true
			end)
			local function Example()
				error(fakeSuspensePromise)
			end

			jestExpect(function()
				ReactTestRenderer.create(
					React.createElement(
						React.unstable_DebugTracingMode,
						nil,
						React.createElement(
							React.Suspense,
							{ fallback = {} },
							React.createElement(Example)
						)
					)
				)
			end).toLogDev({
					-- "* render (0b0000000000000000000000000000001)",
					"* Example suspended",
					-- "* render (0b0000000000000000000000000000001)"
				},
				{ withoutStack = true }
			)

			jestExpect(function()
				fakeSuspensePromise:await()
			end).toLogDev({
					"* Example resolved",
				},
				{ withoutStack = true}
			)
		end)

		-- @gate experimental && build === 'development' && enableDebugTracing
		itSKIP("should log sync render with CPU suspense", function()
			local function Example()
				console.log("<Example/>")
				return nil
			end

			local function Wrapper(props)
				local children = props.children
				console.log("<Wrapper/>")
				return children
			end

			jestExpect(function()
				ReactTestRenderer.create(
					React.createElement(
						React.unstable_DebugTracingMode,
						nil,
						React.createElement(
							Wrapper,
							nil,
							React.createElement(
								React.Suspense,
								{ fallback = {}, unstable_expectedLoadTime = 1 },
								React.createElement(Example)
							)
						)
					)
				)
			end).toLogDev({
			-- 	"group: * render (0b0000000000000000000000000000001)",
				"<Wrapper/>",
			-- 	"groupEnd: * render (0b0000000000000000000000000000001)",
			}, { withoutStack = true })

			jestExpect(function()
				jestExpect(Scheduler).toFlushUntilNextPaint({})
			end).toLogDev({
			-- 	"group: * render (0b0000010000000000000000000000000)",
				"<Example/>",
			-- 	"groupEnd: * render (0b0000010000000000000000000000000)",
			}, { withoutStack = true })
		end)

		-- @gate experimental && build === 'development' && enableDebugTracing
		xit("should log concurrent render with suspense", function()
			-- ROBLOX deviation: evaera Prosmise.resolve doesn't match JS Promise, so we delay(0) to match
			local fakeSuspensePromise = Promise.delay(0):andThen(function()
				return true
			end)
			local function Example()
				error(fakeSuspensePromise)
			end

			jestExpect(function()
				ReactTestRenderer.create(
					React.createElement(
						React.unstable_DebugTracingMode,
						nil,
						React.createElement(
							React.Suspense,
							{ fallback = {} },
							React.createElement(Example)
						)
					),
					{ unstable_isConcurrent = true }
				)
			end).toLogDev({})

			jestExpect(function()
				jestExpect(Scheduler).toFlushUntilNextPaint({})
			end).toLogDev({
			-- 	"group: * render (0b0000000000000000000001000000000)",
				"* Example suspended",
			-- 	"groupEnd: * render (0b0000000000000000000001000000000)",
			}, { withoutStack = true })

			jestExpect(function()
				fakeSuspensePromise:await()
			end).toLogDev(
				{ "* Example resolved" },
				{withoutStack = true}
			)
		end)

		-- @gate experimental && build === 'development' && enableDebugTracing
		xit("should log concurrent render with CPU suspense", function()
			local function Example()
				console.log("<Example/>")
				return nil
			end

			local function Wrapper(props)
				local children = props.children
				console.log("<Wrapper/>")
				return children
			end

			jestExpect(function()
				ReactTestRenderer.create(
					React.createElement(
						React.unstable_DebugTracingMode,
						nil,
						React.createElement(
							Wrapper,
							nil,
							React.createElement(
								React.Suspense,
								{ fallback = {}, unstable_expectedLoadTime = 1 },
								React.createElement(Example)
							)
						)
					),
					{ unstable_isConcurrent = true }
				)
			end).toLogDev({})

			jestExpect(function()
				jestExpect(Scheduler).toFlushUntilNextPaint({})
			end).toLogDev({
				-- 	"group: * render (0b0000000000000000000001000000000)",
					"<Wrapper/>",
				-- 	"groupEnd: * render (0b0000000000000000000001000000000)",
				},
				{withoutStack = true}
			)

			jestExpect(function()
				jestExpect(Scheduler).toFlushUntilNextPaint({})
			end).toLogDev({
				-- 	"group: * render (0b0000010000000000000000000000000)",
					"<Example/>",
				-- 	"groupEnd: * render (0b0000010000000000000000000000000)",
				},
				{ withoutStack = true}
			)
		end)

		-- @gate experimental && build === 'development' && enableDebugTracing
		it("should log cascading class component updates", function()
			local Example = React.Component:extend("Example")
			function Example:init()
				self.state = { didMount = false }
			end
			function Example:componentDidMount()
				self:setState({ didMount = true })
			end
			function Example:render()
				return nil
			end

			jestExpect(function()
				ReactTestRenderer.create(
					React.createElement(
						React.unstable_DebugTracingMode,
						nil,
						React.createElement(Example)
					),
					{ unstable_isConcurrent = true }
				)
			end).toLogDev({})

			jestExpect(function()
				jestExpect(Scheduler).toFlushUntilNextPaint({})
			end).toLogDev({
			-- 	"group: * commit (0b0000000000000000000001000000000)",
			-- 	"group: * layout effects (0b0000000000000000000001000000000)",
					"* Example updated state (0b0000000000000000000000000000001)",
			-- 	"groupEnd: * layout effects (0b0000000000000000000001000000000)",
			-- 	"groupEnd: * commit (0b0000000000000000000001000000000)",
				},
				{ withoutStack = true }
			)
		end)

		-- @gate experimental && build === 'development' && enableDebugTracing
		it("should log render phase state updates for class component", function()
			local Example = React.Component:extend("Example")
			function Example:init()
				self.state = { didRender = false }
			end
			function Example:render()
				if self.state.didRender == false then
					self:setState({ didRender = true })
				end
				return nil
			end

			jestExpect(function()
				ReactTestRenderer.create(
					React.createElement(
						React.unstable_DebugTracingMode,
						nil,
						React.createElement(Example)
					),
					{ unstable_isConcurrent = true }
				)
			end).toLogDev({})

			jestExpect(function()
				jestExpect(function()
					jestExpect(Scheduler).toFlushUntilNextPaint({})
				end).toErrorDev("Cannot update during an existing state transition")
			end).toLogDev({
			-- 	"group: * render (0b0000000000000000000001000000000)",
					"* Example updated state (0b0000000000000000000001000000000)",
					"* Example updated state (0b0000000000000000000001000000000)"
				},
				{ withoutStack = true }
			)
		end)

		-- @gate experimental && build === 'development' && enableDebugTracing
		it("should log cascading layout updates", function()
			local function Example()
				local didMount, setDidMount = React.useState(false)
				React.useLayoutEffect(function()
					setDidMount(true)
				end, {})
				return didMount
			end

			jestExpect(function()
				ReactTestRenderer.create(
					React.createElement(
						React.unstable_DebugTracingMode,
						nil,
						React.createElement(Example)
					),
					{ unstable_isConcurrent = true }
				)
			end).toLogDev({})

			jestExpect(function()
				jestExpect(Scheduler).toFlushUntilNextPaint({})
			end).toLogDev({
			-- 	"group: * commit (0b0000000000000000000001000000000)",
			-- 	"group: * layout effects (0b0000000000000000000001000000000)",
					"* Example updated state (0b0000000000000000000000000000001)",
			-- 	"groupEnd: * layout effects (0b0000000000000000000001000000000)",
			-- 	"groupEnd: * commit (0b0000000000000000000001000000000)",
				},
				{ withoutStack = true }
			)
		end)

		-- @gate experimental && build === 'development' && enableDebugTracing
		it("should log cascading passive updates", function()
			local function Example()
				local didMount, setDidMount = React.useState(false)
				React.useEffect(function()
					setDidMount(true)
				end, {})
				return didMount
			end


			jestExpect(function()
				ReactTestRenderer.act(function()
					ReactTestRenderer.create(
						React.createElement(
							React.unstable_DebugTracingMode,
							nil,
							React.createElement(Example)
						),
						{ unstable_isConcurrent = true }
					)
				end)
			end).toLogDev({
			-- 	"group: * passive effects (0b0000000000000000000001000000000)",
				"* Example updated state (0b0000000000000000000010000000000)",
			-- 	"groupEnd: * passive effects (0b0000000000000000000001000000000)",
				},
				{ withoutStack = true }
			)
		end)

		-- @gate experimental && build === 'development' && enableDebugTracing
		it("should log render phase updates", function()
			local function Example()
				local didRender, setDidRender = React.useState(false)
				if not didRender then
					setDidRender(true)
				end
				return didRender
			end

			jestExpect(function()
				ReactTestRenderer.act(function()
					ReactTestRenderer.create(
						React.createElement(
							React.unstable_DebugTracingMode,
							nil,
							React.createElement(Example)
						),
						{ unstable_isConcurrent = true }
					)
				end)
			end).toLogDev({
			-- 	"group: * render (0b0000000000000000000001000000000)",
				"* Example updated state (0b0000000000000000000001000000000)",
				"* Example updated state (0b0000000000000000000001000000000)",
			-- 	"groupEnd: * render (0b0000000000000000000001000000000)",
				},
				{ withoutStack = true }
			)

			-- ROBLOX deviation: we don't have build-time gating like upstream
			-- gate(function(flags)
			-- 	if flags.new then
			-- jestExpect(logs).toEqual({
			-- })
			-- 	else
			-- 		jestExpect(logs).toEqual({
			-- 			"group: * render (0b0000000000000000000001000000000)",
			-- 			"log: * Example updated state (0b0000000000000000000010000000000)",
			-- 			"log: * Example updated state (0b0000000000000000000010000000000)",
			-- 			"groupEnd: * render (0b0000000000000000000001000000000)",
			-- 		})
			-- 	end
			-- end)
		end)

		-- @gate experimental && build === 'development' && enableDebugTracing
		xit("should log when user code logs", function()
			local function Example()
				console.log("Hello from user code")
				return nil
			end

			jestExpect(function()
				ReactTestRenderer.create(
					React.createElement(
						React.unstable_DebugTracingMode,
						nil,
						React.createElement(Example)
					),
					{ unstable_isConcurrent = true }
				)
			end).toLogDev({})

			jestExpect(function()
				jestExpect(Scheduler).toFlushUntilNextPaint({})
			end).toLogDev({
			-- 	"group: * render (0b0000000000000000000001000000000)",
					"Hello from user code",
			-- 	"groupEnd: * render (0b0000000000000000000001000000000)",
			})
		end)

		-- @gate experimental
		it(
			"should not log anything outside of a unstable_DebugTracingMode subtree",
			function()
				local function ExampleThatCascades()
					local didMount, setDidMount = React.useState(false)
					React.useLayoutEffect(function()
						setDidMount(true)
					end, {})
					return didMount
				end

				local fakeSuspensePromise = Promise.new(function()
					return {}
				end)
				local function ExampleThatSuspends()
					error(fakeSuspensePromise)
				end

				local function Example()
					return nil
				end

				jestExpect(function()
					ReactTestRenderer.create(
						React.createElement(
							React.Fragment,
							nil,
							React.createElement(ExampleThatCascades),
							React.createElement(
								React.Suspense,
								{ fallback = {} },
								nil,
								React.createElement(ExampleThatSuspends)
							),
							React.createElement(
								React.unstable_DebugTracingMode,
								nil,
								React.createElement(Example)
							)
						)
					)
				end).toLogDev({})
			end
		)
	end)
end
