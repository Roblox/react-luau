--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/__tests__/profilerStore-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

return function()
	local Packages = script.Parent.Parent.Parent
	local JestGlobals = require(Packages.Dev.JestGlobals)
	local jest = JestGlobals.jest
	local jestExpect = JestGlobals.expect

	local devtoolsTypes = require(script.Parent.Parent.devtools.types)
	type Store = devtoolsTypes.Store

	local global = _G

	xdescribe("ProfilerStore", function()
		local React
		local ReactRoblox
		local LuauPolyfill
		local store: Store
		local utils
		local act

		beforeEach(function()
			utils = require(script.Parent.utils)
			act = utils.act

			store = global.store
			store:setCollapseNodesByDefault(false)
			store:setRecordChangeDescriptions(true)

			React = require(Packages.React)
			ReactRoblox = require(Packages.ReactRoblox)
			LuauPolyfill = require(Packages.LuauPolyfill)

			utils.beforeEachProfiling()
		end)

		it("should not remove profiling data when roots are unmounted", function()
			local function Child()
				return React.createElement("Frame")
			end

			local function Parent(props)
				local count = props.count

				local arr = table.create(count) :: any
				for index = 1, count do
					arr[index] = React.createElement(
						Child,
						{ key = tostring(index), duration = index }
					)
				end
				return arr
			end

			local containerA = ReactRoblox.createRoot(Instance.new("Frame"))
			local containerB = ReactRoblox.createRoot(Instance.new("Frame"))
			act(function()
				containerA:render(React.createElement(Parent, { key = "A", count = 3 }))
				containerB:render(React.createElement(Parent, { key = "B", count = 2 }))
			end)
			act(function()
				store._profilerStore:startProfiling()
			end)
			act(function()
				containerA:render(React.createElement(Parent, { key = "A", count = 4 }))
				containerB:render(React.createElement(Parent, { key = "B", count = 1 }))
			end)
			act(function()
				store._profilerStore:stopProfiling()
			end)
			local rootA = store:getRoots()[1]
			local rootB = store:getRoots()[2]
			act(function()
				containerB:render(nil)
			end)
			jestExpect(store._profilerStore:getDataForRoot(rootA)).never.toBeNull()
			act(function()
				containerA:render(nil)
			end)
			jestExpect(store._profilerStore:getDataForRoot(rootB)).never.toBeNull()
		end)
		it(
			"should not allow new/saved profiling data to be set while profiling is in progress",
			function()
				act(function()
					return store._profilerStore:startProfiling()
				end)
				local fauxProfilingData = {
					-- ROLBLOX deviation START: upstream doesn't typecheck, needs mandatory imported field
					dataForRoots = LuauPolyfill.Map.new(),
					imported = false,
					-- ROBLOX deviation END
				}

				-- ROBLOX deviation: spyOn console.warn workaround
				local mockWarn = jest.fn().mockName("console.warn")
				LuauPolyfill.console.warn = mockWarn

				store._profilerStore:profilingData(fauxProfilingData)
				jestExpect(store._profilerStore.profilingData).never.toBe(
					fauxProfilingData
				)
				jestExpect(mockWarn).toHaveBeenCalledTimes(1)
				jestExpect(mockWarn).toHaveBeenCalledWith(
					"Profiling data cannot be updated while profiling is in progress."
				)

				act(function()
					return store._profilerStore:stopProfiling()
				end)

				store._profilerStore:profilingData(fauxProfilingData)
				jestExpect(store._profilerStore:profilingData()).toBe(fauxProfilingData)
			end
		)

		--[[ ROBLOX note: This seems to test edges that aren't present in our environment
		-- This test covers current broken behavior (arguably) with the synthetic event system.
		it("should filter empty commits", function()
			local inputRef = React.createRef()
			local function ControlledInput()
				local name, setName = React.useState("foo")
				local function handleChange(event)
					return setName(event.target.value)
				end
				return React.createElement(
					"input",
					{ ref = inputRef, value = name, onChange = handleChange }
				)
			end

			local container = Instance.new("Frame") -- This element has to be in the <body> for the event system to work.
			-document.body:appendChild(container) -- It's important that this test uses legacy sync mode.
			-- The root API does not trigger this particular failing case.
			ReactRoblox.createRoot(container):render(React.createElement(ControlledInput, nil))
			act(function()
				return store._profilerStore:startProfiling()
			end)

			-- Sets a value in a way that React doesn't see,
			-- so that a subsequent "change" event will trigger the event handler.
			local setUntrackedValue = Object.getOwnPropertyDescriptor(
				HTMLInputElement.prototype,
				"value"
			).set

			local target = inputRef.current
			setUntrackedValue(target, "bar")
			target:dispatchEvent(
				Event.new("input", { bubbles = true, cancelable = true })
			)
			jestExpect(target.value).toBe("bar")

			act(function()
				return store._profilerStore:stopProfiling()
			end)

			-- Only one commit should have been recorded (in response to the "change" event).
			local root = store:getRoots()[1]
			local data = store._profilerStore:getDataForRoot(root)
			jestExpect(data.commitData).toHaveLength(1)
			jestExpect(data.operations).toHaveLength(1)
		end)
		--]]
	end)
end
