--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.2/packages/react-is/src/__tests__/ReactIs-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 ]]
local Packages = script.Parent.Parent.Parent
-- ROBLOX deviation START: fix import
-- local LuauPolyfill = require(Packages.LuauPolyfill)
local LuauPolyfill = require(Packages.Dev.LuauPolyfill)
-- ROBLOX deviation END
-- ROBLOX deviation START: not used
-- local Boolean = LuauPolyfill.Boolean
-- ROBLOX deviation END
local Object = LuauPolyfill.Object
local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it
local jest = JestGlobals.jest

-- ROBLOX deviation START: add imports
local Promise = require(Packages.Dev.Promise)
local ReactTypes = require(Packages.Shared)
type React_Component<Props, State> = ReactTypes.React_Component<Props, State>
-- ROBLOX deviation END
local React
local ReactDOM
local ReactIs
describe("ReactIs", function()
	beforeEach(function()
		jest.resetModules()
		-- ROBLOX deviation START: additional flag to switch for tests
		local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
		ReactFeatureFlags.replayFailedUnitOfWorkWithInvokeGuardedCallback = false
		-- ROBLOX deviation END
		-- ROBLOX deviation START: fix imports
		-- React = require_("react")
		-- ReactDOM = require_("react-dom")
		-- ReactIs = require_("react-is")
		React = require(Packages.Dev.React)
		ReactIs = require(Packages.ReactIs)
		ReactDOM = require(Packages.Dev.ReactRoblox)
		-- ROBLOX deviation END
	end)
	it("should return undefined for unknown/invalid types", function()
		expect(ReactIs.typeOf("abc")).toBe(nil)
		expect(ReactIs.typeOf(true)).toBe(nil)
		expect(ReactIs.typeOf(123)).toBe(nil)
		expect(ReactIs.typeOf({})).toBe(nil)
		expect(ReactIs.typeOf(nil)).toBe(nil)
		-- ROBLOX deviation START: no undefined in Lua, we only support nil
		-- expect(ReactIs.typeOf(nil)).toBe(nil)
		-- ROBLOX deviation END
	end)
	it("identifies valid element types", function()
		type Component = React_Component<any, any> & {}
		type Component_statics = {}
		local Component =
			React.Component:extend("Component") :: Component & Component_statics
		function Component.render(self: Component)
			-- ROBLOX deviation START: replace div with TextLabel
			-- return React.createElement("div")
			return React.createElement("TextLabel")
			-- ROBLOX deviation END
		end

		local function FunctionComponent()
			-- ROBLOX deviation START: replace div with TextLabel
			-- return React.createElement("div")
			return React.createElement("TextLabel")
			-- ROBLOX deviation END
		end
		local ForwardRefComponent = React.forwardRef(function(props, ref)
			return React.createElement(
				Component,
				Object.assign({}, { forwardedRef = ref }, props)
			)
		end)
		-- ROBLOX TODO: this is incorrect in upstream
		-- ROBLOX note: Lazy will need deeper adaptation for the Luau module system
		-- ROBLOX deviation START: convert return type to thenable
		-- local LazyComponent = React.lazy(function()
		-- 	return Component
		-- end)
		local LazyComponent = React.lazy(function()
			return Promise.delay(0):andThen(function()
				return { default = Component }
			end)
		end)
		-- ROBLOX deviation END
		-- ROBLOX note: Should memo accept a LazyComponent?
		local MemoComponent = React.memo(Component)
		local Context = React.createContext(false)
		expect(ReactIs.isValidElementType("div")).toEqual(true)
		expect(ReactIs.isValidElementType(Component)).toEqual(true)
		expect(ReactIs.isValidElementType(FunctionComponent)).toEqual(true)
		expect(ReactIs.isValidElementType(ForwardRefComponent)).toEqual(true)
		expect(ReactIs.isValidElementType(LazyComponent)).toEqual(true)
		expect(ReactIs.isValidElementType(MemoComponent)).toEqual(true)
		expect(ReactIs.isValidElementType(Context.Provider)).toEqual(true)
		expect(ReactIs.isValidElementType(Context.Consumer)).toEqual(true)
		-- ROBLOX deviation START: we don't support things that are already deprecated
		-- if not Boolean.toJSBoolean(__EXPERIMENTAL__) then
		-- 	local factory
		-- 	expect(function()
		-- 		factory = React.createFactory("div")
		-- 	end).toWarnDev(
		-- 		"Warning: React.createFactory() is deprecated and will be removed in a "
		-- 			.. "future major release. Consider using JSX or use React.createElement() "
		-- 			.. "directly instead.",
		-- 		{ withoutStack = true }
		-- 	)
		-- 	expect(ReactIs:isValidElementType(factory)).toEqual(true)
		-- end
		-- ROBLOX deviation END
		expect(ReactIs.isValidElementType(React.Fragment)).toEqual(true)
		expect(ReactIs.isValidElementType(React.StrictMode)).toEqual(true)
		expect(ReactIs.isValidElementType(React.Suspense)).toEqual(true)
		expect(ReactIs.isValidElementType(true)).toEqual(false)
		expect(ReactIs.isValidElementType(123)).toEqual(false)
		expect(ReactIs.isValidElementType({})).toEqual(false)
		expect(ReactIs.isValidElementType(nil)).toEqual(false)
		-- ROBLOX deviation START: no difference between nil and undefined in Lua, skip
		-- expect(ReactIs.isValidElementType(nil)).toEqual(false)
		-- ROBLOX deviation END
		-- ROBLOX deviation START: replace "div" with "TextLabel", use dot notation
		-- expect(ReactIs.isValidElementType({ type = "div", props = {} })).toEqual(false)
		expect(ReactIs.isValidElementType({ type = "TextLabel", props = {} })).toEqual(
			false
		)
		-- ROBLOX deviation END
	end)
	it("should identify context consumers", function()
		local Context = React.createContext(false)
		expect(ReactIs.isValidElementType(Context.Consumer)).toBe(true)
		expect(ReactIs.typeOf(React.createElement(Context.Consumer, nil))).toBe(
			ReactIs.ContextConsumer
		)
		expect(ReactIs.isContextConsumer(React.createElement(Context.Consumer, nil))).toBe(
			true
		)
		expect(ReactIs.isContextConsumer(React.createElement(Context.Provider, nil))).toBe(
			false
		)
		expect(ReactIs.isContextConsumer(React.createElement("div", nil))).toBe(false)
	end)
	it("should identify context providers", function()
		local Context = React.createContext(false)
		expect(ReactIs.isValidElementType(Context.Provider)).toBe(true)
		expect(ReactIs.typeOf(React.createElement(Context.Provider, nil))).toBe(
			ReactIs.ContextProvider
		)
		expect(ReactIs.isContextProvider(React.createElement(Context.Provider, nil))).toBe(
			true
		)
		expect(ReactIs.isContextProvider(React.createElement(Context.Consumer, nil))).toBe(
			false
		)
		expect(ReactIs.isContextProvider(React.createElement("div", nil))).toBe(false)
	end)
	it("should identify elements", function()
		expect(ReactIs.typeOf(React.createElement("div", nil))).toBe(ReactIs.Element)
		expect(ReactIs.isElement(React.createElement("div", nil))).toBe(true)
		expect(ReactIs.isElement("div")).toBe(false)
		expect(ReactIs.isElement(true)).toBe(false)
		expect(ReactIs.isElement(123)).toBe(false)
		expect(ReactIs.isElement(nil)).toBe(false)
		-- ROBLOX deviation START: no difference between nil and undefined in Lua
		-- expect(ReactIs.isElement(nil)).toBe(false)
		-- ROBLOX deviation END
		expect(ReactIs.isElement({})).toBe(false) -- It should also identify more specific types as elements
		local Context = React.createContext(false)
		expect(ReactIs.isElement(React.createElement(Context.Provider, nil))).toBe(true)
		expect(ReactIs.isElement(React.createElement(Context.Consumer, nil))).toBe(true)
		expect(ReactIs.isElement(React.createElement(React.Fragment, nil))).toBe(true)
		expect(ReactIs.isElement(React.createElement(React.StrictMode, nil))).toBe(true)
		expect(ReactIs.isElement(React.createElement(React.Suspense, nil))).toBe(true)
	end)
	it("should identify ref forwarding component", function()
		local RefForwardingComponent = React.forwardRef(function(props, ref)
			return nil
		end)
		expect(ReactIs.isValidElementType(RefForwardingComponent)).toBe(true)
		expect(ReactIs.typeOf(React.createElement(RefForwardingComponent, nil))).toBe(
			ReactIs.ForwardRef
		)
		expect(ReactIs.isForwardRef(React.createElement(RefForwardingComponent, nil))).toBe(
			true
		)
		expect(ReactIs.isForwardRef({ type = ReactIs.StrictMode })).toBe(false)
		expect(ReactIs.isForwardRef(React.createElement("div", nil))).toBe(false)
	end)
	it("should identify fragments", function()
		expect(ReactIs.isValidElementType(React.Fragment)).toBe(true)
		expect(ReactIs.typeOf(React.createElement(React.Fragment, nil))).toBe(
			ReactIs.Fragment
		)
		expect(ReactIs.isFragment(React.createElement(React.Fragment, nil))).toBe(true)
		expect(ReactIs.isFragment({ type = ReactIs.Fragment })).toBe(false)
		expect(ReactIs.isFragment("React.Fragment")).toBe(false)
		expect(ReactIs.isFragment(React.createElement("div", nil))).toBe(false)
		expect(ReactIs.isFragment({})).toBe(false)
	end)
	it("should identify portals", function()
		-- ROBLOX deviation START: replace created element attachaed to DOM
		-- local div = document:createElement("div")
		local div = Instance.new("ScreenGui")
		-- ROBLOX deviation END
		-- ROBLOX deviation START: replace "div" with "Frame"
		-- local portal = ReactDOM:createPortal(React.createElement("div", nil), div)
		local portal = ReactDOM.createPortal(React.createElement("Frame"), div)
		-- ROBLOX deviation END
		expect(ReactIs.isValidElementType(portal)).toBe(false)
		expect(ReactIs.typeOf(portal)).toBe(ReactIs.Portal)
		expect(ReactIs.isPortal(portal)).toBe(true)
		expect(ReactIs.isPortal(div)).toBe(false)
	end)
	it("should identify memo", function()
		local function Component()
			return React.createElement("div")
		end
		local Memoized = React.memo(Component)
		expect(ReactIs.isValidElementType(Memoized)).toBe(true)
		expect(ReactIs.typeOf(React.createElement(Memoized, nil))).toBe(ReactIs.Memo)
		expect(ReactIs.isMemo(React.createElement(Memoized, nil))).toBe(true)
		expect(ReactIs.isMemo(React.createElement(Component, nil))).toBe(false)
	end)
	it("should identify lazy", function()
		local function Component()
			return React.createElement("div")
		end
		-- ROBLOX TODO: this is incorrect in upstream
		-- ROBLOX deviation START: return thenable
		-- local LazyComponent = React.lazy(function()
		-- 	return Component
		-- end)
		local LazyComponent = React.lazy(function()
			return Promise.delay(0):andThen(function()
				return { default = Component }
			end)
		end)
		-- ROBLOX deviation END
		expect(ReactIs.isValidElementType(LazyComponent)).toBe(true)
		expect(ReactIs.typeOf(React.createElement(LazyComponent, nil))).toBe(ReactIs.Lazy)
		expect(ReactIs.isLazy(React.createElement(LazyComponent, nil))).toBe(true)
		expect(ReactIs.isLazy(React.createElement(Component, nil))).toBe(false)
	end)
	it("should identify strict mode", function()
		expect(ReactIs.isValidElementType(React.StrictMode)).toBe(true)
		expect(ReactIs.typeOf(React.createElement(React.StrictMode, nil))).toBe(
			ReactIs.StrictMode
		)
		expect(ReactIs.isStrictMode(React.createElement(React.StrictMode, nil))).toBe(
			true
		)
		expect(ReactIs.isStrictMode({ type = ReactIs.StrictMode })).toBe(false)
		expect(ReactIs.isStrictMode(React.createElement("div", nil))).toBe(false)
	end)
	it("should identify suspense", function()
		expect(ReactIs.isValidElementType(React.Suspense)).toBe(true)
		expect(ReactIs.typeOf(React.createElement(React.Suspense, nil))).toBe(
			ReactIs.Suspense
		)
		expect(ReactIs.isSuspense(React.createElement(React.Suspense, nil))).toBe(true)
		expect(ReactIs.isSuspense({ type = ReactIs.Suspense })).toBe(false)
		expect(ReactIs.isSuspense("React.Suspense")).toBe(false)
		expect(ReactIs.isSuspense(React.createElement("div", nil))).toBe(false)
	end)
	it("should identify profile root", function()
		expect(ReactIs.isValidElementType(React.Profiler)).toBe(true)
		expect(
			ReactIs.typeOf(
				React.createElement(React.Profiler, { id = "foo", onRender = jest.fn() })
			)
		).toBe(ReactIs.Profiler)
		expect(
			ReactIs.isProfiler(
				React.createElement(React.Profiler, { id = "foo", onRender = jest.fn() })
			)
		).toBe(true)
		expect(ReactIs.isProfiler({ type = ReactIs.Profiler })).toBe(false)
		expect(ReactIs.isProfiler(React.createElement("div", nil))).toBe(false)
	end)
	-- ROBLOX deviation START: added this test to cover deprecation warning
	it("should warn for deprecated functions", function()
		expect(function()
			ReactIs.isConcurrentMode(nil)
		end).toWarnDev("deprecated", { withoutStack = true })
		expect(function()
			ReactIs.isAsyncMode(nil)
		end).toWarnDev("deprecated", { withoutStack = true })
	end)
	-- ROBLOX deviation END
	-- ROBLOX deviation START: add Roblox specific tests - bindings are a feature migrated from Roact
	it("should identify bindings", function()
		local binding, _ = React.createBinding(nil)
		expect(ReactIs.isBinding(binding)).toBe(true)
		local mappedBinding = React.createBinding(nil):map(tostring)
		expect(ReactIs.isBinding(mappedBinding)).toBe(true)
		local joinedBinding = React.joinBindings({
			X = React.createBinding(0),
			Y = React.createBinding(0),
		})
		expect(ReactIs.isBinding(joinedBinding)).toBe(true)
		-- In Roact 17, `ref` objects are implemented in terms of bindings!
		expect(ReactIs.isBinding(React.createRef())).toBe(true)
	end)
	-- ROBLOX deviation END
end)
