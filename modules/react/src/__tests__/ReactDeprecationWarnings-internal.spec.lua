-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-dom/src/__tests__/ReactDeprecationWarnings-test.internal.js
local React
local ReactFeatureFlags
local ReactNoop
local Scheduler
-- local JSXDEVRuntime
local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local describe = JestGlobals.describe
local jest = JestGlobals.jest
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach
local it = JestGlobals.it
local xit = JestGlobals.xit

describe("ReactDeprecationWarnings", function()
	beforeEach(function()
		jest.resetModules()
		React = require(script.Parent.Parent)
		ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
		ReactNoop = require(Packages.Dev.ReactNoopRenderer)
		Scheduler = require(Packages.Dev.Scheduler)
		-- if Boolean.toJSBoolean(__DEV__) then
		-- 	JSXDEVRuntime = require("react/jsx-dev-runtime")
		-- end
		ReactFeatureFlags.warnAboutDefaultPropsOnFunctionComponents = true
		ReactFeatureFlags.warnAboutStringRefs = true
	end)
	afterEach(function()
		ReactFeatureFlags.warnAboutDefaultPropsOnFunctionComponents = false
		ReactFeatureFlags.warnAboutStringRefs = false
	end)

	-- ROBLOX deviation: we already don't support defaultProps on function components
	xit("should warn when given defaultProps", function()
		local function FunctionalComponent(_props)
			return nil
		end
		-- FunctionalComponent.defaultProps = { testProp = true }
		ReactNoop.render(React.createElement(FunctionalComponent))
		jestExpect(function()
			return jestExpect(Scheduler).toFlushWithoutYielding()
		end).toErrorDev(
			"Warning: FunctionalComponent: Support for defaultProps "
				.. "will be removed from function components in a future major "
				.. "release. Use JavaScript default parameters instead."
		)
	end)
	it("should warn when given string refs", function()
		local RefComponent = React.Component:extend("RefComponent")
		function RefComponent:render()
			return nil
		end
		local Component = React.Component:extend("Component")
		function Component:render()
			return React.createElement(RefComponent, { ref = "refComponent" })
		end
		ReactNoop.render(React.createElement(Component))
		local expectedName = _G.__DEV__ and "Component"
			or "<enable __DEV__ mode for component names>"
		-- ROBLOX Test Noise: jest setup config makes this hide error
		-- boundary warnings in upstream (scripts/jest/setupTests.js:72)
		-- ROBLOX deviation: we removed string ref support ahead of upstream schedule
		jestExpect(function()
			return jestExpect(Scheduler).toFlushWithoutYielding()
		end).toThrow(
			'Component "'
				.. expectedName
				.. '" contains the string ref "refComponent". '
				.. "Support for string refs has been removed. "
				.. "We recommend using useRef() or createRef() instead. "
				.. "Learn more about using refs safely here: "
				.. "https://reactjs.org/link/strict-mode-string-ref"
			-- ROBLOX deviation: since we throw instead of warn, no stack trace in the message
			-- .. "\n    in Component (at **)"
		)
	end)
	-- ROBLOX deviation: we don't allow string refs under any circumstances
	xit("should not warn when owner and self are the same for string refs", function()
		ReactFeatureFlags.warnAboutStringRefs = false
		local RefComponent = React.Component:extend("RefComponent")
		function RefComponent:render()
			return nil
		end
		local Component = React.Component:extend("")
		function Component:render()
			return React.createElement(
				RefComponent,
				{ ref = "refComponent", __self = self }
			)
		end
		ReactNoop.renderLegacySyncRoot(React.createElement(Component))
		jestExpect(Scheduler).toFlushWithoutYielding()
	end)
	it("should warn when owner and self are different for string refs", function()
		local RefComponent = React.Component:extend("RefComponent")
		function RefComponent:render()
			return nil
		end
		local Component = React.Component:extend("Component")
		function Component:render()
			return React.createElement(
				RefComponent,
				{ ref = "refComponent", __self = {} }
			)
		end
		ReactNoop.render(React.createElement(Component))

		-- ROBLOX deviation: we removed string ref support ahead of upstream schedule
		local expectedName = _G.__DEV__ and "Component"
			or "<enable __DEV__ mode for component names>"
		-- ROBLOX Test Noise: jest setup config makes this hide error
		-- boundary warnings in upstream (scripts/jest/setupTests.js:72)
		jestExpect(function()
			return jestExpect(Scheduler).toFlushWithoutYielding()
		end).toThrow(
			'Component "'
				.. expectedName
				.. '" contains the string ref "refComponent". '
				.. "Support for string refs has been removed. "
				.. "We recommend using useRef() or createRef() instead. "
				.. "Learn more about using refs safely here: "
				.. "https://reactjs.org/link/strict-mode-string-ref"
		)
	end)

	-- ROBLOX TODO: figure out how to do this without JSX internals
	-- if _G.__DEV__ then
	-- 	xit("should warn when owner and self are different for string refs", function()
	-- 		local RefComponent = React.Component:extend("")
	-- 		RefComponent.__index = RefComponent
	-- 		function RefComponent:render()
	-- 			return nil
	-- 		end
	-- 		local Component = React.Component:extend("")
	-- 		Component.__index = Component
	-- 		function Component:render()
	-- 			-- return JSXDEVRuntime:jsxDEV(
	-- 			-- 	RefComponent,
	-- 			-- 	{ ref = "refComponent" },
	-- 			-- 	nil,
	-- 			-- 	false,
	-- 			-- 	{},
	-- 			-- 	{}
	-- 			-- )
	-- 		end
	-- 		ReactNoop.render(React.createElement(Component))
	-- 		jestExpect(function()
	-- 			return jestExpect(Scheduler).toFlushWithoutYielding()
	-- 		end).toErrorDev(
	-- 			'Warning: Component "Component" contains the string ref "refComponent". '
	-- 				.. "Support for string refs will be removed in a future major release. "
	-- 				.. "This case cannot be automatically converted to an arrow function. "
	-- 				.. "We ask you to manually fix this case by using useRef() or createRef() instead. "
	-- 				.. "Learn more about using refs safely here: "
	-- 				.. "https://reactjs.org/link/strict-mode-string-ref"
	-- 		)
	-- 	end)
	-- end
end)
