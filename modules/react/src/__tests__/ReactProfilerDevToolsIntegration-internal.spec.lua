-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react/src/__tests__/ReactProfilerDevToolsIntegration-test.internal.js
local Packages = script.Parent.Parent.Parent
local React
local Scheduler
local LuauPolyfill = require(Packages.LuauPolyfill)
local Set = LuauPolyfill.Set
local JestGlobals = require(Packages.Dev.JestGlobals)
local describe = JestGlobals.describe

describe("ReactProfiler DevTools integration", function()
	local jestExpect = JestGlobals.expect
	local jest = JestGlobals.jest
	local it = JestGlobals.it
	local beforeEach = JestGlobals.beforeEach
	local afterEach = JestGlobals.afterEach
	local ReactFeatureFlags
	local ReactTestRenderer
	local SchedulerTracing
	local AdvanceTime
	local hook
	local originalDevtoolsState

	beforeEach(function()
		hook = {
			inject = function() end,
			onCommitFiberRoot = jest.fn(function(rendererId, root) end),
			onCommitFiberUnmount = function() end,
			supportsFiber = true,
		}
		originalDevtoolsState = _G.__REACT_DEVTOOLS_GLOBAL_HOOK__
		_G.__REACT_DEVTOOLS_GLOBAL_HOOK__ = hook

		jest.resetModules()

		ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
		ReactFeatureFlags.enableProfilerTimer = true
		ReactFeatureFlags.enableSchedulerTracing = true
		Scheduler = require(Packages.Dev.Scheduler)
		-- ROBLOX deviation: import tracing from top-level Scheduler export to avoid direct file access
		SchedulerTracing = Scheduler.tracing
		React = require(Packages.React)
		ReactTestRenderer = require(Packages.Dev.ReactTestRenderer)

		AdvanceTime = React.Component:extend("AdvanceTime")
		AdvanceTime.defaultProps = {
			byAmount = 10,
			shouldComponentUpdate = true,
		}
		function AdvanceTime:shouldComponentUpdate(nextProps)
			return nextProps.shouldComponentUpdate
		end
		function AdvanceTime:render()
			-- Simulate time passing when this component is rendered
			Scheduler.unstable_advanceTime(self.props.byAmount)
			return self.props.children or nil
		end
	end)

	afterEach(function()
		_G.__REACT_DEVTOOLS_GLOBAL_HOOK__ = originalDevtoolsState
	end)

	it("should auto-Profile all fibers if the DevTools hook is detected", function()
		-- ROBLOX deviation: hoist declaration so the value is captured correctly
		local onRender = jest.fn(function() end)
		local App = function(props)
			local multiplier = props.multiplier

			Scheduler.unstable_advanceTime(2)

			return React.createElement(
				React.Profiler,
				{
					id = "Profiler",
					onRender = onRender,
				},
				React.createElement(AdvanceTime, {
					byAmount = 3 * multiplier,
					shouldComponentUpdate = true,
				}),
				React.createElement(AdvanceTime, {
					byAmount = 7 * multiplier,
					shouldComponentUpdate = false,
				})
			)
		end

		local rendered =
			ReactTestRenderer.create(React.createElement(App, { multiplier = 1 }))

		jestExpect(hook.onCommitFiberRoot).toHaveBeenCalledTimes(1)

		-- Measure observable timing using the Profiler component.
		-- The time spent in App (above the Profiler) won't be included in the durations,
		-- But needs to be accounted for in the offset times.
		jestExpect(onRender).toHaveBeenCalledTimes(1)
		jestExpect(onRender).toHaveBeenCalledWith(
			"Profiler",
			"mount",
			10,
			10,
			2,
			12,
			Set.new()
		)
		onRender.mockClear()

		-- Measure unobservable timing required by the DevTools profiler.
		-- At this point, the base time should include both:
		-- The time 2ms in the App component itself, and
		-- The 10ms spend in the Profiler sub-tree beneath.
		jestExpect(rendered.root:findByType(App):_currentFiber().treeBaseDuration).toBe(
			12
		)

		rendered.update(React.createElement(App, { multiplier = 2 }))

		-- Measure observable timing using the Profiler component.
		-- The time spent in App (above the Profiler) won't be included in the durations,
		-- But needs to be accounted for in the offset times.
		jestExpect(onRender).toHaveBeenCalledTimes(1)
		jestExpect(onRender).toHaveBeenCalledWith(
			"Profiler",
			"update",
			6,
			13,
			14,
			20,
			Set.new()
		)

		-- Measure unobservable timing required by the DevTools profiler.
		-- At this point, the base time should include both:
		-- The initial 9ms for the components that do not re-render, and
		-- The updated 6ms for the component that does.
		jestExpect(rendered.root:findByType(App):_currentFiber().treeBaseDuration).toBe(
			15
		)
	end)

	it(
		"should reset the fiber stack correctly after an error when profiling host roots",
		function()
			Scheduler.unstable_advanceTime(20)

			local rendered = ReactTestRenderer.create(
				React.createElement(
					"div",
					nil,
					React.createElement(AdvanceTime, { byAmount = 2 })
				)
			)

			Scheduler.unstable_advanceTime(20)

			jestExpect(function()
				rendered.update(React.createElement("div", {
					ref = "this-will-cause-an-error",
				}, React.createElement(AdvanceTime, { byAmount = 3 })))
			end).toThrow()

			Scheduler.unstable_advanceTime(20)

			-- But this should render correctly, if the profiler's fiber stack has been reset.
			rendered.update(
				React.createElement(
					"div",
					nil,
					React.createElement(AdvanceTime, { byAmount = 7 })
				)
			)

			-- Measure unobservable timing required by the DevTools profiler.
			-- At this point, the base time should include only the most recent (not failed) render.
			-- It should not include time spent on the initial render,
			-- Or time that elapsed between any of the above renders.
			jestExpect(rendered.root:findByType("div"):_currentFiber().treeBaseDuration).toBe(
				7
			)
		end
	)

	it(
		"should store traced interactions on the HostNode so DevTools can access them",
		function()
			-- Render without an interaction
			local rendered = ReactTestRenderer.create(React.createElement("div"))

			local root = rendered.root:_currentFiber().return_
			jestExpect(root.stateNode.memoizedInteractions).toContainNoInteractions()

			Scheduler.unstable_advanceTime(10)

			local eventTime = Scheduler.unstable_now()

			-- Render with an interaction
			SchedulerTracing.unstable_trace("some event", eventTime, function()
				rendered.update(React.createElement("div"))
			end)

			jestExpect(root.stateNode.memoizedInteractions).toMatchInteractions({
				{
					name = "some event",
					timestamp = eventTime,
				},
			})
		end
	)

	it("regression test: #17159", function()
		local function Text(props)
			local text = props.text

			Scheduler.unstable_yieldValue(text)

			return text
		end

		local root = ReactTestRenderer.create(nil, { unstable_isConcurrent = true })

		-- Commit something
		root.update(React.createElement(Text, {
			text = "A",
		}))
		jestExpect(Scheduler).toFlushAndYield({
			"A",
		})
		jestExpect(root).toMatchRenderedOutput("A")

		-- Advance time by many seconds, larger than the default expiration time
		-- for updates.
		Scheduler.unstable_advanceTime(10000)
		root.update(React.createElement(Text, {
			text = "B",
		}))

		-- Update B should not instantly expire.
		jestExpect(Scheduler).toFlushExpired({})
		jestExpect(Scheduler).toFlushAndYield({
			"B",
		})
		jestExpect(root).toMatchRenderedOutput("B")
	end)
end)
