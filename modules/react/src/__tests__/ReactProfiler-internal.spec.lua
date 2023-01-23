-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react/src/__tests__/ReactProfiler-test.internal.js
local React
local ReactFeatureFlags
local ReactNoop
local Scheduler
local ReactCache
local ReactTestRenderer
local ReactTestRendererAct
local _SchedulerTracing
local AdvanceTime
local _AsyncText
local _ComponentWithPassiveEffect
local _Text
local TextResource
local resourcePromise
local setTimeout
local Set

local Packages = script.Parent.Parent.Parent

local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local jest = JestGlobals.jest
local describe = JestGlobals.describe
local beforeEach = JestGlobals.beforeEach
local it = JestGlobals.it

local Promise = require(Packages.Dev.Promise)

local function loadModules(config)
	local enableProfilerTimer = (function()
		if config.enableProfilerTimer ~= nil then
			return config.enableProfilerTimer
		end
		return true
	end)()
	local enableProfilerCommitHooks = (function()
		if config.enableProfilerCommitHooks ~= nil then
			return config.enableProfilerCommitHooks
		end
		return true
	end)()
	local enableSchedulerTracing = (function()
		if config.enableSchedulerTracing ~= nil then
			return config.enableSchedulerTracing
		end
		return true
	end)()
	local replayFailedUnitOfWorkWithInvokeGuardedCallback = (function()
		if config.replayFailedUnitOfWorkWithInvokeGuardedCallback ~= nil then
			return config.replayFailedUnitOfWorkWithInvokeGuardedCallback
		end
		return false
	end)()
	local useNoopRenderer = (function()
		if config.useNoopRenderer ~= nil then
			return config.useNoopRenderer
		end
		return false
	end)()
	ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags

	ReactFeatureFlags.enableProfilerTimer = enableProfilerTimer
	ReactFeatureFlags.enableProfilerCommitHooks = enableProfilerCommitHooks
	ReactFeatureFlags.enableSchedulerTracing = enableSchedulerTracing
	ReactFeatureFlags.replayFailedUnitOfWorkWithInvokeGuardedCallback =
		replayFailedUnitOfWorkWithInvokeGuardedCallback

	local LuauPolyfill = require(Packages.LuauPolyfill)
	setTimeout = LuauPolyfill.setTimeout
	Set = LuauPolyfill.Set

	React = require(script.Parent.Parent)
	Scheduler = require(Packages.Dev.Scheduler)
	_SchedulerTracing = Scheduler.tracing
	ReactCache = require(Packages.Dev.ReactCache)

	if useNoopRenderer then
		ReactNoop = require(Packages.Dev.ReactNoopRenderer)
		ReactTestRenderer = nil
		ReactTestRendererAct = nil
	else
		ReactNoop = nil
		ReactTestRenderer = require(Packages.Dev.ReactTestRenderer)
		ReactTestRendererAct = ReactTestRenderer.unstable_concurrentAct
	end

	AdvanceTime = React.Component:extend("AdvanceTime")
	AdvanceTime.defaultProps = {
		byAmount = 10,
		shouldComponentUpdate = true,
	}
	function AdvanceTime:shouldComponentUpdate(nextProps)
		return nextProps.shouldComponentUpdate
	end
	function AdvanceTime:render()
		-- Simulate time passing when self component is rendered
		Scheduler.unstable_advanceTime(self.props.byAmount)
		return self.props.children or nil
	end

	resourcePromise = nil

	TextResource = ReactCache.unstable_createResource(function(args)
		local text, ms = args[1], args[2] or 0
		resourcePromise = Promise.new(function(resolve, reject)
			setTimeout(function()
				Scheduler.unstable_yieldValue(
					string.format("Promise resolved [%s]", tostring(text))
				)
				resolve(text)
			end, ms)
		end)
		return resourcePromise
	end, function(args)
		local text = args[1]
		return text
	end)

	_AsyncText = function(props)
		local ms, text = props.ms, props.text
		local ok, result = pcall(function()
			TextResource.read({ text, ms })
			Scheduler.unstable_yieldValue(string.format("AsyncText [%s]", text))
			return text
		end)
		if not ok then
			local promise = result
			if typeof(promise.andThen) == "function" then
				Scheduler.unstable_yieldValue(string.format("Suspend [%s]", text))
			else
				Scheduler.unstable_yieldValue(string.format("Error [%s]", text))
			end
			error(promise)
		end
	end

	_Text = function(props)
		local text = props.text
		Scheduler.unstable_yieldValue(string.format("Text [%s]", text))
		return text
	end

	_ComponentWithPassiveEffect = function()
		-- Intentionally schedule a passive effect so the onPostCommit hook will be called.
		React.useEffect(function() end)
		return nil
	end
