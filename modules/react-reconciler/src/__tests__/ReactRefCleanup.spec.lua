-- ROBLOX upstream: https://github.com/facebook/react/blob/d4e78c42a94be027b4dc7ed2659a5fddfbf9bd4e/packages/react-dom/src/__tests__/refs-test.js#L564-L755
--[[*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 ]]
--!strict

local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local jest = JestGlobals.jest
local jestExpect = JestGlobals.expect
local it = JestGlobals.it

local React
local ReactNoop

-- ROBLOX DEVIATION: React-Luau uses ReactNoop's public renderer seam instead
-- of the DOM container, and ReactNoop.act is synchronous.
describe("refs return clean up function", function()
	beforeEach(function()
		jest.resetModules()
		React = require(Packages.React)
		ReactNoop = require(Packages.Dev.ReactNoopRenderer)
	end)

	it("calls clean up function if it exists", function()
		local cleanUpMock, cleanUp = jest.fn()
		local setup = jest.fn()
		local root = ReactNoop.createRoot()

		ReactNoop.act(function()
			root.render(React.createElement("div", {
				ref = function(ref)
					setup(ref)
					return cleanUp
				end,
			}))
		end)

		ReactNoop.act(function()
			root.render(React.createElement("div", {
				ref = function(ref)
					setup(ref)
				end,
			}))
		end)

		jestExpect(setup).toHaveBeenCalledTimes(2)
		jestExpect(cleanUpMock).toHaveBeenCalledTimes(1)
		jestExpect(cleanUpMock.mock.calls[1][1]).toBe(nil)

		ReactNoop.act(function()
			root.render(React.createElement("div", {
				ref = function() end,
			}))
		end)

		jestExpect(cleanUpMock).toHaveBeenCalledTimes(1)
		jestExpect(setup).toHaveBeenCalledTimes(3)
		-- ROBLOX DEVIATION: Jest-Lua records an explicit nil argument as an
		-- Object.None sentinel owned by the mock package's dependency graph.
		jestExpect(tostring(setup.mock.calls[3][1])).toBe("Object.None")

		cleanUpMock, cleanUp = jest.fn()
		setup = jest.fn()

		ReactNoop.act(function()
			root.render(React.createElement("div", {
				ref = function(ref)
					setup(ref)
					return cleanUp
				end,
			}))
		end)

		jestExpect(setup).toHaveBeenCalledTimes(1)
		jestExpect(cleanUpMock).toHaveBeenCalledTimes(0)

		ReactNoop.act(function()
			root.render(React.createElement("div", {
				ref = function(ref)
					setup(ref)
					return cleanUp
				end,
			}))
		end)

		jestExpect(setup).toHaveBeenCalledTimes(2)
		jestExpect(cleanUpMock).toHaveBeenCalledTimes(1)
	end)

	it("handles ref functions with stable identity", function()
		local cleanUpMock, cleanUp = jest.fn()
		local setup = jest.fn()
		local function onRefChange(ref)
			setup(ref)
			return cleanUp
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement("div", { ref = onRefChange }))
		end)

		jestExpect(setup).toHaveBeenCalledTimes(1)
		jestExpect(cleanUpMock).toHaveBeenCalledTimes(0)

		ReactNoop.act(function()
			root.render(React.createElement("div", {
				className = "niceClassName",
				ref = onRefChange,
			}))
		end)

		jestExpect(setup).toHaveBeenCalledTimes(1)
		jestExpect(cleanUpMock).toHaveBeenCalledTimes(0)

		ReactNoop.act(function()
			root.render(React.createElement("div"))
		end)

		jestExpect(setup).toHaveBeenCalledTimes(1)
		jestExpect(cleanUpMock).toHaveBeenCalledTimes(1)
	end)

	it("handles detaching refs with either cleanup function or nil argument", function()
		local cleanUpMock, cleanUp = jest.fn()
		local setup = jest.fn()
		local setup2 = jest.fn()
		local nilHandler = jest.fn()

		local function onRefChangeWithCleanup(ref)
			if ref then
				setup(ref.prop)
			else
				nilHandler()
			end
			return cleanUp
		end

		local function onRefChangeWithoutCleanup(ref)
			if ref then
				setup2(ref.prop)
			else
				nilHandler()
			end
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement("div", {
				prop = "test-div",
				ref = onRefChangeWithCleanup,
			}))
		end)

		jestExpect(setup).toHaveBeenCalledWith("test-div")
		jestExpect(setup).toHaveBeenCalledTimes(1)
		jestExpect(cleanUpMock).toHaveBeenCalledTimes(0)

		ReactNoop.act(function()
			root.render(React.createElement("div", {
				prop = "test-div2",
				ref = onRefChangeWithoutCleanup,
			}))
		end)

		jestExpect(setup).toHaveBeenCalledTimes(1)
		jestExpect(nilHandler).toHaveBeenCalledTimes(0)
		jestExpect(cleanUpMock).toHaveBeenCalledTimes(1)
		jestExpect(setup2).toHaveBeenCalledWith("test-div2")
		jestExpect(setup2).toHaveBeenCalledTimes(1)

		ReactNoop.act(function()
			root.render(React.createElement("div", {
				prop = "test-div3",
				ref = onRefChangeWithCleanup,
			}))
		end)

		jestExpect(setup2).toHaveBeenCalledWith("test-div2")
		jestExpect(setup2).toHaveBeenCalledTimes(1)
		jestExpect(nilHandler).toHaveBeenCalledTimes(1)
		jestExpect(setup).toHaveBeenCalledTimes(2)
	end)

	it("calls cleanup function on unmount", function()
		local cleanUpMock, cleanUp = jest.fn()
		local setup = jest.fn()
		local nilHandler = jest.fn()

		local function onRefChangeWithCleanup(ref)
			if ref then
				setup(ref.prop)
			else
				nilHandler()
			end
			return cleanUp
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement("div", {
				prop = "test-div",
				ref = onRefChangeWithCleanup,
			}))
		end)

		jestExpect(setup).toHaveBeenCalledTimes(1)
		jestExpect(cleanUpMock).toHaveBeenCalledTimes(0)
		jestExpect(nilHandler).toHaveBeenCalledTimes(0)

		ReactNoop.act(function()
			root.render(nil)
		end)

		jestExpect(setup).toHaveBeenCalledTimes(1)
		jestExpect(cleanUpMock).toHaveBeenCalledTimes(1)
		jestExpect(nilHandler).toHaveBeenCalledTimes(0)
	end)

	-- ROBLOX upstream: https://github.com/facebook/react/blob/e98225485a124e35abc4cea82e6da944472ce7c7/packages/react-reconciler/src/ReactFiberCommitWork.new.js#L304-L328
	it("warns when a legacy detach callback returns a cleanup function", function()
		local root = ReactNoop.createRoot()
		local function ref(instance)
			if instance == nil then
				return function() end
			end
			return nil
		end

		ReactNoop.act(function()
			root.render(React.createElement("div", { ref = ref }))
		end)

		jestExpect(function()
			ReactNoop.act(function()
				root.render(nil)
			end)
		end).toErrorDev(
			"Unexpected return value from a callback ref in div. "
				.. "A callback ref should not return a function.",
			{ withoutStack = true }
		)
	end)

	-- ROBLOX DEVIATION: The upstream suite exercises host refs. This parallel
	-- public class-ref case covers React-Luau's class receiver path.
	it("calls cleanup function for class refs", function()
		local cleanUpMock, cleanUp = jest.fn()
		local setup = jest.fn()
		local nilHandler = jest.fn()
		local Component = React.Component:extend("Component")
		function Component:render()
			return nil
		end

		local function classRef(ref)
			if ref then
				setup(ref)
			else
				nilHandler()
			end
			return cleanUp
		end

		local root = ReactNoop.createRoot()
		ReactNoop.act(function()
			root.render(React.createElement(Component, { ref = classRef }))
		end)
		ReactNoop.act(function()
			root.render(nil)
		end)

		jestExpect(setup).toHaveBeenCalledTimes(1)
		jestExpect(cleanUpMock).toHaveBeenCalledTimes(1)
		jestExpect(nilHandler).toHaveBeenCalledTimes(0)
	end)
