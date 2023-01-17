--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/c57fe4a2c1402acdbf31ac48cfc6a6bf336c4067/react-is/src/__tests__/ReactIs-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 *]]

return function()
	local Packages = script.Parent.Parent.Parent
	local Promise = require(Packages.Dev.Promise)
	local JestGlobals = require(Packages.Dev.JestGlobals)
	local jestExpect = JestGlobals.expect
	local jest = JestGlobals.jest
	local RobloxJest = require(Packages.Dev.RobloxJest)
	local React
	local ReactIs
	local ReactRoblox
	local ReactFeatureFlags

	describe("ReactIs", function()
		beforeEach(function()
			RobloxJest.resetModules()
			ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
			ReactFeatureFlags.replayFailedUnitOfWorkWithInvokeGuardedCallback = false

			React = require(Packages.Dev.React)
			ReactIs = require(Packages.ReactIs)
			ReactRoblox = require(Packages.Dev.ReactRoblox)
		end)

		it("should return nil for unknown/invalid types", function()
			jestExpect(ReactIs.typeOf("abc")).toBe(nil)
			jestExpect(ReactIs.typeOf(true)).toBe(nil)
			jestExpect(ReactIs.typeOf(123)).toBe(nil)
			jestExpect(ReactIs.typeOf({})).toBe(nil)
			jestExpect(ReactIs.typeOf(nil)).toBe(nil)
			-- ROBLOX deviation: no undefined in Lua, we only support nil
			-- expect(ReactIs.typeOf(undefined)).toBe(undefined)
		end)

		it("identifies valid element types", function()
			local Component = React.Component:extend("MyComponent")
			Component.render = function()
				return React.createElement("TextLabel")
			end

			local PureComponent = React.PureComponent:extend("MyPureComponent")
			PureComponent.render = function()
				return React.createElement("TextLabel")
			end

			local FunctionComponent = function()
				return React.createElement("TextLabel")
			end

			local ForwardRefComponent = React.forwardRef(function(_props, ref)
				return React.createElement(Component, { forwardedRef = ref })
			end)

			-- ROBLOX TODO: this is incorrect in upstream
			-- ROBLOX note: Lazy will need deeper adaptation for the Luau module system
			local LazyComponent = React.lazy(function()
				return Promise.delay(0):andThen(function()
					return { default = Component }
				end)
			end)
			-- ROBLOX FIXME: Should memo accept a LazyComponent?
			local MemoComponent = React.memo(Component :: any)
			local Context = React.createContext(false)

			jestExpect(ReactIs.isValidElementType("div")).toEqual(true)
			jestExpect(ReactIs.isValidElementType(Component)).toEqual(true)
			jestExpect(ReactIs.isValidElementType(PureComponent)).toEqual(true)
			jestExpect(ReactIs.isValidElementType(FunctionComponent)).toEqual(true)
			jestExpect(ReactIs.isValidElementType(ForwardRefComponent)).toEqual(true)
			jestExpect(ReactIs.isValidElementType(LazyComponent)).toEqual(true)
			jestExpect(ReactIs.isValidElementType(MemoComponent)).toEqual(true)
			jestExpect(ReactIs.isValidElementType(Context.Provider)).toEqual(true)
			jestExpect(ReactIs.isValidElementType(Context.Consumer)).toEqual(true)
			-- ROBLOX deviation: we don't support things that are already deprecated
			--if (!__EXPERIMENTAL__) {
			--let factory
			--jestExpect(() => {
			--factory = React.createFactory('TextLabel')
			--}).toWarnDev(
			--'Warning: React.createFactory() is deprecated and will be removed in a ' +
			--'future major release. Consider using JSX or use React.createElement() ' +
			--'directly instead.',
			--{withoutStack: true},
			--)
			--jestExpect(ReactIs.isValidElementType(factory)).toEqual(true)
			--}
			jestExpect(ReactIs.isValidElementType(React.Fragment)).toEqual(true)
			jestExpect(ReactIs.isValidElementType(React.StrictMode)).toEqual(true)
			jestExpect(ReactIs.isValidElementType(React.Suspense)).toEqual(true)
			jestExpect(ReactIs.isValidElementType(true)).toEqual(false)
			jestExpect(ReactIs.isValidElementType(123)).toEqual(false)
			jestExpect(ReactIs.isValidElementType({})).toEqual(false)
			jestExpect(ReactIs.isValidElementType(nil)).toEqual(false)
			-- ROBLOX deviation: no difference between nil and undefined in Lua
			-- jestExpect(ReactIs.isValidElementType(undefined)).toEqual(false)
			jestExpect(ReactIs.isValidElementType({ type = "TextLabel", props = {} })).toEqual(
				false
			)
		end)

		it("should identify context consumers", function()
			local Context = React.createContext(false)
			jestExpect(ReactIs.isValidElementType(Context.Consumer)).toBe(true)
			jestExpect(ReactIs.typeOf(React.createElement(Context.Consumer))).toBe(
				ReactIs.ContextConsumer
			)
			jestExpect(ReactIs.isContextConsumer(React.createElement(Context.Consumer))).toBe(
				true
			)
			jestExpect(ReactIs.isContextConsumer(React.createElement(Context.Provider))).toBe(
				false
			)
			jestExpect(ReactIs.isContextConsumer(React.createElement("div"))).toBe(false)
		end)

		it("should identify context providers", function()
			local Context = React.createContext(false)
			jestExpect(ReactIs.isValidElementType(Context.Provider)).toBe(true)
			jestExpect(ReactIs.typeOf(React.createElement(Context.Provider))).toBe(
				ReactIs.ContextProvider
			)
			jestExpect(ReactIs.isContextProvider(React.createElement(Context.Provider))).toBe(
				true
			)
			jestExpect(ReactIs.isContextProvider(React.createElement(Context.Consumer))).toBe(
				false
			)
			jestExpect(ReactIs.isContextProvider(React.createElement("div"))).toBe(false)
		end)

		it("should identify elements", function()
			jestExpect(ReactIs.typeOf(React.createElement("div"))).toBe(ReactIs.Element)
			jestExpect(ReactIs.isElement(React.createElement("div"))).toBe(true)
			jestExpect(ReactIs.isElement("div")).toBe(false)
			jestExpect(ReactIs.isElement(true)).toBe(false)
			jestExpect(ReactIs.isElement(123)).toBe(false)
			jestExpect(ReactIs.isElement(nil)).toBe(false)
			-- ROBLOX deviation: no difference between nil and undefined in Lua
			-- expect(ReactIs.isElement(undefined)).toBe(false)
			jestExpect(ReactIs.isElement({})).toBe(false)

			-- It should also identify more specific types as elements
			local Context = React.createContext(false)
			jestExpect(ReactIs.isElement(React.createElement(Context.Provider))).toBe(
				true
			)
			jestExpect(ReactIs.isElement(React.createElement(Context.Consumer))).toBe(
				true
			)
			jestExpect(ReactIs.isElement(React.createElement(React.Fragment))).toBe(true)
			jestExpect(ReactIs.isElement(React.createElement(React.StrictMode))).toBe(
				true
			)
			jestExpect(ReactIs.isElement(React.createElement(React.Suspense))).toBe(true)
		end)

		it("should identify ref forwarding component", function()
			local RefForwardingComponent = React.forwardRef(function(props, ref)
				return nil
			end)
			jestExpect(ReactIs.isValidElementType(RefForwardingComponent)).toBe(true)
			jestExpect(ReactIs.typeOf(React.createElement(RefForwardingComponent))).toBe(
				ReactIs.ForwardRef
			)
			jestExpect(ReactIs.isForwardRef(React.createElement(RefForwardingComponent))).toBe(
				true
			)
			jestExpect(ReactIs.isForwardRef({ type = ReactIs.StrictMode })).toBe(false)
			jestExpect(ReactIs.isForwardRef(React.createElement("div"))).toBe(false)
		end)

		it("should identify fragments", function()
			jestExpect(ReactIs.isValidElementType(React.Fragment)).toBe(true)
			jestExpect(ReactIs.typeOf(React.createElement(React.Fragment))).toBe(
				ReactIs.Fragment
			)
			jestExpect(ReactIs.isFragment(React.createElement(React.Fragment))).toBe(true)
			jestExpect(ReactIs.isFragment({ type = ReactIs.Fragment })).toBe(false)
			jestExpect(ReactIs.isFragment("React.Fragment")).toBe(false)
			jestExpect(ReactIs.isFragment(React.createElement("div"))).toBe(false)
			jestExpect(ReactIs.isFragment({})).toBe(false)
		end)

		it("should identify portals", function()
			local ScreenGui = Instance.new("ScreenGui")
			local portal =
				ReactRoblox.createPortal(React.createElement("Frame"), ScreenGui)
			jestExpect(ReactIs.isValidElementType(portal)).toBe(false)
			jestExpect(ReactIs.typeOf(portal)).toBe(ReactIs.Portal)
			jestExpect(ReactIs.isPortal(portal)).toBe(true)
			jestExpect(ReactIs.isPortal("Frame")).toBe(false)
		end)

		it("should identify memo", function()
			local Component = function()
				return React.createElement("div")
			end
			local Memoized = React.memo(Component)
			jestExpect(ReactIs.isValidElementType(Memoized)).toBe(true)
			jestExpect(ReactIs.typeOf(React.createElement(Memoized))).toBe(ReactIs.Memo)
			jestExpect(ReactIs.isMemo(React.createElement(Memoized))).toBe(true)
			jestExpect(ReactIs.isMemo(React.createElement(Component))).toBe(false)
		end)

		it("should identify lazy", function()
			local Component = function()
				return React.createElement("div")
			end
			-- ROBLOX TODO: this is incorrect in upstream
			local LazyComponent = React.lazy(function()
				return Promise.delay(0):andThen(function()
					return { default = Component }
				end)
			end)
			jestExpect(ReactIs.isValidElementType(LazyComponent)).toBe(true)
			jestExpect(ReactIs.typeOf(React.createElement(LazyComponent))).toBe(
				ReactIs.Lazy
			)
			jestExpect(ReactIs.isLazy(React.createElement(LazyComponent))).toBe(true)
			jestExpect(ReactIs.isLazy(React.createElement(Component))).toBe(false)
		end)

		it("should identify strict mode", function()
			jestExpect(ReactIs.isValidElementType(React.StrictMode)).toBe(true)
			jestExpect(ReactIs.typeOf(React.createElement(React.StrictMode))).toBe(
				ReactIs.StrictMode
			)
			jestExpect(ReactIs.isStrictMode(React.createElement(React.StrictMode))).toBe(
				true
			)
			jestExpect(ReactIs.isStrictMode({ type = ReactIs.StrictMode })).toBe(false)
			jestExpect(ReactIs.isStrictMode(React.createElement("div"))).toBe(false)
		end)

		it("should identify suspense", function()
			jestExpect(ReactIs.isValidElementType(React.Suspense)).toBe(true)
			jestExpect(ReactIs.typeOf(React.createElement(React.Suspense))).toBe(
				ReactIs.Suspense
			)
			jestExpect(ReactIs.isSuspense(React.createElement(React.Suspense))).toBe(true)
			jestExpect(ReactIs.isSuspense({ type = ReactIs.Suspense })).toBe(false)
			jestExpect(ReactIs.isSuspense("React.Suspense")).toBe(false)
			jestExpect(ReactIs.isSuspense(React.createElement("div"))).toBe(false)
		end)

		it("should identify profile root", function()
			jestExpect(ReactIs.isValidElementType(React.Profiler)).toBe(true)
			jestExpect(
				ReactIs.typeOf(
					React.createElement(
						React.Profiler,
						{ id = "foo", onRender = jest.fn() }
					)
				)
			).toBe(ReactIs.Profiler)
			jestExpect(
				ReactIs.isProfiler(
					React.createElement(
						React.Profiler,
						{ id = "foo", onRender = jest.fn() }
					)
				)
			).toBe(true)
			jestExpect(ReactIs.isProfiler({ type = ReactIs.Profiler })).toBe(false)
			jestExpect(ReactIs.isProfiler(React.createElement("div"))).toBe(false)
		end)

		-- ROBLOX deviation: added this test to cover deprecation warning
		it("should warn for deprecated functions", function()
			jestExpect(function()
				ReactIs.isConcurrentMode(nil)
			end).toWarnDev("deprecated", { withoutStack = true })

			jestExpect(function()
				ReactIs.isAsyncMode(nil)
			end).toWarnDev("deprecated", { withoutStack = true })
		end)

		-- ROBLOX deviation: Bindings are a feature migrated from Roact
		it("should identify bindings", function()
			local binding, _ = React.createBinding(nil)
			jestExpect(ReactIs.isBinding(binding)).toBe(true)

			local mappedBinding = React.createBinding(nil):map(tostring)
			jestExpect(ReactIs.isBinding(mappedBinding)).toBe(true)

			local joinedBinding = React.joinBindings({
				X = React.createBinding(0),
				Y = React.createBinding(0),
			})
			jestExpect(ReactIs.isBinding(joinedBinding)).toBe(true)

			-- In Roact 17, `ref` objects are implemented in terms of bindings!
			jestExpect(ReactIs.isBinding(React.createRef())).toBe(true)
		end)
	end)
end