end

-- ROBLOX Test Noise: in upstream, jest setup config makes these tests hide
-- the error boundary warnings they trigger (scripts/jest/setupTests.js:72)
describe("Profiler", function()
	-- ROBLOX deviation: use faketimers instead
	-- local advanceTimeBy
	-- local currentTime

	describe("works in profiling and non-profiling bundles", function()
		for _, enableSchedulerTracing in { true, false } do
			for _, enableProfilerTimer in { true, false } do
				describe("enableSchedulerTracing:" .. (function()
					if enableSchedulerTracing then
						return "enabled"
					end
					return "disabled"
				end)() .. " enableProfilerTimer:" .. (function()
					if enableProfilerTimer then
						return "enabled"
					end
					return "disabled"
				end)() .. "}", function()
					-- ROBLOX deviation START: add condition, otherwise the suite will fail because of no tests
					if _G.__DEV__ and enableProfilerTimer then
						-- ROBLOX deviation END
						beforeEach(function()
							jest.resetModules()

							loadModules({
								enableSchedulerTracing = enableSchedulerTracing,
								enableProfilerTimer = enableProfilerTimer,
								-- ROBLOX TODO: set this explicitly to false until we have the correct HostConfig for the TestRenderer setup
								replayFailedUnitOfWorkWithInvokeGuardedCallback = false,
							})
						end)
						-- ROBLOX deviation START: add condition, otherwise the suite will fail because of no tests
					end
					-- ROBLOX deviation END

					-- This will throw in production too,
					-- But the test is only interested in verifying the DEV error message.
					if _G.__DEV__ and enableProfilerTimer then
						it("should warn if required params are missing", function()
							jestExpect(function()
								ReactTestRenderer.create(
									React.createElement(React.Profiler)
								)
							end).toErrorDev(
								'Profiler must specify an "id" as a prop',
								{
									withoutStack = true,
								}
							)
						end)

						it(
							"should support an empty Profiler (with no children)",
							function()
								jestExpect(function()
									ReactTestRenderer.create(
										React.createElement(React.Profiler, {
											id = "label",
											onRender = jest.fn(),
										})
									)
										:toJSON()
									-- ROBLOX TODO: toJSON needs to work, use toMatchSnapshot
								end).never.toThrow()
							end
						)

						it("should render children", function()
							local FunctionComponent = function(props)
								local label = props.label
								return React.createElement("span", nil, label)
							end
							local renderer = ReactTestRenderer.create(
								React.createElement(
									"div",
									nil,
									React.createElement("span", nil, "outside span"),
									React.createElement(
										React.Profiler,
										{ id = "label", onRender = jest.fn() },
										React.createElement("span", nil, "inside span"),
										React.createElement(FunctionComponent, {
											label = "function component",
										})
									)
								)
							)
							jestExpect(function()
								renderer:toJSON()
							end).never.toThrow()
							-- ROBLOX TODO: toJSON needs to work, use toMatchSnapshot
							--toMatchSnapshot()
						end)

						it("should support nested Profilers", function()
							local FunctionComponent = function(props)
								local label = props.label
								return React.createElement("div", nil, label)
							end
							local ClassComponent =
								React.Component:extend("ClassComponent")
							function ClassComponent:render()
								return React.createElement("block", nil, self.props.label)
							end
							local renderer = ReactTestRenderer.create(
								React.createElement(
									React.Profiler,
									{ id = "outer", onRender = jest.fn() },
									React.createElement(FunctionComponent, {
										label = "outer function component",
									}),
									React.createElement(
										React.Profiler,
										{ id = "inner", onRender = jest.fn() },
										React.createElement(ClassComponent, {
											label = "inner class component",
										}),
										React.createElement("span", nil, "inner span")
									)
								)
							)

							jestExpect(function()
								renderer:toJSON()
							end).never.toThrow()
							-- ROBLOX TODO: implement toJSON, use toMatchSnapshot when its available
							-- .toMatchSnapshot()
						end)
					end
				end)
			end
		end
	end)

	for _, enableSchedulerTracing in { true, false } do
		describe("onRender enableSchedulerTracing:" .. (function()
			if enableSchedulerTracing then
				return "enabled"
			end
			return "disabled"
		end)(), function()
			beforeEach(function()
				jest.resetModules()

				loadModules({
					enableSchedulerTracing = enableSchedulerTracing,
					-- ROBLOX TODO: set this explicitly to false until we have the correct HostConfig for the TestRenderer setup
					replayFailedUnitOfWorkWithInvokeGuardedCallback = false,
				})
			end)

			it("should handle errors thrown", function()
				local callback = jest.fn(function(id)
					if id == "throw" then
						error("expected")
					end
				end)

				local didMount = false
				local ClassComponent = React.Component:extend("ClassComponent")
				function ClassComponent:componentDidMount()
					didMount = true
				end
				function ClassComponent:render()
					return self.props.children
				end

				-- Errors thrown from onRender should not break the commit phase,
				-- Or prevent other lifecycles from being called.
				jestExpect(function()
					ReactTestRenderer.create(
						React.createElement(
							ClassComponent,
							nil,
							React.createElement(
								React.Profiler,
								{ id = "do-not-throw", onRender = callback },
								React.createElement(React.Profiler, {
									id = "throw",
									onRender = callback,
								}, React.createElement("div"))
							)
						)
					)
				end).toThrow("expected")
				jestExpect(didMount).toBe(true)
				jestExpect(callback).toHaveBeenCalledTimes(2)
			end)

			it("is not invoked until the commit phase", function()
				local callback = jest.fn()

				local Yield = function(props)
					local value = props.value
					Scheduler.unstable_yieldValue(value)
					return nil
				end

				ReactTestRenderer.create(
					React.createElement(
						React.Profiler,
						{ id = "test", onRender = callback },
						React.createElement(Yield, { value = "first" }),
						React.createElement(Yield, { value = "last" })
					),
					{
						unstable_isConcurrent = true,
					}
				)

				-- Times are logged until a render is committed.
				jestExpect(Scheduler).toFlushAndYieldThrough({ "first" })
				jestExpect(callback).toHaveBeenCalledTimes(0)
				jestExpect(Scheduler).toFlushAndYield({ "last" })
				jestExpect(callback).toHaveBeenCalledTimes(1)
			end)

			-- skipped translating some tests

			it("does not report work done on a sibling", function()
				local callback = jest.fn()

				local DoesNotUpdate = React.memo(function()
					Scheduler.unstable_advanceTime(10)
					return nil
				end, function()
					return true
				end)

				local updateProfilerSibling

				local function ProfilerSibling()
					local count, setCount = React.useState(0)
					updateProfilerSibling = function()
						setCount(count + 1)
					end
					return nil
				end

				local function App()
					return React.createElement(
						React.Fragment,
						nil,
						React.createElement(React.Profiler, {
							id = "test",
							onRender = callback,
						}, React.createElement(DoesNotUpdate)),
						React.createElement(ProfilerSibling)
					)
				end

				local renderer = ReactTestRenderer.create(React.createElement(App))

				jestExpect(callback).toHaveBeenCalledTimes(1)

				local call = callback.mock.calls[1]

				jestExpect(call).toHaveLength((function()
					if enableSchedulerTracing then
						return 7
					else
						return 6
					end
				end)())
				jestExpect(call[1]).toBe("test")
				jestExpect(call[2]).toBe("mount")
				jestExpect(call[3]).toBe(10) -- actual time
				jestExpect(call[4]).toBe(10) -- base time
				jestExpect(call[5]).toBe(0) -- start time
				jestExpect(call[6]).toBe(10) -- commit time
				jestExpect(call[7]).toEqual((function()
					if enableSchedulerTracing then
						return Set.new()
					else
						return nil
					end
				end)()) -- intersection events

				callback:mockReset()

				Scheduler.unstable_advanceTime(20) -- 10 -> 30

				renderer.update(React.createElement(App))

				-- ROBLOX deviation: we don't support dynamic/gated flags, so hard-code the path
				-- 						if (gate(flags => flags.new)) {
				-- None of the Profiler's subtree was rendered because App bailed out before the Profiler.
				-- So we expect onRender not to be called.
				jestExpect(callback).never.toHaveBeenCalled()
				-- 						} else {
				-- Updating a parent reports a re-render,
				-- since React technically did a little bit of work between the Profiler and the bailed out subtree.
				-- This is not optimal but it's how the old reconciler fork works.
				--   jestExpect(callback).toHaveBeenCalledTimes(1)

				--   call = callback.mock.calls[1]

				--   jestExpect(call).toHaveLength((function()
				-- 	if enableSchedulerTracing then
				-- 		return 7
				-- 	else
				-- 		return 6
				-- 	end
				-- 	end)())
				--   jestExpect(call[1]).toBe('test')
				--   jestExpect(call[2]).toBe('update')
				--   jestExpect(call[3]).toBe(0) -- actual time
				--   jestExpect(call[4]).toBe(10) -- base time
				--   jestExpect(call[5]).toBe(30) -- start time
				--   jestExpect(call[6]).toBe(30) -- commit time
				--   jestExpect(call[7]).toEqual((function()
				-- 	if enableSchedulerTracing then
				-- 		return {}
				-- 	else
				-- 		return nil
				-- 	end
				-- end)()) -- intersection events

				--   callback.mockReset()
				-- }

				Scheduler.unstable_advanceTime(20) -- 30 -> 50

				-- Updating a sibling should not report a re-render.
				ReactTestRendererAct(updateProfilerSibling)

				jestExpect(callback).never.toHaveBeenCalled()
			end)

			it("logs render times for both mount and update", function()
				local callback = jest.fn()

				Scheduler.unstable_advanceTime(5) -- 0 -> 5

				local renderer = ReactTestRenderer.create(
					React.createElement(
						React.Profiler,
						{ id = "test", onRender = callback },
						React.createElement(AdvanceTime)
					)
				)

				jestExpect(callback).toHaveBeenCalledTimes(1)

				local call = callback.mock.calls[1]

				jestExpect(call).toHaveLength((function()
					if enableSchedulerTracing then
						return 7
					else
						return 6
					end
				end)())
				jestExpect(call[1]).toBe("test")
				jestExpect(call[2]).toBe("mount")
				jestExpect(call[3]).toBe(10) -- actual time
				jestExpect(call[4]).toBe(10) -- base time
				jestExpect(call[5]).toBe(5) -- start time
				jestExpect(call[6]).toBe(15) -- commit time
				jestExpect(call[7]).toEqual((function()
					if enableSchedulerTracing then
						return Set.new()
					else
						return nil
					end
				end)()) -- intersection events

				callback.mockReset()

				Scheduler.unstable_advanceTime(20) -- 15 -> 35

				renderer.update(React.createElement(React.Profiler, {
					id = "test",
					onRender = callback,
				}, React.createElement(AdvanceTime)))

				jestExpect(callback).toHaveBeenCalledTimes(1)

				call = callback.mock.calls[1]

				jestExpect(call).toHaveLength((function()
					if enableSchedulerTracing then
						return 7
					else
						return 6
					end
				end)())
				jestExpect(call[1]).toBe("test")
				jestExpect(call[2]).toBe("update")
				jestExpect(call[3]).toBe(10) -- actual time
				jestExpect(call[4]).toBe(10) -- base time
				jestExpect(call[5]).toBe(35) -- start time
				jestExpect(call[6]).toBe(45) -- commit time
				jestExpect(call[7]).toEqual((function()
					if enableSchedulerTracing then
						return Set.new()
					else
						return nil
					end
				end)()) -- intersection events

				callback.mockReset()

				Scheduler.unstable_advanceTime(20) -- 45 -> 65

				renderer.update(React.createElement(React.Profiler, {
					id = "test",
					onRender = callback,
				}, React.createElement(AdvanceTime, { byAmount = 4 })))

				jestExpect(callback).toHaveBeenCalledTimes(1)

				call = callback.mock.calls[1]

				jestExpect(call).toHaveLength((function()
					if enableSchedulerTracing then
						return 7
					else
						return 6
					end
				end)())
				jestExpect(call[1]).toBe("test")
				jestExpect(call[2]).toBe("update")
				jestExpect(call[3]).toBe(4) -- actual time
				jestExpect(call[4]).toBe(4) -- base time
				jestExpect(call[5]).toBe(65) -- start time
				jestExpect(call[6]).toBe(69) -- commit time
				jestExpect(call[7]).toEqual((function()
					if enableSchedulerTracing then
						return Set.new()
					else
						return nil
					end
				end)()) -- intersection events
			end)

			it(
				"includes render times of nested Profilers in their parent times",
				function()
					local callback = jest.fn()

					Scheduler.unstable_advanceTime(5) -- 0 -> 5

					ReactTestRenderer.create(
						React.createElement(
							React.Fragment,
							nil,
							React.createElement(
								React.Profiler,
								{ id = "parent", onRender = callback },
								React.createElement(
									AdvanceTime,
									{ byAmount = 10 },
									React.createElement(
										React.Profiler,
										{ id = "child", onRender = callback },
										React.createElement(
											AdvanceTime,
											{ byAmount = 20 }
										)
									)
								)
							)
						)
					)

					jestExpect(callback).toHaveBeenCalledTimes(2)

					-- Callbacks bubble (reverse order).
					local childCall, parentCall =
						callback.mock.calls[1], callback.mock.calls[2]
					jestExpect(childCall[1]).toBe("child")
					jestExpect(parentCall[1]).toBe("parent")

					-- Parent times should include child times
					jestExpect(childCall[3]).toBe(20) -- actual time
					jestExpect(childCall[4]).toBe(20) -- base time
					jestExpect(childCall[5]).toBe(15) -- start time
					jestExpect(childCall[6]).toBe(35) -- commit time
					jestExpect(parentCall[3]).toBe(30) -- actual time
					jestExpect(parentCall[4]).toBe(30) -- base time
					jestExpect(parentCall[5]).toBe(5) -- start time
					jestExpect(parentCall[6]).toBe(35) -- commit time
				end
			)

			it("traces sibling Profilers separately", function()
				local callback = jest.fn()

				Scheduler.unstable_advanceTime(5) -- 0 -> 5

				ReactTestRenderer.create(
					React.createElement(
						React.Fragment,
						nil,
						React.createElement(React.Profiler, {
							id = "first",
							onRender = callback,
						}, React.createElement(AdvanceTime, { byAmount = 20 })),
						React.createElement(React.Profiler, {
							id = "second",
							onRender = callback,
						}, React.createElement(AdvanceTime, { byAmount = 5 }))
					)
				)

				jestExpect(callback).toHaveBeenCalledTimes(2)

				-- Callbacks bubble (reverse order).
				local firstCall, secondCall =
					callback.mock.calls[1], callback.mock.calls[2]
				jestExpect(firstCall[1]).toBe("first")
				jestExpect(secondCall[1]).toBe("second")

				-- Parent times should include child times
				jestExpect(firstCall[3]).toBe(20) -- actual time
				jestExpect(firstCall[4]).toBe(20) -- base time
				jestExpect(firstCall[5]).toBe(5) -- start time
				jestExpect(firstCall[6]).toBe(30) -- commit time
				jestExpect(secondCall[3]).toBe(5) -- actual time
				jestExpect(secondCall[4]).toBe(5) -- base time
				jestExpect(secondCall[5]).toBe(25) -- start time
				jestExpect(secondCall[6]).toBe(30) -- commit time
			end)

			it("does not include time spent outside of profile root", function()
				local callback = jest.fn()

				Scheduler.unstable_advanceTime(5) -- 0 -> 5

				ReactTestRenderer.create(
					React.createElement(
						React.Fragment,
						nil,
						React.createElement(AdvanceTime, { byAmount = 20 }),
						React.createElement(React.Profiler, {
							id = "test",
							onRender = callback,
						}, React.createElement(AdvanceTime, { byAmount = 5 })),
						React.createElement(AdvanceTime, { byAmount = 20 })
					)
				)

				jestExpect(callback).toHaveBeenCalledTimes(1)

				-- Callbacks bubble (reverse order).
				local call = callback.mock.calls[1]
				jestExpect(call[1]).toBe("test")
				jestExpect(call[3]).toBe(5) -- actual time
				jestExpect(call[4]).toBe(5) -- base time
				jestExpect(call[5]).toBe(25) -- start time
				jestExpect(call[6]).toBe(50) -- commit time
			end)

			it("is not called when blocked by sCU false", function()
				local callback = jest.fn()

				local instance
				local Updater = React.Component:extend("Updater")
				function Updater:init()
					self.state = {}
				end
				function Updater:render()
					instance = self
					return self.props.children
				end

				local renderer = ReactTestRenderer.create(
					React.createElement(
						React.Profiler,
						{ id = "outer", onRender = callback },
						React.createElement(
							Updater,
							nil,
							React.createElement(
								React.Profiler,
								{ id = "inner", onRender = callback },
								React.createElement("div")
							)
						)
					)
				)

				-- All profile callbacks are called for initial render
				jestExpect(callback).toHaveBeenCalledTimes(2)

				callback:mockReset()

				renderer.unstable_flushSync(function()
					instance:setState({
						count = 1,
					})
				end)

				-- Only call onRender for paths that have re-rendered.
				-- Since the Updater's props didn't change,
				-- React does not re-render its children.
				jestExpect(callback).toHaveBeenCalledTimes(1)
				jestExpect(callback.mock.calls[1][1]).toBe("outer")
			end)

			it(
				"decreases actual time but not base time when sCU prevents an update",
				function()
					local callback = jest.fn()

					Scheduler.unstable_advanceTime(5) -- 0 -> 5

					local renderer = ReactTestRenderer.create(
						React.createElement(
							React.Profiler,
							{ id = "test", onRender = callback },
							React.createElement(
								AdvanceTime,
								{ byAmount = 10 },
								React.createElement(
									AdvanceTime,
									{ byAmount = 13, shouldComponentUpdate = false }
								)
							)
						)
					)

					jestExpect(callback).toHaveBeenCalledTimes(1)

					Scheduler.unstable_advanceTime(30) -- 28 -> 58

					renderer.update(
						React.createElement(
							React.Profiler,
							{ id = "test", onRender = callback },
							React.createElement(
								AdvanceTime,
								{ byAmount = 4 },
								React.createElement(
									AdvanceTime,
									{ byAmount = 7, shouldComponentUpdate = false }
								)
							)
						)
					)

					jestExpect(callback).toHaveBeenCalledTimes(2)

					local mountCall, updateCall =
						callback.mock.calls[1], callback.mock.calls[2]

					jestExpect(mountCall[2]).toBe("mount")
					jestExpect(mountCall[3]).toBe(23) -- actual time
					jestExpect(mountCall[4]).toBe(23) -- base time
					jestExpect(mountCall[5]).toBe(5) -- start time
					jestExpect(mountCall[6]).toBe(28) -- commit time

					jestExpect(updateCall[2]).toBe("update")
					jestExpect(updateCall[3]).toBe(4) -- actual time
					jestExpect(updateCall[4]).toBe(17) -- base time
					jestExpect(updateCall[5]).toBe(58) -- start time
					jestExpect(updateCall[6]).toBe(62) -- commit time
				end
			)

			it("includes time spent in render phase lifecycles", function()
				local WithLifecycles = React.Component:extend("WithLifecycles")
				function WithLifecycles:init()
					self.state = {}
				end
				WithLifecycles.getDerivedStateFromProps = function()
					Scheduler.unstable_advanceTime(3)
					return nil
				end
				function WithLifecycles:shouldComponentUpdate()
					Scheduler.unstable_advanceTime(7)
					return true
				end
				function WithLifecycles:render()
					Scheduler.unstable_advanceTime(5)
					return nil
				end

				local callback = jest.fn()

				Scheduler.unstable_advanceTime(5) -- 0 -> 5

				local renderer = ReactTestRenderer.create(
					React.createElement(
						React.Profiler,
						{ id = "test", onRender = callback },
						React.createElement(WithLifecycles)
					)
				)

				Scheduler.unstable_advanceTime(15) -- 13 -> 28

				renderer.update(
					React.createElement(
						React.Profiler,
						{ id = "test", onRender = callback },
						React.createElement(WithLifecycles)
					)
				)

				jestExpect(callback).toHaveBeenCalledTimes(2)

				local mountCall, updateCall =
					callback.mock.calls[1], callback.mock.calls[2]

				jestExpect(mountCall[2]).toBe("mount")
				jestExpect(mountCall[3]).toBe(8) -- actual time
				jestExpect(mountCall[4]).toBe(8) -- base time
				jestExpect(mountCall[5]).toBe(5) -- start time
				jestExpect(mountCall[6]).toBe(13) -- commit time

				jestExpect(updateCall[2]).toBe("update")
				jestExpect(updateCall[3]).toBe(15) -- actual time
				jestExpect(updateCall[4]).toBe(15) -- base time
				jestExpect(updateCall[5]).toBe(28) -- start time
				jestExpect(updateCall[6]).toBe(43) -- commit time
			end)

			describe("with regard to interruptions", function()
				for _, replayFailedUnitOfWorkWithInvokeGuardedCallback in { true, false } do
					describe(
						"replayFailedUnitOfWorkWithInvokeGuardedCallback "
							.. (function()
								if replayFailedUnitOfWorkWithInvokeGuardedCallback then
									return "enabled"
								end
								return "disabled"
							end)(),
						function()
							beforeEach(function()
								jest.resetModules()

								loadModules({
									replayFailedUnitOfWorkWithInvokeGuardedCallback = replayFailedUnitOfWorkWithInvokeGuardedCallback,
								})
							end)

							it(
								"should accumulate actual time after an error handled by componentDidCatch()",
								function()
									local callback = jest.fn()

									local ThrowsError = function(props)
										local _unused = props.unused
										Scheduler.unstable_advanceTime(3)
										error("expected error")
									end

									local ErrorBoundary =
										React.Component:extend("ErrorBoundary")
									function ErrorBoundary:init()
										self.state = { error_ = nil }
									end
									function ErrorBoundary:componentDidCatch(error_)
										self:setState({ error_ = error_ })
									end
									function ErrorBoundary:render()
										Scheduler.unstable_advanceTime(2)
										return (function()
											if self.state.error_ == nil then
												return self.props.children
											end
											return React.createElement(
												AdvanceTime,
												{ byAmount = 20 }
											)
										end)()
									end

									Scheduler.unstable_advanceTime(5) -- 0 -> 5

									ReactTestRenderer.create(
										React.createElement(
											React.Profiler,
											{ id = "test", onRender = callback },
											React.createElement(
												ErrorBoundary,
												nil,
												React.createElement(
													AdvanceTime,
													{ byAmount = 9 }
												),
												React.createElement(ThrowsError)
											)
										)
									)

									jestExpect(callback).toHaveBeenCalledTimes(2)

									-- Callbacks bubble (reverse order).
									local mountCall, updateCall =
										callback.mock.calls[1], callback.mock.calls[2]

									-- The initial mount only includes the ErrorBoundary (which takes 2)
									-- But it spends time rendering all of the failed subtree also.
									jestExpect(mountCall[2]).toBe("mount")
									-- actual time includes: 2 (ErrorBoundary) + 9 (AdvanceTime) + 3 (ThrowsError)
									-- We don't count the time spent in replaying the failed unit of work (ThrowsError)
									jestExpect(mountCall[3]).toBe(14)
									-- base time includes: 2 (ErrorBoundary)
									-- Since the tree is empty for the initial commit
									jestExpect(mountCall[4]).toBe(2)
									-- start time
									jestExpect(mountCall[5]).toBe(5)
									-- commit time: 5 initially + 14 of work
									-- Add an additional 3 (ThrowsError) if we replayed the failed work
									jestExpect(mountCall[6]).toBe((function()
										if
											_G.__DEV__
											and replayFailedUnitOfWorkWithInvokeGuardedCallback
										then
											return 22
										end
										return 19
									end)())

									-- The update includes the ErrorBoundary and its fallback child
									jestExpect(updateCall[2]).toBe("update")
									-- actual time includes: 2 (ErrorBoundary) + 20 (AdvanceTime)
									jestExpect(updateCall[3]).toBe(22)
									-- base time includes: 2 (ErrorBoundary) + 20 (AdvanceTime)
									jestExpect(updateCall[4]).toBe(22)
									-- start time
									jestExpect(updateCall[5]).toBe((function()
										if
											_G.__DEV__
											and replayFailedUnitOfWorkWithInvokeGuardedCallback
										then
											return 22
										end
										return 19
									end)())

									-- commit time: 19 (startTime) + 2 (ErrorBoundary) + 20 (AdvanceTime)
									-- Add an additional 3 (ThrowsError) if we replayed the failed work
									jestExpect(updateCall[6]).toBe((function()
										if
											_G.__DEV__
											and replayFailedUnitOfWorkWithInvokeGuardedCallback
										then
											return 44
										end
										return 41
									end)())
								end
							)

							it(
								"should accumulate actual time after an error handled by getDerivedStateFromError()",
								function()
									local callback = jest.fn()

									local ThrowsError = function(props)
										local _unused = props.unused
										Scheduler.unstable_advanceTime(10)
										error("expected error")
									end

									local ErrorBoundary =
										React.Component:extend("ErrorBoundary")
									function ErrorBoundary:init()
										self.state = { error_ = nil }
									end
									function ErrorBoundary.getDerivedStateFromError(
										error_
									)
										return { error_ = error_ }
									end
									function ErrorBoundary:render()
										Scheduler.unstable_advanceTime(2)
										return (function()
											if self.state.error_ == nil then
												return self.props.children
											end
											return React.createElement(
												AdvanceTime,
												{ byAmount = 20 }
											)
										end)()
									end

									Scheduler.unstable_advanceTime(5) -- 0 -> 5

									ReactTestRenderer.create(
										React.createElement(
											React.Profiler,
											{ id = "test", onRender = callback },
											React.createElement(
												ErrorBoundary,
												nil,
												React.createElement(
													AdvanceTime,
													{ byAmount = 5 }
												),
												React.createElement(ThrowsError)
											)
										)
									)

									jestExpect(callback).toHaveBeenCalledTimes(1)

									-- Callbacks bubble (reverse order).
									local mountCall = callback.mock.calls[1]

									-- The initial mount includes the ErrorBoundary's error state,
									-- But it also spends actual time rendering UI that fails and isn't included.
									jestExpect(mountCall[2]).toBe("mount")
									-- actual time includes: 2 (ErrorBoundary) + 5 (AdvanceTime) + 10 (ThrowsError)
									-- Then the re-render: 2 (ErrorBoundary) + 20 (AdvanceTime)
									-- We don't count the time spent in replaying the failed unit of work (ThrowsError)
									jestExpect(mountCall[3]).toBe(39)
									-- base time includes: 2 (ErrorBoundary) + 20 (AdvanceTime)
									jestExpect(mountCall[4]).toBe(22)
									-- start time
									jestExpect(mountCall[5]).toBe(5)
									-- commit time
									jestExpect(mountCall[6]).toBe((function()
										if
											_G.__DEV__
											and replayFailedUnitOfWorkWithInvokeGuardedCallback
										then
											return 54
										end
										return 44
									end)())
								end
							)

							it(
								'should reset the fiber stack correct after a "complete" phase error',
								function()
									jest.resetModules()

									loadModules({
										useNoopRenderer = true,
										replayFailedUnitOfWorkWithInvokeGuardedCallback = replayFailedUnitOfWorkWithInvokeGuardedCallback,
									})

									-- Simulate a renderer error during the "complete" phase.
									-- This mimics behavior like React Native's View/Text nesting validation.
									ReactNoop.render(
										React.createElement(
											React.Profiler,
											{ id = "profiler", onRender = jest.fn() },
											React.createElement(
												"errorInCompletePhase",
												nil,
												"hi"
											)
										)
									)
									jestExpect(Scheduler).toFlushAndThrow(
										"Error in host config."
									)

									-- A similar case we've seen caused by an invariant in ReactDOM.
									-- It didn't reproduce without a host component inside.
									ReactNoop.render(
										React.createElement(
											React.Profiler,
											{ id = "profiler", onRender = jest.fn() },
											React.createElement(
												"errorInCompletePhase",
												nil,
												React.createElement("span", nil, "hi")
											)
										)
									)
									jestExpect(Scheduler).toFlushAndThrow(
										"Error in host config."
									)

									-- So long as the profiler timer's fiber stack is reset correctly,
									-- Subsequent renders should not error.
									ReactNoop.render(
										React.createElement(
											React.Profiler,
											{ id = "profiler", onRender = jest.fn() },
											React.createElement("span", nil, "hi")
										)
									)
									jestExpect(Scheduler).toFlushWithoutYielding()
								end
							)
						end
					)
				end
			end)
		end)
	end
end)
