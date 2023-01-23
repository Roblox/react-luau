--[[
	* Copyright (c) Roblox Corporation. All rights reserved.
	* Licensed under the MIT License (the "License");
	* you may not use this file except in compliance with the License.
	* You may obtain a copy of the License at
	*
	*     https://opensource.org/licenses/MIT
	*
	* Unless required by applicable law or agreed to in writing, software
	* distributed under the License is distributed on an "AS IS" BASIS,
	* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	* See the License for the specific language governing permissions and
	* limitations under the License.
]]

local Packages = script.Parent.Parent.Parent.Parent

local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local jest = JestGlobals.jest
local beforeEach = JestGlobals.beforeEach
local it = JestGlobals.it
local describe = JestGlobals.describe

local React
local ReactRoblox
local reactRobloxRoot
local parent

beforeEach(function()
	jest.resetModules()
	jest.useFakeTimers()
	local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
	ReactFeatureFlags.debugRenderPhaseSideEffectsForStrictMode = false

	React = require(Packages.React)
	ReactRoblox = require(Packages.ReactRoblox)
	parent = Instance.new("Folder")
	reactRobloxRoot = ReactRoblox.createRoot(parent)
end)

it("should update a value without re-rendering", function()
	local value, setValue = React.createBinding("hello")
	local renderCount = 0
	local function Component(props)
		renderCount += 1
		return React.createElement("TextLabel", {
			Name = "Label",
			Text = value,
		})
	end

	ReactRoblox.act(function()
		reactRobloxRoot:render(React.createElement(Component))
	end)

	jestExpect(renderCount).toBe(1)
	jestExpect(parent.Label.Text).toBe("hello")

	setValue("world")

	jestExpect(renderCount).toBe(1)
	jestExpect(parent.Label.Text).toBe("world")
end)

it("subscribe to updates when used as a ref", function()
	local leftButtonRef = React.createRef()
	local rightButtonRef = React.createRef()

	local function Component(props)
		return React.createElement(React.Fragment, nil, {
			Left = React.createElement("TextButton", {
				ref = leftButtonRef,
				NextSelectionRight = rightButtonRef,
			}),
			Right = React.createElement("TextButton", {
				ref = rightButtonRef,
				NextSelectionRight = leftButtonRef,
			}),
		})
	end

	ReactRoblox.act(function()
		reactRobloxRoot:render(React.createElement(Component))
	end)

	jestExpect(leftButtonRef.current).never.toBeNil()
	jestExpect(rightButtonRef.current).never.toBeNil()

	jestExpect(leftButtonRef.current.NextSelectionRight).toBe(rightButtonRef.current)
	jestExpect(rightButtonRef.current.NextSelectionRight).toBe(leftButtonRef.current)
end)

it("should not return the same root twice", function()
	local parent2 = Instance.new("Folder")
	local reactRobloxRoot2 = ReactRoblox.createRoot(parent2)

	jestExpect(reactRobloxRoot).never.toBe(reactRobloxRoot2)
end)