end)

-- ROBLOX upstream: https://github.com/facebook/react/blob/ed71a3ad2965617c27c6e7ca7577f15b8ca4152c/packages/react-dom/src/__tests__/refs-test.js#L744-L830
describe("useImerativeHandle refs", function()
	beforeEach(function()
		jest.resetModules()
		React = require(Packages.React)
		ReactNoop = require(Packages.Dev.ReactNoopRenderer)
	end)

	local function createImperativeHandleComponent()
		return React.forwardRef(function(props, ref)
			React.useImperativeHandle(ref, function()
				return {
					greet = function()
						return "Hello " .. props.name
					end,
				}
			end, { props.name })
			return nil
		end)
	end

	it("should work with object style refs", function()
		local ImperativeHandleComponent = createImperativeHandleComponent()
		local root = ReactNoop.createRoot()
		local ref = React.createRef()

		ReactNoop.act(function()
			root.render(React.createElement(ImperativeHandleComponent, {
				name = "Alice",
				ref = ref,
			}))
		end)
		jestExpect(ref.current.greet()).toBe("Hello Alice")
		ReactNoop.act(function()
			root.render(nil)
		end)
		jestExpect(ref.current).toBe(nil)
	end)

	it("should work with callback style refs", function()
		local ImperativeHandleComponent = createImperativeHandleComponent()
		local root = ReactNoop.createRoot()
		local current = nil

		ReactNoop.act(function()
			root.render(React.createElement(ImperativeHandleComponent, {
				name = "Alice",
				ref = function(ref)
					current = ref
				end,
			}))
		end)
		jestExpect(current.greet()).toBe("Hello Alice")
		ReactNoop.act(function()
			root.render(nil)
		end)
		jestExpect(current).toBe(nil)
	end)

	it("should work with callback style refs with cleanup function", function()
		local ImperativeHandleComponent = createImperativeHandleComponent()
		local root = ReactNoop.createRoot()
		local cleanupCalls = 0
		local createCalls = 0
		local current = nil

		local function ref(nextCurrent)
			current = nextCurrent
			createCalls += 1
			return function()
				current = nil
				cleanupCalls += 1
			end
		end

		ReactNoop.act(function()
			root.render(React.createElement(ImperativeHandleComponent, {
				name = "Alice",
				ref = ref,
			}))
		end)
		jestExpect(current.greet()).toBe("Hello Alice")
		jestExpect(createCalls).toBe(1)
		jestExpect(cleanupCalls).toBe(0)

		ReactNoop.act(function()
			root.render(React.createElement(ImperativeHandleComponent, {
				name = "Bob",
				ref = ref,
			}))
		end)
		jestExpect(current.greet()).toBe("Hello Bob")
		jestExpect(createCalls).toBe(2)
		jestExpect(cleanupCalls).toBe(1)

		ReactNoop.act(function()
			root.render(nil)
		end)
		jestExpect(current).toBe(nil)
		jestExpect(createCalls).toBe(2)
		jestExpect(cleanupCalls).toBe(2)
	end)
end)