describe("useBinding hook", function()
	it("returns the same binding object each time", function()
		local captureBinding = jest.fn()
		local updateComponent
		local function Component(props)
			local binding, updater = React.useBinding("hello")
			local stateValue, updateStateValue = React.useState(1)
			captureBinding(binding, updater)
			updateComponent = function()
				updateStateValue(function(prev)
					return prev + 1
				end)
			end

			return React.createElement("TextLabel", {
				Name = "Label",
				LayoutOrder = stateValue,
				Text = binding,
			})
		end

		ReactRoblox.act(function()
			reactRobloxRoot:render(React.createElement(Component))
		end)

		jestExpect(captureBinding).toHaveBeenCalledTimes(1)
		jestExpect(parent.Label.Text).toBe("hello")
		jestExpect(parent.Label.LayoutOrder).toBe(1)

		ReactRoblox.act(function()
			updateComponent()
		end)

		jestExpect(captureBinding).toHaveBeenCalledTimes(2)
		local capturedBindings = captureBinding.mock.calls
		jestExpect(capturedBindings[1]).toEqual(capturedBindings[2])
		jestExpect(parent.Label.Text).toBe("hello")
		jestExpect(parent.Label.LayoutOrder).toBe(2)
	end)

	it("updates the relevant property without re-rendering", function()
		local updateBinding
		local renderCount = 0
		local function Component(props)
			local value, setValue = React.useBinding("hello")
			updateBinding = setValue
			renderCount += 1
			return React.createElement("TextLabel", {
				Name = "Label",
				Text = value,
			})
		end

		ReactRoblox.act(function()
			reactRobloxRoot:render(React.createElement(Component))
		end)

		jestExpect(renderCount).toBe(1)
		jestExpect(parent.Label.Text).toBe("hello")

		updateBinding("world")

		jestExpect(renderCount).toBe(1)
		jestExpect(parent.Label.Text).toBe("world")
	end)

	it("can be used with mapped bindings", function()
		local updateBinding
		local renderCount = 0
		local function Component(props)
			local text, setText = React.useBinding("hello")
			updateBinding = setText
			renderCount += 1
			return React.createElement("TextLabel", {
				Name = "Label",
				Text = text:map(function(value)
					return string.reverse(value)
				end),
			})
		end

		ReactRoblox.act(function()
			reactRobloxRoot:render(React.createElement(Component))
		end)

		jestExpect(renderCount).toBe(1)
		jestExpect(parent.Label.Text).toBe("olleh")

		updateBinding("world")

		jestExpect(renderCount).toBe(1)
		jestExpect(parent.Label.Text).toBe("dlrow")
	end)

	it("mapped bindings can be re-mapped", function()
		-- Accepts a binding and remaps it
		local function Remap(props)
			return React.createElement("TextLabel", {
				Name = "LabelLength",
				Text = props.length:map(function(value)
					return "Length: " .. tostring(value)
				end),
			})
		end

		local updateBinding
		local renderCount = 0
		local function Component(props)
			local text, setText = React.useBinding("hello")
			updateBinding = setText
			renderCount += 1
			return React.createElement(
				React.Fragment,
				nil,
				React.createElement("TextLabel", {
					Name = "Label",
					Text = text:map(string.reverse),
				}),
				React.createElement(Remap, {
					length = text:map(string.len),
				})
			)
		end

		ReactRoblox.act(function()
			reactRobloxRoot:render(React.createElement(Component))
		end)

		jestExpect(renderCount).toBe(1)
		jestExpect(parent.Label.Text).toBe("olleh")
		jestExpect(parent.LabelLength.Text).toBe("Length: 5")

		updateBinding("friends")

		jestExpect(renderCount).toBe(1)
		jestExpect(parent.Label.Text).toBe("sdneirf")
		jestExpect(parent.LabelLength.Text).toBe("Length: 7")
	end)

	it("can be used with joined bindings", function()
		local updatePrefix, updateText
		local renderCount = 0
		local function Component(props)
			local prefix, setPrefix = React.useBinding("Greeting:")
			local text, setText = React.useBinding("hello")
			updatePrefix, updateText = setPrefix, setText
			renderCount += 1

			local fullText = React.joinBindings({ prefix, text })

			return React.createElement("TextLabel", {
				Name = "Label",
				Text = fullText:map(function(values)
					return table.concat(values, " ")
				end),
			})
		end

		ReactRoblox.act(function()
			reactRobloxRoot:render(React.createElement(Component))
		end)

		jestExpect(renderCount).toBe(1)
		jestExpect(parent.Label.Text).toBe("Greeting: hello")

		updatePrefix("Salutation:")

		jestExpect(renderCount).toBe(1)
		jestExpect(parent.Label.Text).toBe("Salutation: hello")

		updateText("sup")

		jestExpect(renderCount).toBe(1)
		jestExpect(parent.Label.Text).toBe("Salutation: sup")
	end)
end)
