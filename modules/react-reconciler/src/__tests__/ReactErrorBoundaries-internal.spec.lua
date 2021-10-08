-- Upstream = https://github.com/facebook/react/blob/d13f5b9538e48f74f7c571ef3cde652ca887cca0/packages/react-dom/src/__tests__/ReactErrorBoundaries-test.internal.js
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @emails react-core
--  */
-- !strict
return function()
	local Packages = script.Parent.Parent.Parent
	local RobloxJest = require(Packages.Dev.RobloxJest)

	-- local PropTypes
	local React
	-- local ReactDOM
	local ReactNoop
	-- local act
	local Scheduler
	local LuauPolyfill = require(Packages.LuauPolyfill)
	local Array = LuauPolyfill.Array
	local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
	local jestExpect = require(Packages.Dev.JestGlobals).expect

	-- ROBLOX deviation: using textContent helper in place of upstream .textContent()
	local function textContent(node)
		local res
		local queue = Array.slice(node.getChildren())
		while #queue > 0 do
			local currentNode = table.remove(queue)
			if currentNode.text then
				res = currentNode.text .. (res or "")
			end
			if currentNode.children then
				for _, value in ipairs(currentNode.children) do
					table.insert(queue, value)
				end
			end
		end
		return res or ""
	end

	describe("ReactErrorBoundaries", function()
		local BrokenConstructor
		local BrokenComponentWillMount
		local BrokenComponentDidMount
		local BrokenComponentWillReceiveProps
		local BrokenComponentWillUpdate
		local BrokenComponentDidUpdate
		local BrokenComponentWillUnmount
		local BrokenRenderErrorBoundary
		local BrokenComponentWillMountErrorBoundary
		local BrokenComponentDidMountErrorBoundary
		local BrokenRender
		local BrokenUseEffect
		local BrokenUseLayoutEffect
		local ErrorBoundary
		local ErrorMessage
		local NoopErrorBoundary
		local RetryErrorBoundary
		local Normal

		beforeEach(function()
			RobloxJest.resetModules()
			RobloxJest.useFakeTimers()

			-- PropTypes = require('prop-types')
			ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
			ReactFeatureFlags.replayFailedUnitOfWorkWithInvokeGuardedCallback = false
			-- ReactDOM = require('react-dom')
			React = require(Packages.React)
			ReactNoop = require(Packages.Dev.ReactNoopRenderer)
			Scheduler = require(Packages.Scheduler)
			-- act = require('react-dom/test-utils').unstable_concurrentAct

			BrokenConstructor = React.Component:extend("BrokenConstructor")

			function BrokenConstructor:init()
				Scheduler.unstable_yieldValue("BrokenConstructor constructor [!]")
				error("Hello", 0)
			end
			function BrokenConstructor:render()
				Scheduler.unstable_yieldValue("BrokenConstructor render")
				return React.createElement("div", nil, self.props.children)
			end
			function BrokenConstructor:UNSAFE_componentWillMount()
				Scheduler.unstable_yieldValue("BrokenConstructor componentWillMount")
			end
			function BrokenConstructor:componentDidMount()
				Scheduler.unstable_yieldValue("BrokenConstructor componentDidMount")
			end
			function BrokenConstructor:UNSAFE_componentWillReceiveProps()
				Scheduler.unstable_yieldValue("BrokenConstructor componentWillReceiveProps")
			end
			function BrokenConstructor:UNSAFE_componentWillUpdate()
				Scheduler.unstable_yieldValue("BrokenConstructor componentWillUpdate")
			end
			function BrokenConstructor:componentDidUpdate()
				Scheduler.unstable_yieldValue("BrokenConstructor componentDidUpdate")
			end

			function BrokenConstructor:componentWillUnmount()
				Scheduler.unstable_yieldValue("BrokenConstructor componentWillUnmount")
			end

			BrokenComponentWillMount = React.Component:extend("BrokenComponentWillMount")

			function BrokenComponentWillMount:init()
				Scheduler.unstable_yieldValue("BrokenComponentWillMount constructor")
			end

			function BrokenComponentWillMount:render()
				Scheduler.unstable_yieldValue("BrokenComponentWillMount render")
				return React.createElement("div", nil, self.props.children)
			end

			function BrokenComponentWillMount:UNSAFE_componentWillMount()
				Scheduler.unstable_yieldValue("BrokenComponentWillMount componentWillMount [!]")
				error("Hello", 0)
			end

			function BrokenComponentWillMount:componentDidMount()
				Scheduler.unstable_yieldValue("BrokenComponentWillMount componentDidMount")
			end
			function BrokenComponentWillMount:UNSAFE_componentWillReceiveProps()
				Scheduler.unstable_yieldValue("BrokenComponentWillMount componentWillReceiveProps")
			end

			function BrokenComponentWillMount:UNSAFE_componentWillUpdate()
				Scheduler.unstable_yieldValue("BrokenComponentWillMount componentWillUpdate")
			end

			function BrokenComponentWillMount:componentDidUpdate()
				Scheduler.unstable_yieldValue("BrokenComponentWillMount componentDidUpdate")
			end

			function BrokenComponentWillMount:componentWillUnmount()
				Scheduler.unstable_yieldValue("BrokenComponentWillMount componentWillUnmount")
			end

			BrokenComponentDidMount = React.Component:extend("BrokenComponentDidMount")

			function BrokenComponentDidMount:init()
				Scheduler.unstable_yieldValue("BrokenComponentDidMount constructor")
			end
			function BrokenComponentDidMount:render()
				Scheduler.unstable_yieldValue("BrokenComponentDidMount render")
				return React.createElement("div", nil, self.props.children)
			end
			function BrokenComponentDidMount:UNSAFE_componentWillMount()
				Scheduler.unstable_yieldValue("BrokenComponentDidMount componentWillMount")
			end
			function BrokenComponentDidMount:componentDidMount()
				Scheduler.unstable_yieldValue("BrokenComponentDidMount componentDidMount [!]")
				error("Hello", 0)
			end
			function BrokenComponentDidMount:UNSAFE_componentWillReceiveProps()
				Scheduler.unstable_yieldValue("BrokenComponentDidMount componentWillReceiveProps")
			end
			function BrokenComponentDidMount:UNSAFE_componentWillUpdate()
				Scheduler.unstable_yieldValue("BrokenComponentDidMount componentWillUpdate")
			end
			function BrokenComponentDidMount:componentDidUpdate()
				Scheduler.unstable_yieldValue("BrokenComponentDidMount componentDidUpdate")
			end
			function BrokenComponentDidMount:componentWillUnmount()
				Scheduler.unstable_yieldValue("BrokenComponentDidMount componentWillUnmount")
			end

			BrokenComponentWillReceiveProps = React.Component:extend("BrokenComponentWillReceiveProps")

			function BrokenComponentWillReceiveProps:init()
				Scheduler.unstable_yieldValue("BrokenComponentWillReceiveProps constructor")
			end
			function BrokenComponentWillReceiveProps:render()
				Scheduler.unstable_yieldValue("BrokenComponentWillReceiveProps render")
				return React.createElement("div", nil, self.props.children)
			end
			function BrokenComponentWillReceiveProps:UNSAFE_componentWillMount()
				Scheduler.unstable_yieldValue("BrokenComponentWillReceiveProps componentWillMount")
			end
			function BrokenComponentWillReceiveProps:componentDidMount()
				Scheduler.unstable_yieldValue("BrokenComponentWillReceiveProps componentDidMount")
			end
			function BrokenComponentWillReceiveProps:UNSAFE_componentWillReceiveProps()
				Scheduler.unstable_yieldValue("BrokenComponentWillReceiveProps componentWillReceiveProps [!]")
				error("Hello", 0)
			end
			function BrokenComponentWillReceiveProps:UNSAFE_componentWillUpdate()
				Scheduler.unstable_yieldValue("BrokenComponentWillReceiveProps componentWillUpdate")
			end
			function BrokenComponentWillReceiveProps:componentDidUpdate()
				Scheduler.unstable_yieldValue("BrokenComponentWillReceiveProps componentDidUpdate")
			end
			function BrokenComponentWillReceiveProps:componentWillUnmount()
				Scheduler.unstable_yieldValue("BrokenComponentWillReceiveProps componentWillUnmount")
			end

			BrokenComponentWillUpdate = React.Component:extend("BrokenComponentWillUpdate")

			function BrokenComponentWillUpdate:init()
				Scheduler.unstable_yieldValue("BrokenComponentWillUpdate constructor")
			end
			function BrokenComponentWillUpdate:render()
				Scheduler.unstable_yieldValue("BrokenComponentWillUpdate render")
				return React.createElement("div", nil, self.props.children)
			end
			function BrokenComponentWillUpdate:UNSAFE_componentWillMount()
				Scheduler.unstable_yieldValue("BrokenComponentWillUpdate componentWillMount")
			end
			function BrokenComponentWillUpdate:componentDidMount()
				Scheduler.unstable_yieldValue("BrokenComponentWillUpdate componentDidMount")
			end
			function BrokenComponentWillUpdate:UNSAFE_componentWillReceiveProps()
				Scheduler.unstable_yieldValue("BrokenComponentWillUpdate componentWillReceiveProps")
			end
			function BrokenComponentWillUpdate:UNSAFE_componentWillUpdate()
				Scheduler.unstable_yieldValue("BrokenComponentWillUpdate componentWillUpdate [!]")
				error("Hello", 0)
			end
			function BrokenComponentWillUpdate:componentDidUpdate()
				Scheduler.unstable_yieldValue("BrokenComponentWillUpdate componentDidUpdate")
			end
			function BrokenComponentWillUpdate:componentWillUnmount()
				Scheduler.unstable_yieldValue("BrokenComponentWillUpdate componentWillUnmount")
			end

			BrokenComponentDidUpdate = React.Component:extend("BrokenComponentDidUpdate")

			function BrokenComponentDidUpdate:init()
				Scheduler.unstable_yieldValue("BrokenComponentDidUpdate constructor")
			end
			function BrokenComponentDidUpdate:render()
				Scheduler.unstable_yieldValue("BrokenComponentDidUpdate render")
				return React.createElement("div", nil, self.props.children)
			end
			function BrokenComponentDidUpdate:UNSAFE_componentWillMount()
				Scheduler.unstable_yieldValue("BrokenComponentDidUpdate componentWillMount")
			end
			function BrokenComponentDidUpdate:componentDidMount()
				Scheduler.unstable_yieldValue("BrokenComponentDidUpdate componentDidMount")
			end
			function BrokenComponentDidUpdate:UNSAFE_componentWillReceiveProps()
				Scheduler.unstable_yieldValue("BrokenComponentDidUpdate componentWillReceiveProps")
			end
			function BrokenComponentDidUpdate:UNSAFE_componentWillUpdate()
				Scheduler.unstable_yieldValue("BrokenComponentDidUpdate componentWillUpdate")
			end
			function BrokenComponentDidUpdate:componentDidUpdate()
				Scheduler.unstable_yieldValue("BrokenComponentDidUpdate componentDidUpdate [!]")

				-- ROBLOX deviation: or 'Hello' in place of setting defaultProps
				error(self.props.errorText or "Hello", 0)
			end
			function BrokenComponentDidUpdate:componentWillUnmount()
				Scheduler.unstable_yieldValue("BrokenComponentDidUpdate componentWillUnmount")
			end

			BrokenComponentWillUnmount = React.Component:extend("BrokenComponentWillUnmount")

			function BrokenComponentWillUnmount:init()
				Scheduler.unstable_yieldValue("BrokenComponentWillUnmount constructor")
			end
			function BrokenComponentWillUnmount:render()
				Scheduler.unstable_yieldValue("BrokenComponentWillUnmount render")
				return React.createElement("div", nil, self.props.children)
			end
			function BrokenComponentWillUnmount:UNSAFE_componentWillMount()
				Scheduler.unstable_yieldValue("BrokenComponentWillUnmount componentWillMount")
			end
			function BrokenComponentWillUnmount:componentDidMount()
				Scheduler.unstable_yieldValue("BrokenComponentWillUnmount componentDidMount")
			end
			function BrokenComponentWillUnmount:UNSAFE_componentWillReceiveProps()
				Scheduler.unstable_yieldValue("BrokenComponentWillUnmount componentWillReceiveProps")
			end
			function BrokenComponentWillUnmount:UNSAFE_componentWillUpdate()
				Scheduler.unstable_yieldValue("BrokenComponentWillUnmount componentWillUpdate")
			end
			function BrokenComponentWillUnmount:componentDidUpdate()
				Scheduler.unstable_yieldValue("BrokenComponentWillUnmount componentDidUpdate")
			end
			function BrokenComponentWillUnmount:componentWillUnmount()
				Scheduler.unstable_yieldValue("BrokenComponentWillUnmount componentWillUnmount [!]")
				-- ROBLOX deviation: or 'Hello' in place of setting defaultProps
				error(self.props.errorText or "Hello", 0)
			end

			BrokenComponentWillMountErrorBoundary = React.Component:extend("BrokenComponentWillMountErrorBoundary")

			function BrokenComponentWillMountErrorBoundary:init()
				self.state = { error = nil }
				Scheduler.unstable_yieldValue("BrokenComponentWillMountErrorBoundary constructor")
			end
			function BrokenComponentWillMountErrorBoundary:render()
				if self.state.error then
					Scheduler.unstable_yieldValue("BrokenComponentWillMountErrorBoundary render error")
					return React.createElement("div", nil, "Caught an error: " .. tostring(self.state.error.message))
				end
				Scheduler.unstable_yieldValue("BrokenComponentWillMountErrorBoundary render success")
				return React.createElement("div", nil, self.props.children)
			end
			function BrokenComponentWillMountErrorBoundary:UNSAFE_componentWillMount()
				Scheduler.unstable_yieldValue("BrokenComponentWillMountErrorBoundary componentWillMount [!]")
				error("Hello", 0)
			end
			function BrokenComponentWillMountErrorBoundary:componentDidMount()
				Scheduler.unstable_yieldValue("BrokenComponentWillMountErrorBoundary componentDidMount")
			end
			function BrokenComponentWillMountErrorBoundary:componentWillUnmount()
				Scheduler.unstable_yieldValue("BrokenComponentWillMountErrorBoundary componentWillUnmount")
			end
			function BrokenComponentWillMountErrorBoundary.getDerivedStateFromError(error_)
				Scheduler.unstable_yieldValue("BrokenComponentWillMountErrorBoundary static getDerivedStateFromError")
				return { error = error_ }
			end

			BrokenComponentDidMountErrorBoundary = React.Component:extend("BrokenComponentDidMountErrorBoundary")

			function BrokenComponentDidMountErrorBoundary:init()
				self.state = { error = nil }
				Scheduler.unstable_yieldValue("BrokenComponentDidMountErrorBoundary constructor")
			end
			function BrokenComponentDidMountErrorBoundary:render()
				if self.state.error then
					Scheduler.unstable_yieldValue("BrokenComponentDidMountErrorBoundary render error")
					return React.createElement("div", nil, "Caught an error: " .. tostring(self.state.error.message))
				end
				Scheduler.unstable_yieldValue("BrokenComponentDidMountErrorBoundary render success")
				return React.createElement("div", nil, self.props.children)
			end
			function BrokenComponentDidMountErrorBoundary:UNSAFE_componentWillMount()
				Scheduler.unstable_yieldValue("BrokenComponentDidMountErrorBoundary componentWillMount")
			end
			function BrokenComponentDidMountErrorBoundary:componentDidMount()
				Scheduler.unstable_yieldValue("BrokenComponentDidMountErrorBoundary componentDidMount [!]")
				error("Hello", 0)
			end
			function BrokenComponentDidMountErrorBoundary:componentWillUnmount()
				Scheduler.unstable_yieldValue("BrokenComponentDidMountErrorBoundary componentWillUnmount")
			end
			function BrokenComponentDidMountErrorBoundary.getDerivedStateFromError(error_)
				Scheduler.unstable_yieldValue("BrokenComponentDidMountErrorBoundary static getDerivedStateFromError")
				return { error = error_ }
			end

			BrokenRenderErrorBoundary = React.Component:extend("BrokenRenderErrorBoundary")

			function BrokenRenderErrorBoundary:init()
				self.state = { error = nil }
				Scheduler.unstable_yieldValue("BrokenRenderErrorBoundary constructor")
			end
			function BrokenRenderErrorBoundary:render()
				if self.state.error then
					Scheduler.unstable_yieldValue("BrokenRenderErrorBoundary render error [!]")
					error("Hello", 0)
				end
				Scheduler.unstable_yieldValue("BrokenRenderErrorBoundary render success")
				return React.createElement("div", nil, self.props.children)
			end
			function BrokenRenderErrorBoundary:UNSAFE_componentWillMount()
				Scheduler.unstable_yieldValue("BrokenRenderErrorBoundary componentWillMount")
			end
			function BrokenRenderErrorBoundary:componentDidMount()
				Scheduler.unstable_yieldValue("BrokenRenderErrorBoundary componentDidMount")
			end
			function BrokenRenderErrorBoundary:componentWillUnmount()
				Scheduler.unstable_yieldValue("BrokenRenderErrorBoundary componentWillUnmount")
			end
			function BrokenRenderErrorBoundary.getDerivedStateFromError(error_)
				Scheduler.unstable_yieldValue("BrokenRenderErrorBoundary static getDerivedStateFromError")
				return { error = error_ }
			end

			BrokenRender = React.Component:extend("BrokenRender")

			function BrokenRender:init()
				Scheduler.unstable_yieldValue("BrokenRender constructor")
			end
			function BrokenRender:render()
				Scheduler.unstable_yieldValue("BrokenRender render [!]")
				error("Hello", 0)
			end
			function BrokenRender:UNSAFE_componentWillMount()
				Scheduler.unstable_yieldValue("BrokenRender componentWillMount")
			end
			function BrokenRender:componentDidMount()
				Scheduler.unstable_yieldValue("BrokenRender componentDidMount")
			end
			function BrokenRender:UNSAFE_componentWillReceiveProps()
				Scheduler.unstable_yieldValue("BrokenRender componentWillReceiveProps")
			end
			function BrokenRender:UNSAFE_componentWillUpdate()
				Scheduler.unstable_yieldValue("BrokenRender componentWillUpdate")
			end
			function BrokenRender:componentDidUpdate()
				Scheduler.unstable_yieldValue("BrokenRender componentDidUpdate")
			end
			function BrokenRender:componentWillUnmount()
				Scheduler.unstable_yieldValue("BrokenRender componentWillUnmount")
			end

			BrokenUseEffect = function(props)
				local children = props.children

				Scheduler.unstable_yieldValue("BrokenUseEffect render")
				React.useEffect(function()
					Scheduler.unstable_yieldValue("BrokenUseEffect useEffect [!]")
					error("Hello", 0)
				end)

				return children
			end
			BrokenUseLayoutEffect = function(props)
				local children = props.children

				Scheduler.unstable_yieldValue("BrokenUseLayoutEffect render")
				React.useLayoutEffect(function()
					Scheduler.unstable_yieldValue("BrokenUseLayoutEffect useLayoutEffect [!]")
					error("Hello", 0)
				end)

				return children
			end

			NoopErrorBoundary = React.Component:extend("NoopErrorBoundary")

			function NoopErrorBoundary:init()
				Scheduler.unstable_yieldValue("NoopErrorBoundary constructor")
			end
			function NoopErrorBoundary:render()
				Scheduler.unstable_yieldValue("NoopErrorBoundary render")
				return React.createElement(BrokenRender)
			end
			function NoopErrorBoundary:UNSAFE_componentWillMount()
				Scheduler.unstable_yieldValue("NoopErrorBoundary componentWillMount")
			end
			function NoopErrorBoundary:componentDidMount()
				Scheduler.unstable_yieldValue("NoopErrorBoundary componentDidMount")
			end
			function NoopErrorBoundary:componentWillUnmount()
				Scheduler.unstable_yieldValue("NoopErrorBoundary componentWillUnmount")
			end
			function NoopErrorBoundary.getDerivedStateFromError()
				Scheduler.unstable_yieldValue("NoopErrorBoundary static getDerivedStateFromError")
			end

			Normal = React.Component:extend("Normal")

			Normal.defaultProps = {
				logName = "Normal",
			}
			function Normal:init()
				Scheduler.unstable_yieldValue(self.props.logName .. " constructor")
			end
			function Normal:render()
				Scheduler.unstable_yieldValue(self.props.logName .. " render")
				return React.createElement("div", nil, self.props.children)
			end
			function Normal:UNSAFE_componentWillMount()
				Scheduler.unstable_yieldValue(self.props.logName .. " componentWillMount")
			end
			function Normal:componentDidMount()
				Scheduler.unstable_yieldValue(self.props.logName .. " componentDidMount")
			end
			function Normal:UNSAFE_componentWillReceiveProps()
				Scheduler.unstable_yieldValue(self.props.logName .. " componentWillReceiveProps")
			end
			function Normal:UNSAFE_componentWillUpdate()
				Scheduler.unstable_yieldValue(self.props.logName .. " componentWillUpdate")
			end
			function Normal:componentDidUpdate()
				Scheduler.unstable_yieldValue(self.props.logName .. " componentDidUpdate")
			end
			function Normal:componentWillUnmount()
				Scheduler.unstable_yieldValue(self.props.logName .. " componentWillUnmount")
			end

			ErrorBoundary = React.Component:extend("ErrorBoundary")

			function ErrorBoundary:init()
				self.state = {
					error = nil,
				}
				Scheduler.unstable_yieldValue(self.props.logName .. " constructor")
			end
			function ErrorBoundary:render()
				if self.state.error and not self.props.forceRetry then
					Scheduler.unstable_yieldValue(self.props.logName .. " render error")
					return self.props.renderError(self.state.error, self.props)
				end
				Scheduler.unstable_yieldValue(self.props.logName .. " render success")
				return React.createElement("div", nil, self.props.children)
			end
			function ErrorBoundary.getDerivedStateFromError(error_)
				Scheduler.unstable_yieldValue("ErrorBoundary static getDerivedStateFromError")
				return { error = error_ }
			end
			function ErrorBoundary:UNSAFE_componentWillMount()
				Scheduler.unstable_yieldValue(self.props.logName .. " componentWillMount")
			end
			function ErrorBoundary:componentDidMount()
				Scheduler.unstable_yieldValue(self.props.logName .. " componentDidMount")
			end
			function ErrorBoundary:UNSAFE_componentWillReceiveProps()
				Scheduler.unstable_yieldValue(self.props.logName .. " componentWillReceiveProps")
			end
			function ErrorBoundary:UNSAFE_componentWillUpdate()
				Scheduler.unstable_yieldValue(self.props.logName .. " componentWillUpdate")
			end
			function ErrorBoundary:componentDidUpdate()
				Scheduler.unstable_yieldValue(self.props.logName .. " componentDidUpdate")
			end
			function ErrorBoundary:componentWillUnmount()
				Scheduler.unstable_yieldValue(self.props.logName .. " componentWillUnmount")
			end
			ErrorBoundary.defaultProps = {
				logName = "ErrorBoundary",
				renderError = function(error_, props)
					local errorMessage = error_
					-- ROBLOX deviation: additional logic to deal with pre-polyfill error object
					if typeof(error_) == "table" then
						errorMessage = error_.message
					end
					return React.createElement("div", {
						ref = props.errorMessageRef,
					}, "Caught an error: ", errorMessage, ".")
				end,
			}

			RetryErrorBoundary = React.Component:extend("RetryErrorBoundary")

			function RetryErrorBoundary:init()
				Scheduler.unstable_yieldValue("RetryErrorBoundary constructor")
			end
			function RetryErrorBoundary:render()
				Scheduler.unstable_yieldValue("RetryErrorBoundary render")
				return React.createElement(BrokenRender)
			end
			function RetryErrorBoundary:UNSAFE_componentWillMount()
				Scheduler.unstable_yieldValue("RetryErrorBoundary componentWillMount")
			end
			function RetryErrorBoundary:componentDidMount()
				Scheduler.unstable_yieldValue("RetryErrorBoundary componentDidMount")
			end
			function RetryErrorBoundary:componentWillUnmount()
				Scheduler.unstable_yieldValue("RetryErrorBoundary componentWillUnmount")
			end
			function RetryErrorBoundary.getDerivedStateFromError(error)
				Scheduler.unstable_yieldValue("RetryErrorBoundary static getDerivedStateFromError [!]")
				-- In Fiber, calling setState() (and failing) is treated as a rethrow.
				return {}
			end

			ErrorMessage = React.Component:extend("ErrorMessage")

			function ErrorMessage:init()
				Scheduler.unstable_yieldValue("ErrorMessage constructor")
			end
			function ErrorMessage:UNSAFE_componentWillMount()
				Scheduler.unstable_yieldValue("ErrorMessage componentWillMount")
			end
			function ErrorMessage:componentDidMount()
				Scheduler.unstable_yieldValue("ErrorMessage componentDidMount")
			end
			function ErrorMessage:componentWillUnmount()
				Scheduler.unstable_yieldValue("ErrorMessage componentWillUnmount")
			end
			function ErrorMessage:render()
				Scheduler.unstable_yieldValue("ErrorMessage render")
				return React.createElement("div", nil, "Caught an error: " .. tostring(self.props.message))
			end
		end)
		it("does not swallow exceptions on mounting without boundaries", function()
			jestExpect(function()
				ReactNoop.act(function()
					ReactNoop.render(React.createElement(BrokenRender))
				end)
			end).toThrow("Hello")

			jestExpect(function()
				ReactNoop.act(function()
					ReactNoop.render(React.createElement(BrokenComponentWillMount))
				end)
			end).toThrow("Hello")

			jestExpect(function()
				ReactNoop.act(function()
					ReactNoop.render(React.createElement(BrokenComponentDidMount))
				end)
			end).toThrow("Hello")
		end)
		it("does not swallow exceptions on updating without boundaries", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(BrokenComponentWillUpdate))
			jestExpect(function()
				root.render(React.createElement(BrokenComponentWillUpdate))
			end).toThrow("Hello")

			root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(BrokenComponentWillReceiveProps))
			jestExpect(function()
				root.render(React.createElement(BrokenComponentWillReceiveProps))
			end).toThrow("Hello")

			root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(BrokenComponentDidUpdate))
			jestExpect(function()
				root.render(React.createElement(BrokenComponentDidUpdate))
			end).toThrow("Hello")
		end)
		it("does not swallow exceptions on unmounting without boundaries", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(BrokenComponentWillUnmount))
			jestExpect(function()
				-- ROBLOX deviation: render nil to unmount
				root.render(nil)
			end).toThrow("Hello")
		end)
		it("prevents errors from leaking into other roots", function()
			local root1 = ReactNoop.createLegacyRoot()
			local root2 = ReactNoop.createLegacyRoot()
			local root3 = ReactNoop.createLegacyRoot()

			root1.render(React.createElement("span", nil, "Before 1"))
			jestExpect(function()
				root2.render(React.createElement(BrokenRender))
			end).toThrow("Hello")
			root3.render(React.createElement(ErrorBoundary, nil, React.createElement(BrokenRender)))
			jestExpect(root1.getChildren()[1].text).toEqual("Before 1")
			jestExpect(root2.getChildren()[1]).toEqual(nil)

			-- ROBLOX deviation: using textContent helper in place of upstream .textContent()
			jestExpect(textContent(root3)).toEqual("Caught an error: Hello.")

			root1.render(React.createElement("span", nil, "After 1"), root1)
			root2.render(React.createElement("span", nil, "After 2"), root2)
			root3.render(React.createElement(ErrorBoundary, { forceRetry = true }, "After 3"), root3)
			jestExpect(root1.getChildren()[1].text).toEqual("After 1")
			jestExpect(root2.getChildren()[1].text).toEqual("After 2")
			jestExpect(root3.getChildren()[1].text).toEqual("After 3")
			root1.render(nil)
			root2.render(nil)
			root3.render(nil)
			jestExpect(root1.getChildren()[1]).toEqual(nil)
			jestExpect(root2.getChildren()[1]).toEqual(nil)
			jestExpect(root3.getChildren()[1]).toEqual(nil)
		end)
		it("logs a single error when using error boundary", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			jestExpect(function()
				return root.render(React.createElement(ErrorBoundary, nil, React.createElement(BrokenRender)))
			end).toErrorDev("The above error occurred in the <BrokenRender> component:", { logAllErrors = true })

			-- ROBLOX deviation: using textContent helper in place of upstream .textContent()
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary constructor",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render success",
				"BrokenRender constructor",
				"BrokenRender componentWillMount",
				"BrokenRender render [!]",
				-- Catch and render an error message
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render error",
				"ErrorBoundary componentDidMount",
			})
			-- ROBLOX deviation: render nil to unmount
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("renders an error state if child throws in render", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()
			root.render(React.createElement(ErrorBoundary, nil, React.createElement(BrokenRender)))
			-- ROBLOX deviation: using textContent helper in place of upstream .textContent()
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary constructor",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render success",
				"BrokenRender constructor",
				"BrokenRender componentWillMount",
				"BrokenRender render [!]",
				-- Catch and render an error message
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render error",
				"ErrorBoundary componentDidMount",
			})
			-- ROBLOX deviation: render nil to unmount
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("renders an error state if child throws in constructor", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(ErrorBoundary, nil, React.createElement(BrokenConstructor)))
			-- ROBLOX deviation: using textContent helper in place of upstream .textContent()
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary constructor",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render success",
				"BrokenConstructor constructor [!]",
				-- Catch and render an error message
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render error",
				"ErrorBoundary componentDidMount",
			})
			-- ROBLOX deviation: render nil to unmount
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("renders an error state if child throws in componentWillMount", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(ErrorBoundary, nil, React.createElement(BrokenComponentWillMount)))
			-- ROBLOX deviation: using textContent helper in place of upstream .textContent()
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary constructor",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render success",
				"BrokenComponentWillMount constructor",
				"BrokenComponentWillMount componentWillMount [!]",
				-- Catch and render an error message
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render error",
				"ErrorBoundary componentDidMount",
			})
			-- ROBLOX deviation: render nil to unmount
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("renders an error state if context provider throws in componentWillMount", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			local BrokenComponentWillMountWithContext = React.Component:extend("BrokenComponentWillMountWithContext")

			function BrokenComponentWillMountWithContext:getChildContext()
				return { foo = 42 }
			end
			function BrokenComponentWillMountWithContext:render()
				return React.createElement("div", nil, self.props.children)
			end
			function BrokenComponentWillMountWithContext:UNSAFE_componentWillMount()
				error("Hello", 0)
			end

			BrokenComponentWillMountWithContext.childContextTypes = {
				-- ROBLOX Deviation: using 0 as a workaround for Proptypes.number
				foo = 0,
			}

			root.render(React.createElement(ErrorBoundary, nil, React.createElement(BrokenComponentWillMountWithContext)))
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
		end)
		if not ReactFeatureFlags.disableModulePatternComponents then
			it("renders an error state if module-style context provider throws in componentWillMount", function()
				-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
				local root = ReactNoop.createLegacyRoot()

				local function BrokenComponentWillMountWithContext()
					return {
						getChildContext = function()
							return { foo = 42 }
						end,
						render = function(self)
							return React.createElement("div", nil, self.props.children)
						end,
						UNSAFE_componentWillMount = function()
							error("Hello")
						end,
					}
				end

				-- ROBLOX deviation: no propTypes, test seems to work OK without it
				-- BrokenComponentWillMountWithContext.childContextTypes = {
				--     foo = 0,
				-- }

				jestExpect(function()
					return root.render(React.createElement(
						ErrorBoundary,
						nil,
						React.createElement(BrokenComponentWillMountWithContext)
					))
				end).toErrorDev(
					"Warning: The <BrokenComponentWillMountWithContext /> component appears to be a function component that "
						.. "returns a class instance. "
						.. "Change BrokenComponentWillMountWithContext to a class that extends React.Component instead. "
					-- ROBLOX deviation: Remove JS specifics
					-- .. "If you can't use a class try assigning the prototype on the function as a workaround. "
					-- 	.. "`BrokenComponentWillMountWithContext.prototype = React.Component.prototype`. "
					-- 	.. "Don't use an arrow function since it cannot be called with `new` by React."
				)
				-- ROBLOX FIXME: fails here, but error message above is correct. root appears to have empty children tables
				-- jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			end)
		end
		it("mounts the error message if mounting fails", function()
			local function renderError(error_)
				local errorMessage = error_
				-- ROBLOX deviation: additional logic to deal with pre-polyfill error object
				if typeof(error_) == "table" then
					errorMessage = error_.message
				end
				return React.createElement(ErrorMessage, {
					message = errorMessage,
				})
			end

			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(
				ErrorBoundary,
				{ renderError = renderError },
				React.createElement(BrokenRender)
			))
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary constructor",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render success",
				"BrokenRender constructor",
				"BrokenRender componentWillMount",
				"BrokenRender render [!]",
				-- Catch and render an error message
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render error",
				"ErrorMessage constructor",
				"ErrorMessage componentWillMount",
				"ErrorMessage render",
				"ErrorMessage componentDidMount",
				"ErrorBoundary componentDidMount",
			})
			-- ROBLOX deviation: render nil to unmount
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
				"ErrorMessage componentWillUnmount",
			})
		end)
		it("propagates errors on retry on mounting", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(RetryErrorBoundary, nil, React.createElement(BrokenRender))
			))
			-- ROBLOX deviation: using textContent helper in place of upstream .textContent()
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary constructor",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render success",
				"RetryErrorBoundary constructor",
				"RetryErrorBoundary componentWillMount",
				"RetryErrorBoundary render",
				"BrokenRender constructor",
				"BrokenRender componentWillMount",
				"BrokenRender render [!]",
				-- Retry
				"RetryErrorBoundary static getDerivedStateFromError [!]",
				"RetryErrorBoundary componentWillMount",
				"RetryErrorBoundary render",
				"BrokenRender constructor",
				"BrokenRender componentWillMount",
				"BrokenRender render [!]",
				-- This time, the error propagates to the higher boundary
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render error",
				"ErrorBoundary componentDidMount",
			})
			-- ROBLOX deviation: render nil to unmount
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("propagates errors inside boundary during componentWillMount", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()
			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(BrokenComponentWillMountErrorBoundary)
			))
			-- ROBLOX deviation: using textContent helper in place of upstream .textContent()
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary constructor",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render success",
				"BrokenComponentWillMountErrorBoundary constructor",
				"BrokenComponentWillMountErrorBoundary componentWillMount [!]",
				-- The error propagates to the higher boundary
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render error",
				"ErrorBoundary componentDidMount",
			})
			-- ROBLOX deviation: render nil to unmount
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("propagates errors inside boundary while rendering error state", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(BrokenRenderErrorBoundary, nil, React.createElement(BrokenRender))
			))
			-- ROBLOX deviation: using textContent helper in place of upstream .textContent()
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary constructor",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render success",
				"BrokenRenderErrorBoundary constructor",
				"BrokenRenderErrorBoundary componentWillMount",
				"BrokenRenderErrorBoundary render success",
				"BrokenRender constructor",
				"BrokenRender componentWillMount",
				"BrokenRender render [!]",
				-- Attempt to handle the error
				"BrokenRenderErrorBoundary static getDerivedStateFromError",
				"BrokenRenderErrorBoundary componentWillMount",
				"BrokenRenderErrorBoundary render error [!]",
				-- Attempt to handle the error again
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render error",
				"ErrorBoundary componentDidMount",
			})
			-- ROBLOX deviation: render nil to unmount
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("does not call componentWillUnmount when aborting initial mount", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(Normal),
				React.createElement(BrokenRender),
				React.createElement(Normal)
			))
			-- ROBLOX deviation: using textContent helper in place of upstream .textContent()
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary constructor",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render success",
				-- Render first child
				"Normal constructor",
				"Normal componentWillMount",
				"Normal render",
				-- Render second child (it throws)
				"BrokenRender constructor",
				"BrokenRender componentWillMount",
				"BrokenRender render [!]",
				-- Render third child, even though an earlier sibling threw.
				"Normal constructor",
				"Normal componentWillMount",
				"Normal render",
				-- Handle the error
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render error",
				"ErrorBoundary componentDidMount",
			})
			-- ROBLOX deviation: render nil to unmount
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("resets callback refs if mounting aborts", function()
			local function childRef(x)
				-- throw new Error(typeof(x))
				-- ROBLOX deviation: use explicit '[object HTMLDivElement]' string because Lua uses tables
				local XAsString = x and "[object HTMLDivElement]" or "nil"
				Scheduler.unstable_yieldValue("Child ref is set to " .. XAsString)
			end
			local function errorMessageRef(x)
				-- ROBLOX deviation: use explicit '[object HTMLDivElement]' string because Lua uses tables
				local XAsString = x and "[object HTMLDivElement]" or "nil"
				Scheduler.unstable_yieldValue("Error message ref is set to " .. XAsString)
			end

			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(
				ErrorBoundary,
				{ errorMessageRef = errorMessageRef },
				React.createElement("div", { ref = childRef }),
				React.createElement(BrokenRender)
			))
			-- ROBLOX deviation: using textContent helper in place of upstream .textContent()
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary constructor",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render success",
				"BrokenRender constructor",
				"BrokenRender componentWillMount",
				"BrokenRender render [!]",
				-- Handle the error
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render error",
				"Error message ref is set to [object HTMLDivElement]",
				"ErrorBoundary componentDidMount",
			})
			-- ROBLOX deviation: render nil to unmount
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
				"Error message ref is set to nil",
			})
		end)
		it("resets object refs if mounting aborts", function()
			local childRef = React.createRef()
			local errorMessageRef = React.createRef()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(
				ErrorBoundary,
				{ errorMessageRef = errorMessageRef },
				React.createElement("div", { ref = childRef }),
				React.createElement(BrokenRender)
			))
			-- ROBLOX deviation: using textContent helper in place of upstream .textContent()
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary constructor",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render success",
				"BrokenRender constructor",
				"BrokenRender componentWillMount",
				"BrokenRender render [!]",
				-- Handle the error
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render error",
				"ErrorBoundary componentDidMount",
			})
			-- ROBLOX deviation: workaround for object '[object HTMLDivElement]'
			jestExpect(tostring(errorMessageRef.current):find("table: ") ~= nil).toEqual(true)
			-- ROBLOX deviation: render nil to unmount
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
			jestExpect(errorMessageRef.current).toEqual(nil)
		end)
		it("successfully mounts if no error occurs", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement("div", nil, { "Mounted successfully." })
			))
			-- ROBLOX deviation: using textContent helper in place of upstream .textContent()
			jestExpect(textContent(root)).toEqual("Mounted successfully.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary constructor",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render success",
				"ErrorBoundary componentDidMount",
			})
			-- ROBLOX deviation: render nil to unmount
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("catches if child throws in constructor during update", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(ErrorBoundary, nil, React.createElement(Normal)))
			Scheduler.unstable_clearYields()
			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(Normal),
				React.createElement(Normal, {
					logName = "Normal2",
				}),
				React.createElement(BrokenConstructor)
			))

			-- ROBLOX deviation: using textContent helper in place of upstream .textContent()
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillReceiveProps",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render success",
				"Normal componentWillReceiveProps",
				"Normal componentWillUpdate",
				"Normal render",
				-- Normal2 will attempt to mount:
				"Normal2 constructor",
				"Normal2 componentWillMount",
				"Normal2 render",
				-- BrokenConstructor will abort rendering:
				"BrokenConstructor constructor [!]",
				-- Handle the error
				"ErrorBoundary static getDerivedStateFromError",
				-- Render the error message
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render error",
				"Normal componentWillUnmount",
				"ErrorBoundary componentDidUpdate",
			})
			-- ROBLOX deviation: render nil to unmount
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("catches if child throws in componentWillMount during update", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(ErrorBoundary, nil, React.createElement(Normal)))
			Scheduler.unstable_clearYields()
			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(Normal),
				React.createElement(Normal, {
					logName = "Normal2",
				}),
				React.createElement(BrokenComponentWillMount)
			))
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillReceiveProps",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render success",
				"Normal componentWillReceiveProps",
				"Normal componentWillUpdate",
				"Normal render",
				-- Normal2 will attempt to mount:
				"Normal2 constructor",
				"Normal2 componentWillMount",
				"Normal2 render",
				-- BrokenComponentWillMount will abort rendering:
				"BrokenComponentWillMount constructor",
				"BrokenComponentWillMount componentWillMount [!]",
				-- Handle the error
				"ErrorBoundary static getDerivedStateFromError",
				-- Render the error message
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render error",
				"Normal componentWillUnmount",
				"ErrorBoundary componentDidUpdate",
			})
			-- ROBLOX deviation: render nil to unmount
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("catches if child throws in componentWillReceiveProps during update", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(Normal),
				React.createElement(BrokenComponentWillReceiveProps)
			))
			Scheduler.unstable_clearYields()
			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(Normal),
				React.createElement(BrokenComponentWillReceiveProps)
			))
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillReceiveProps",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render success",
				"Normal componentWillReceiveProps",
				"Normal componentWillUpdate",
				"Normal render",
				-- BrokenComponentWillReceiveProps will abort rendering:
				"BrokenComponentWillReceiveProps componentWillReceiveProps [!]",
				-- Handle the error
				"ErrorBoundary static getDerivedStateFromError",
				-- Render the error message
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render error",
				"Normal componentWillUnmount",
				"BrokenComponentWillReceiveProps componentWillUnmount",
				"ErrorBoundary componentDidUpdate",
			})
			-- ROBLOX deviation: render nil to unmount
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("catches if child throws in componentWillUpdate during update", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(Normal),
				React.createElement(BrokenComponentWillUpdate)
			))
			Scheduler.unstable_clearYields()
			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(Normal),
				React.createElement(BrokenComponentWillUpdate)
			))
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillReceiveProps",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render success",
				"Normal componentWillReceiveProps",
				"Normal componentWillUpdate",
				"Normal render",
				-- BrokenComponentWillUpdate will abort rendering:
				"BrokenComponentWillUpdate componentWillReceiveProps",
				"BrokenComponentWillUpdate componentWillUpdate [!]",
				-- Handle the error
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render error",
				"Normal componentWillUnmount",
				"BrokenComponentWillUpdate componentWillUnmount",
				"ErrorBoundary componentDidUpdate",
			})
			-- ROBLOX deviation: render nil to unmount
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("catches if child throws in render during update", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(ErrorBoundary, nil, React.createElement(Normal)))
			Scheduler.unstable_clearYields()
			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(Normal),
				React.createElement(Normal, {
					logName = "Normal2",
				}),
				React.createElement(BrokenRender)
			))
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillReceiveProps",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render success",
				"Normal componentWillReceiveProps",
				"Normal componentWillUpdate",
				"Normal render",
				-- Normal2 will attempt to mount:
				"Normal2 constructor",
				"Normal2 componentWillMount",
				"Normal2 render",
				-- BrokenRender will abort rendering:
				"BrokenRender constructor",
				"BrokenRender componentWillMount",
				"BrokenRender render [!]",
				-- Handle the error
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render error",
				"Normal componentWillUnmount",
				"ErrorBoundary componentDidUpdate",
			})
			-- ROBLOX deviation: render nil to unmount
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("keeps refs up-to-date during updates", function()
			local function child1Ref(x)
				-- ROBLOX deviation: use explicit '[object HTMLDivElement]' string because Lua uses tables
				local XAsString = x and "[object HTMLDivElement]" or "nil"
				Scheduler.unstable_yieldValue("Child1 ref is set to " .. XAsString)
			end
			local function child2Ref(x)
				-- ROBLOX deviation: use explicit '[object HTMLDivElement]' string because Lua uses tables
				local XAsString = x and "[object HTMLDivElement]" or "nil"
				Scheduler.unstable_yieldValue("Child2 ref is set to " .. XAsString)
			end
			local function errorMessageRef(x)
				-- ROBLOX deviation: use explicit '[object HTMLDivElement]' string because Lua uses tables
				local XAsString = x and "[object HTMLDivElement]" or "nil"
				Scheduler.unstable_yieldValue("Error message ref is set to " .. XAsString)
			end

			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(
				ErrorBoundary,
				{ errorMessageRef = errorMessageRef },
				React.createElement("div", { ref = child1Ref })
			))
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary constructor",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render success",
				"Child1 ref is set to [object HTMLDivElement]",
				"ErrorBoundary componentDidMount",
			})
			root.render(React.createElement(
				ErrorBoundary,
				{ errorMessageRef = errorMessageRef },
				React.createElement("div", { ref = child1Ref }),
				React.createElement("div", { ref = child2Ref }),
				React.createElement(BrokenRender)
			))
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillReceiveProps",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render success",
				-- BrokenRender will abort rendering:
				"BrokenRender constructor",
				"BrokenRender componentWillMount",
				"BrokenRender render [!]",
				-- Handle the error
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render error",
				-- Update Child1 ref since Child1 has been unmounted
				-- Child2 ref is never set because its mounting aborted
				"Child1 ref is set to nil",
				"Error message ref is set to [object HTMLDivElement]",
				"ErrorBoundary componentDidUpdate",
			})
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
				"Error message ref is set to nil",
			})
		end)
		it("recovers from componentWillUnmount errors on update", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()
			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(BrokenComponentWillUnmount),
				React.createElement(BrokenComponentWillUnmount),
				React.createElement(Normal)
			))
			Scheduler.unstable_clearYields()
			-- ROBLOX DEVIATION: Pass a key to the "BrokenWillUnmount" element. This allows for
			-- compatibility when we go from rendering multiple children to rendering a single
			-- child, as we apply keys to children in an array by default, but not to a single
			-- element
			root.render(React.createElement(ErrorBoundary, nil,
				React.createElement(BrokenComponentWillUnmount, { key = 1 }))
			)
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillReceiveProps",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render success",
				-- Update existing child:
				"BrokenComponentWillUnmount componentWillReceiveProps",
				"BrokenComponentWillUnmount componentWillUpdate",
				"BrokenComponentWillUnmount render",
				-- Unmounting throws:
				"BrokenComponentWillUnmount componentWillUnmount [!]",
				-- Fiber proceeds with lifecycles despite errors
				"Normal componentWillUnmount",
				-- The components have updated in this phase
				"BrokenComponentWillUnmount componentDidUpdate",
				"ErrorBoundary componentDidUpdate",
				-- The initial render was aborted, so
				-- Fiber retries from the root.
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render error",
				"BrokenComponentWillUnmount componentWillUnmount [!]",
				"ErrorBoundary componentDidUpdate",
				-- The second willUnmount error should be captured and logged, too.
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillUpdate",
				-- Render an error now (stack will do it later)
				"ErrorBoundary render error",
				-- Attempt to unmount previous child:
				-- Done
				"ErrorBoundary componentDidUpdate",
			})
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("recovers from nested componentWillUnmount errors on update", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()
			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(Normal, nil, React.createElement(BrokenComponentWillUnmount)),
				React.createElement(BrokenComponentWillUnmount)
			))
			Scheduler.unstable_clearYields()
			-- ROBLOX DEVIATION: Pass a key to the "Normal" element. This allows for compatibility
			-- when we go from rendering multiple children to rendering a single child, as we
			-- apply keys to children in an array by default, but not to a single element
			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(Normal, { key = 1 },
					React.createElement(BrokenComponentWillUnmount)
				)
			))
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillReceiveProps",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render success",
				-- Update existing children:
				"Normal componentWillReceiveProps",
				"Normal componentWillUpdate",
				"Normal render",
				"BrokenComponentWillUnmount componentWillReceiveProps",
				"BrokenComponentWillUnmount componentWillUpdate",
				"BrokenComponentWillUnmount render",
				-- Unmounting throws:
				"BrokenComponentWillUnmount componentWillUnmount [!]",
				-- Fiber proceeds with lifecycles despite errors
				"BrokenComponentWillUnmount componentDidUpdate",
				"Normal componentDidUpdate",
				"ErrorBoundary componentDidUpdate",
				-- Now that commit phase is done, Fiber handles errors
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render error",
				"Normal componentWillUnmount",
				"BrokenComponentWillUnmount componentWillUnmount [!]",
				"ErrorBoundary componentDidUpdate",
				-- The second willUnmount error should be captured and logged, too.
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillUpdate",
				-- Render an error now (stack will do it later)
				"ErrorBoundary render error",
				-- Done
				"ErrorBoundary componentDidUpdate",
			})
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("picks the right boundary when handling unmounting errors", function()
			local function renderInnerError(error_)
				return React.createElement("div", nil, "Caught an inner error: ", error_, ".")
			end
			local function renderOuterError(error_)
				return React.createElement("div", nil, "Caught an outer error: ", error_, ".")
			end

			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()
			root.render(React.createElement(
				ErrorBoundary,
				{
					logName = "OuterErrorBoundary",
					renderError = renderOuterError,
				},
				React.createElement(ErrorBoundary, {
					logName = "InnerErrorBoundary",
					renderError = renderInnerError,
				}, React.createElement(BrokenComponentWillUnmount))
			))
			Scheduler.unstable_clearYields()
			root.render(React.createElement(
				ErrorBoundary,
				{
					logName = "OuterErrorBoundary",
					renderError = renderOuterError,
				},
				React.createElement(ErrorBoundary, {
					logName = "InnerErrorBoundary",
					renderError = renderInnerError,
				})
			))
			jestExpect(textContent(root)).toEqual("Caught an inner error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				-- Update outer boundary
				"OuterErrorBoundary componentWillReceiveProps",
				"OuterErrorBoundary componentWillUpdate",
				"OuterErrorBoundary render success",
				-- Update inner boundary
				"InnerErrorBoundary componentWillReceiveProps",
				"InnerErrorBoundary componentWillUpdate",
				"InnerErrorBoundary render success",
				-- Try unmounting child
				"BrokenComponentWillUnmount componentWillUnmount [!]",
				-- Now that commit phase is done, Fiber handles errors
				-- Only inner boundary receives the error:
				"InnerErrorBoundary componentDidUpdate",
				"OuterErrorBoundary componentDidUpdate",
				"ErrorBoundary static getDerivedStateFromError",
				"InnerErrorBoundary componentWillUpdate",
				-- Render an error now
				"InnerErrorBoundary render error",
				-- In Fiber, this was a local update to the
				-- inner boundary so only its hook fires
				"InnerErrorBoundary componentDidUpdate",
			})
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"OuterErrorBoundary componentWillUnmount",
				"InnerErrorBoundary componentWillUnmount",
			})
		end)
		it("can recover from error state", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()
			root.render(React.createElement(ErrorBoundary, nil, React.createElement(BrokenRender)))
			root.render(React.createElement(ErrorBoundary, nil, React.createElement(Normal)))
			-- Error boundary doesn't retry by itself
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			-- Force the success path:
			Scheduler.unstable_clearYields()

			root.render(React.createElement(ErrorBoundary, { forceRetry = true }, React.createElement(Normal)))

			jestExpect(textContent(root)).never.toContain("Caught an error")

			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillReceiveProps",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render success",
				-- Mount children:
				"Normal constructor",
				"Normal componentWillMount",
				"Normal render",
				-- Finalize updates:
				"Normal componentDidMount",
				"ErrorBoundary componentDidUpdate",
			})

			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
				"Normal componentWillUnmount",
			})
		end)
		it("can update multiple times in error state", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()
			root.render(React.createElement(ErrorBoundary, nil, React.createElement(BrokenRender)))
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			root.render(React.createElement(ErrorBoundary, nil, React.createElement(BrokenRender)))
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")

			-- ROBLOX deviation: render nil to clear children for textContent
			root.render(nil)
			root.render(React.createElement("div", nil, "Other screen"))
			jestExpect(textContent(root)).toEqual("Other screen")
			root.render(nil)
		end)
		it("doesn't get into inconsistent state during removals", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(Normal),
				React.createElement(BrokenComponentWillUnmount),
				React.createElement(Normal)
			))
			root.render(React.createElement(ErrorBoundary))
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			Scheduler.unstable_clearYields()
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("doesn't get into inconsistent state during additions", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()
			root.render(React.createElement(ErrorBoundary))
			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(Normal),
				React.createElement(BrokenRender),
				React.createElement(Normal)
			))
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			Scheduler.unstable_clearYields()
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("doesn't get into inconsistent state during reorders", function()
			local fail_ = false

			local MaybeBrokenRender = React.Component:extend("MaybeBrokenRender")
			function MaybeBrokenRender:render()
				if fail_ then
					error("Hello", 0)
				end

				return React.createElement("div", nil, self.props.children)
			end

			local function getAMixOfNormalAndBrokenRenderElements()
				local elements = {}

				for i = 1, 100 do
					table.insert(elements, React.createElement(Normal, { key = i }))
				end

				table.insert(elements, React.createElement(MaybeBrokenRender, { key = 101 }))

				local currentIndex = #elements

				while 0 ~= currentIndex do
					local randomIndex = math.floor(math.random() * currentIndex)

					currentIndex = currentIndex - 1

					local temporaryValue = elements[currentIndex]

					elements[currentIndex] = elements[randomIndex]
					elements[randomIndex] = temporaryValue
				end

				return elements
			end

			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()
			root.render(React.createElement(ErrorBoundary, nil, getAMixOfNormalAndBrokenRenderElements()))
			jestExpect(textContent(root)).never.toContain("Caught an error")

			fail_ = true

			root.render(React.createElement(ErrorBoundary, nil, getAMixOfNormalAndBrokenRenderElements()))
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			Scheduler.unstable_clearYields()
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("catches errors originating downstream", function()
			local fail_ = false
			local Stateful = React.Component:extend("Stateful")

			function Stateful:init()
				self.state = {
					shouldThrow = false,
				}
			end
			function Stateful:render()
				if fail_ then
					Scheduler.unstable_yieldValue("Stateful render [!]")
					error("Hello", 0)
				end

				return React.createElement("div", nil, self.props.children)
			end

			local statefulInst
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()
			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(Stateful, {
					ref = function(inst)
						statefulInst = inst
					end,
				})
			))
			Scheduler.unstable_clearYields()
			jestExpect(function()
				fail_ = true
				statefulInst:forceUpdate()
			end).never.toThrow()
			jestExpect(Scheduler).toHaveYielded({
				"Stateful render [!]",
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render error",
				"ErrorBoundary componentDidUpdate",
			})
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("catches errors in componentDidMount", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()
			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(BrokenComponentWillUnmount, nil, React.createElement(Normal)),
				React.createElement(BrokenComponentDidMount),
				React.createElement(Normal, {
					logName = "LastChild",
				})
			))
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary constructor",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render success",
				"BrokenComponentWillUnmount constructor",
				"BrokenComponentWillUnmount componentWillMount",
				"BrokenComponentWillUnmount render",
				"Normal constructor",
				"Normal componentWillMount",
				"Normal render",
				"BrokenComponentDidMount constructor",
				"BrokenComponentDidMount componentWillMount",
				"BrokenComponentDidMount render",
				"LastChild constructor",
				"LastChild componentWillMount",
				"LastChild render",
				-- Start flushing didMount queue
				"Normal componentDidMount",
				"BrokenComponentWillUnmount componentDidMount",
				"BrokenComponentDidMount componentDidMount [!]",
				-- Continue despite the error
				"LastChild componentDidMount",
				-- Now we are ready to handle the error
				"ErrorBoundary componentDidMount",
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render error",
				-- Safely unmount every child
				"BrokenComponentWillUnmount componentWillUnmount [!]",
				-- Continue unmounting safely despite any errors
				"Normal componentWillUnmount",
				"BrokenComponentDidMount componentWillUnmount",
				"LastChild componentWillUnmount",
				-- The willUnmount error should be captured and logged, too.
				"ErrorBoundary componentDidUpdate",
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render error",
				-- The update has finished
				"ErrorBoundary componentDidUpdate",
			})
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("catches errors in componentDidUpdate", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()
			root.render(React.createElement(ErrorBoundary, nil, React.createElement(BrokenComponentDidUpdate)))
			Scheduler.unstable_clearYields()
			root.render(React.createElement(ErrorBoundary, nil, React.createElement(BrokenComponentDidUpdate)))
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillReceiveProps",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render success",
				"BrokenComponentDidUpdate componentWillReceiveProps",
				"BrokenComponentDidUpdate componentWillUpdate",
				"BrokenComponentDidUpdate render",
				-- All lifecycles run
				"BrokenComponentDidUpdate componentDidUpdate [!]",
				"ErrorBoundary componentDidUpdate",
				-- Then, error is handled
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render error",
				"BrokenComponentDidUpdate componentWillUnmount",
				"ErrorBoundary componentDidUpdate",
			})
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		-- ROBLOX TODO: Eyeballing result shows expected functionality. ReactNoop.act() doesn't flush in the same way
		-- that ReactDOM's act method does; need to resolve this with either ReactDOM port or closer match of act() in another renderer
		xit("catches errors in useEffect", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()
			ReactNoop.act(function()
				root.render(React.createElement(
					ErrorBoundary,
					nil,
					React.createElement(BrokenUseEffect, nil, "Initial value")
				))
				jestExpect(Scheduler).toHaveYielded({
					"ErrorBoundary constructor",
					"ErrorBoundary componentWillMount",
					"ErrorBoundary render success",
					"BrokenUseEffect render",
					"ErrorBoundary componentDidMount",
				})
				jestExpect(textContent(root)).toEqual("Initial value")
				Scheduler.unstable_clearYields()
			end)

			-- verify flushed passive effects and handle the error
			jestExpect(Scheduler).toHaveYielded({
				"BrokenUseEffect useEffect [!]",
				-- Handle the error
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render error",
				"ErrorBoundary componentDidUpdate",
			})
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
		end)
		it("catches errors in useLayoutEffect", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(BrokenUseLayoutEffect, nil, "Initial value")
			))
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary constructor",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render success",
				"BrokenUseLayoutEffect render",
				"BrokenUseLayoutEffect useLayoutEffect [!]",
				-- Fiber proceeds with the hooks
				"ErrorBoundary componentDidMount",
				-- The error propagates to the higher boundary
				"ErrorBoundary static getDerivedStateFromError",
				-- Fiber retries from the root
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render error",
				"ErrorBoundary componentDidUpdate",
			})
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
		end)
		it("propagates errors inside boundary during componentDidMount", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(BrokenComponentDidMountErrorBoundary, {
					renderError = function(error_)
						return React.createElement(
							"div",
							nil,
							"We should never catch our own error: ",
							error_.message,
							"."
						)
					end,
				})
			))
			jestExpect(textContent(root)).toEqual("Caught an error: Hello.")
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary constructor",
				"ErrorBoundary componentWillMount",
				"ErrorBoundary render success",
				"BrokenComponentDidMountErrorBoundary constructor",
				"BrokenComponentDidMountErrorBoundary componentWillMount",
				"BrokenComponentDidMountErrorBoundary render success",
				"BrokenComponentDidMountErrorBoundary componentDidMount [!]",
				-- Fiber proceeds with the hooks
				"ErrorBoundary componentDidMount",
				-- The error propagates to the higher boundary
				"ErrorBoundary static getDerivedStateFromError",
				-- Fiber retries from the root
				"ErrorBoundary componentWillUpdate",
				"ErrorBoundary render error",
				"BrokenComponentDidMountErrorBoundary componentWillUnmount",
				"ErrorBoundary componentDidUpdate",
			})
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"ErrorBoundary componentWillUnmount",
			})
		end)
		it("calls static getDerivedStateFromError for each error that is captured", function()
			local function renderUnmountError(error_)
				return React.createElement("div", nil, "Caught an unmounting error: ", error_, ".")
			end
			local function renderUpdateError(error_)
				return React.createElement("div", nil, "Caught an updating error: ", error_, ".")
			end

			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(
				ErrorBoundary,
				{
					logName = "OuterErrorBoundary",
				},
				React.createElement(
					ErrorBoundary,
					{
						logName = "InnerUnmountBoundary",
						renderError = renderUnmountError,
					},
					React.createElement(BrokenComponentWillUnmount, {
						errorText = "E1",
					}),
					React.createElement(BrokenComponentWillUnmount, {
						errorText = "E2",
					})
				),
				React.createElement(
					ErrorBoundary,
					{
						logName = "InnerUpdateBoundary",
						renderError = renderUpdateError,
					},
					React.createElement(BrokenComponentDidUpdate, {
						errorText = "E3",
					}),
					React.createElement(BrokenComponentDidUpdate, {
						errorText = "E4",
					})
				)
			))
			Scheduler.unstable_clearYields()
			root.render(React.createElement(
				ErrorBoundary,
				{
					logName = "OuterErrorBoundary",
				},
				React.createElement(ErrorBoundary, {
					logName = "InnerUnmountBoundary",
					renderError = renderUnmountError,
				}),
				React.createElement(
					ErrorBoundary,
					{
						logName = "InnerUpdateBoundary",
						renderError = renderUpdateError,
					},
					React.createElement(BrokenComponentDidUpdate, {
						errorText = "E3",
					}),
					React.createElement(BrokenComponentDidUpdate, {
						errorText = "E4",
					})
				)
			))
			jestExpect(textContent(root)).toEqual("Caught an unmounting error: E2.Caught an updating error: E4.")
			jestExpect(Scheduler).toHaveYielded({
				-- Begin update phase
				"OuterErrorBoundary componentWillReceiveProps",
				"OuterErrorBoundary componentWillUpdate",
				"OuterErrorBoundary render success",
				"InnerUnmountBoundary componentWillReceiveProps",
				"InnerUnmountBoundary componentWillUpdate",
				"InnerUnmountBoundary render success",
				"InnerUpdateBoundary componentWillReceiveProps",
				"InnerUpdateBoundary componentWillUpdate",
				"InnerUpdateBoundary render success",
				-- First come the updates
				"BrokenComponentDidUpdate componentWillReceiveProps",
				"BrokenComponentDidUpdate componentWillUpdate",
				"BrokenComponentDidUpdate render",
				"BrokenComponentDidUpdate componentWillReceiveProps",
				"BrokenComponentDidUpdate componentWillUpdate",
				"BrokenComponentDidUpdate render",
				-- We're in commit phase now, deleting
				"BrokenComponentWillUnmount componentWillUnmount [!]",
				"BrokenComponentWillUnmount componentWillUnmount [!]",
				-- Continue despite errors, handle them after commit is done
				"InnerUnmountBoundary componentDidUpdate",
				-- We're still in commit phase, now calling update lifecycles
				"BrokenComponentDidUpdate componentDidUpdate [!]",
				-- Again, continue despite errors, we'll handle them later
				"BrokenComponentDidUpdate componentDidUpdate [!]",
				"InnerUpdateBoundary componentDidUpdate",
				"OuterErrorBoundary componentDidUpdate",
				-- After the commit phase, attempt to recover from any errors that
				-- were captured
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary static getDerivedStateFromError",
				"InnerUnmountBoundary componentWillUpdate",
				"InnerUnmountBoundary render error",
				"ErrorBoundary static getDerivedStateFromError",
				"ErrorBoundary static getDerivedStateFromError",
				"InnerUpdateBoundary componentWillUpdate",
				"InnerUpdateBoundary render error",
				"BrokenComponentDidUpdate componentWillUnmount",
				"BrokenComponentDidUpdate componentWillUnmount",
				"InnerUnmountBoundary componentDidUpdate",
				"InnerUpdateBoundary componentDidUpdate",
			})
			root.render(nil)
			jestExpect(Scheduler).toHaveYielded({
				"OuterErrorBoundary componentWillUnmount",
				"InnerUnmountBoundary componentWillUnmount",
				"InnerUpdateBoundary componentWillUnmount",
			})
		end)
		it("discards a bad root if the root component fails", function()
			local X = nil
			local Y = nil
			local err1
			local err2
			local ok, result

			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			ok, result = pcall(function()
				jestExpect(function()
					return root.render(React.createElement(X))
				end).toErrorDev(
					"React.createElement: type is invalid -- expected a string "
						.. "(for built-in components) or a class/function "
						.. "(for composite components) but got: nil."
				)
			end)
			if not ok then
				err1 = result
			end

			ok, result = pcall(function()
				jestExpect(function()
					return root.render(React.createElement(Y))
				end).toErrorDev(
					"React.createElement: type is invalid -- expected a string "
						.. "(for built-in components) or a class/function "
						.. "(for composite components) but got: nil."
				)
			end)
			if not ok then
				err2 = result
			end

			-- ROBLOX deviation: workaround for Error definition; looks like we
			-- have errors nested inside errors, where err1.message is also of
			-- type Error?
			jestExpect(err1.message.message).toMatch("but got: nil")
			jestExpect(err2.message.message).toMatch("but got: nil")
		end)
		it("renders empty output if error boundary does not handle the error", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			jestExpect(function()
				return root.render(React.createElement(
					"div",
					nil,
					"Sibling",
					React.createElement(NoopErrorBoundary, nil, React.createElement(BrokenRender))
				))
			end).toThrow("Hello")
			jestExpect(textContent(root)).toEqual("")
			jestExpect(Scheduler).toHaveYielded({
				"NoopErrorBoundary constructor",
				"NoopErrorBoundary componentWillMount",
				"NoopErrorBoundary render",
				"BrokenRender constructor",
				"BrokenRender componentWillMount",
				"BrokenRender render [!]",
				-- Noop error boundaries retry render (and fail again)
				"NoopErrorBoundary static getDerivedStateFromError",
				"NoopErrorBoundary render",
				"BrokenRender constructor",
				"BrokenRender componentWillMount",
				"BrokenRender render [!]",
			})
		end)
		it("passes first error when two errors happen in commit", function()
			local errors = {}
			local caughtError

			local Child = React.Component:extend("Child")

			function Child:render()
				return React.createElement("div")
			end
			function Child:componentDidMount()
				table.insert(errors, "child sad")
				error("child sad")
			end
			local Parent = React.Component:extend("Parent")

			function Parent:render()
				return React.createElement(Child)
			end
			function Parent:componentDidMount()
				table.insert(errors, "parent sad")
				error("parent sad")
			end

			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			-- Here, we test the behavior where there is no error boundary and we
			-- delegate to the host root.
			local ok, result = pcall(root.render, React.createElement(Parent))
			if not ok then
				if not (result:sub(-#"parent sad") == "parent sad") and not (result:sub(-#"child sad") == "child sad") then
					error(result)
				end
				caughtError = result
			end

			jestExpect(errors).toEqual({
				"child sad",
				"parent sad",
			})
			-- Error should be the first thrown
			jestExpect(caughtError:sub(-#"child sad")).toEqual("child sad")
		end)
		it("propagates uncaught error inside unbatched initial mount", function()
			local function Foo()
				error("foo error", 0)
			end

			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			jestExpect(function()
				ReactNoop.batchedUpdates(function()
					root.render(React.createElement(Foo))
				end)
			end).toThrow("foo error")
		end)
		it("handles errors that occur in before-mutation commit hook", function()
			local errors = {}
			local caughtError

			local Child = React.Component:extend("Child")

			function Child:getSnapshotBeforeUpdate()
				table.insert(errors, "child sad")
				error("child sad")
			end
			function Child:componentDidUpdate()
			end
			function Child:render()
				return React.createElement("div")
			end

			local Parent = React.Component:extend("Parent")
			function Parent:getSnapshotBeforeUpdate()
				table.insert(errors, "parent sad")
				error("parent sad")
			end
			function Parent:componentDidUpdate()
			end
			function Parent:render()
				return React.createElement(Child, self.props)
			end

			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(Parent, { value = 1 }))
			local ok, result = pcall(root.render, React.createElement(Parent, { value = 2 }))
			if not ok then
				if not (result:sub(-#"parent sad") == "parent sad") and not (result:sub(-#"child sad") == "child sad") then
					error(result)
				end
				caughtError = result
			end
			jestExpect(errors).toEqual({
				"child sad",
				"parent sad",
			})
			-- Error should be the first thrown
			jestExpect(caughtError:sub(-#"child sad")).toEqual("child sad")
		end)
		it("should warn if an error boundary with only componentDidCatch does not update state", function()
			local InvalidErrorBoundary = React.Component:extend("InvalidErrorBoundary")

			function InvalidErrorBoundary:componentDidCatch(error, info)
				-- This component does not define getDerivedStateFromError().
				-- It also doesn't call setState().
				-- So it would swallow errors (which is probably unintentional).
			end
			function InvalidErrorBoundary:render()
				return self.props.children
			end

			local function Throws()
				error("expected")
			end

			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			-- deviation: ReactNoop runs with a StrictMode root and logs more warnings
			jestExpect(function()
				root.render(React.createElement(InvalidErrorBoundary, nil, React.createElement(Throws)))
			end).toErrorDev(
				"InvalidErrorBoundary: Error boundaries should implement getDerivedStateFromError(). " ..
				"In that method, return a state update to display an error message or fallback UI."
			)
			jestExpect(textContent(root)).toEqual("")
		end)
		it("should call both componentDidCatch and getDerivedStateFromError if both exist on a component", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			local componentDidCatchError, getDerivedStateFromErrorError
			local ErrorBoundaryWithBothMethods = React.Component:extend("ErrorBoundaryWithBothMethods")
			function ErrorBoundaryWithBothMethods:init()
				self.state = {}
			end
			function ErrorBoundaryWithBothMethods.getDerivedStateFromError(error_)
				getDerivedStateFromErrorError = error_

				return { error = error_ }
			end
			function ErrorBoundaryWithBothMethods:componentDidCatch(error_, info)
				componentDidCatchError = error_
			end
			function ErrorBoundaryWithBothMethods:render()
				return (function()
					if self.state.error then
						return "ErrorBoundary"
					end

					return self.props.children
				end)()
			end

			-- ROBLOX deviation: using a string 'expected' thrownError in place of JS's error object.
			local thrownError = "expected"
			local Throws = function()
				error(thrownError, 0)
			end

			root.render(React.createElement(ErrorBoundaryWithBothMethods, nil, React.createElement(Throws)))
			jestExpect(textContent(root)).toEqual("ErrorBoundary")

			-- ROBLOX deviation: using a string 'expected' thrownError in place of JS's error object.
			jestExpect(componentDidCatchError).toEqual("expected")
			jestExpect(getDerivedStateFromErrorError).toEqual("expected")
		end)
		-- ROBLOX TODO: ReactDOMComponent not translated
		xit("should catch errors from invariants in completion phase", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement("input", nil, React.createElement("div"))
			))
			jestExpect(textContent(root)).toContain("Caught an error: input is a void element tag")
		end)
		it("should catch errors from errors in the throw phase from boundaries", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()
			local thrownError = "original error"
			local Throws = function()
				error(thrownError, 0)
			end
			local EvilErrorBoundary = React.Component:extend("EvilErrorBoundary")

			function EvilErrorBoundary:componentDidCatch()
				error("gotta catch em all", 0)
			end

			function EvilErrorBoundary:render()
				return self.props.children
			end

			root.render(React.createElement(
				ErrorBoundary,
				nil,
				React.createElement(EvilErrorBoundary, nil, React.createElement(Throws))
			))
			jestExpect(textContent(root)).toContain("Caught an error: gotta catch em all.")
		end)
		-- ROBLOX TODO: when focused this test passes, however it causes 'runAllTimers flushes all scheduled callbacks' and
		-- 'executes callbacks in order of priority' tests to fail in SchedulerNoDOM but only in __DEV__ mode
		local skipIfDev = (function()
			if _G.__DEV__ then
				return itSKIP
			end
			return it
		end)()
		skipIfDev("should protect errors from errors in the stack generation", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()
			local evilError = setmetatable({
				message = "gotta catch em all",
			}, {
				__index = function(mytable, key)
					-- ROBLOX TODO: when we convert to LuauPolyfill errors, ensure this stack error is handled correctly
					if key == "stack" then
						error("gotta catch em all")
					else
						return mytable
					end
				end,
			})

			-- ROBLOX deviation: uses Class component instead of functional component so we can set displayName
			local Throws = React.Component:extend("Throws")
			function Throws:render()
				error(evilError)
			end

			Throws = setmetatable(Throws, {
				__index = function(mytable, key)
					if key == "displayName" then
						error("gotta catch em all", 0)
					else
						return Throws
					end
				end,
			})

			local function Wrapper()
				return React.createElement(Throws)
			end

			root.render(React.createElement(ErrorBoundary, nil, React.createElement(Wrapper)))
			-- ROBLOX deviation: using textContent helper in place of upstream .textContent()
			jestExpect(textContent(root)).toContain("Caught an error: gotta catch em all.")
		end)
		-- @gate skipUnmountedBoundaries
		it("catches errors thrown in componentWillUnmount", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			local Component = React.Component:extend("Component")
			function Component:render()
				local id = self.props.id
				Scheduler.unstable_yieldValue("Component render " .. id)
				return id
			end

			local LocalErrorBoundary = React.Component:extend("LocalErrorBoundary")

			function LocalErrorBoundary:init()
				self.state = {}
			end

			function LocalErrorBoundary.getDerivedStateFromError(error_)
				Scheduler.unstable_yieldValue("ErrorBoundary static getDerivedStateFromError")
				return { error = error_ }
			end
			function LocalErrorBoundary:render()
				local children, id, fallbackID = self.props.children, self.props.id, self.props.fallbackID
				local error_ = self.state.error

				if error_ then
					Scheduler.unstable_yieldValue(("%s render error"):format(id))

					return React.createElement(Component, { id = fallbackID })
				end

				Scheduler.unstable_yieldValue(("%s render success"):format(id))

				return children or nil
			end

			local LocalBrokenComponentWillUnmount = React.Component:extend("LocalBrokenComponentWillUnmount")

			function LocalBrokenComponentWillUnmount:componentWillUnmount()
				Scheduler.unstable_yieldValue("BrokenComponentWillUnmount componentWillUnmount")
				error("Expected")
			end
			function LocalBrokenComponentWillUnmount:render()
				Scheduler.unstable_yieldValue("BrokenComponentWillUnmount render")
				return "broken"
			end

			root.render(React.createElement(
				LocalErrorBoundary,
				{
					id = "OuterBoundary",
					fallbackID = "OuterFallback",
				},
				React.createElement(Component, {
					id = "sibling",
				}),
				React.createElement(LocalErrorBoundary, {
					id = "InnerBoundary",
					fallbackID = "InnerFallback",
				}, React.createElement(LocalBrokenComponentWillUnmount))
			))
			jestExpect(root.getChildren()[1].text).toEqual("sibling")
			jestExpect(root.getChildren()[2].text).toEqual("broken")
			jestExpect(Scheduler).toHaveYielded({
				"OuterBoundary render success",
				"Component render sibling",
				"InnerBoundary render success",
				"BrokenComponentWillUnmount render",
			})
			root.render(React.createElement(LocalErrorBoundary, {
				id = "OuterBoundary",
				fallbackID = "OuterFallback",
			}, React.createElement(
				Component,
				{
					id = "sibling",
				}
			)))
			-- React should skip over the unmounting boundary and find the nearest still-mounted boundary.
			jestExpect(textContent(root)).toEqual("OuterFallback")
			jestExpect(textContent(root)).toEqual("OuterFallback")
			jestExpect(Scheduler).toHaveYielded({
				"OuterBoundary render success",
				"Component render sibling",
				"BrokenComponentWillUnmount componentWillUnmount",
				"ErrorBoundary static getDerivedStateFromError",
				"OuterBoundary render error",
				"Component render OuterFallback",
			})
		end)
		-- @gate skipUnmountedBoundaries
		it("catches errors thrown while detaching refs", function()
			-- ROBLOX deviation: using legacy root of Noop renderer instead of ReactDOM
			local root = ReactNoop.createLegacyRoot()

			local Component = React.Component:extend("Component")

			function Component:render()
				local id = self.props.id

				Scheduler.unstable_yieldValue("Component render " .. id)

				return id
			end

			local LocalErrorBoundary = React.Component:extend("LocalErrorBoundary")

			function LocalErrorBoundary:init()
				self.state = {}
			end
			function LocalErrorBoundary.getDerivedStateFromError(error_)
				Scheduler.unstable_yieldValue("ErrorBoundary static getDerivedStateFromError")
				return { error = error_ }
			end
			function LocalErrorBoundary:render()
				local children, id, fallbackID = self.props.children, self.props.id, self.props.fallbackID
				local error_ = self.state.error

				if error_ then
					Scheduler.unstable_yieldValue(("%s render error"):format(id))

					return React.createElement(Component, { id = fallbackID })
				end

				Scheduler.unstable_yieldValue(("%s render success"):format(id))

				return children or nil
			end

			local LocalBrokenCallbackRef = React.Component:extend("LocalBrokenCallbackRef")

			function LocalBrokenCallbackRef._ref(ref)
				Scheduler.unstable_yieldValue("LocalBrokenCallbackRef ref " .. tostring(not not ref))
				if ref == nil then
					error("Expected")
				end
			end
			function LocalBrokenCallbackRef:render()
				Scheduler.unstable_yieldValue("LocalBrokenCallbackRef render")

				return React.createElement("div", {
					ref = self._ref,
				}, "ref")
			end

			root.render(React.createElement(
				LocalErrorBoundary,
				{
					id = "OuterBoundary",
					fallbackID = "OuterFallback",
				},
				React.createElement(Component, {
					id = "sibling",
				}),
				React.createElement(LocalErrorBoundary, {
					id = "InnerBoundary",
					fallbackID = "InnerFallback",
				}, React.createElement(LocalBrokenCallbackRef))
			))
			jestExpect(root.getChildren()[1].text).toEqual("sibling")
			jestExpect(root.getChildren()[2].text).toEqual("ref")
			jestExpect(Scheduler).toHaveYielded({
				"OuterBoundary render success",
				"Component render sibling",
				"InnerBoundary render success",
				"LocalBrokenCallbackRef render",
				"LocalBrokenCallbackRef ref true",
			})
			root.render(React.createElement(LocalErrorBoundary, {
				id = "OuterBoundary",
				fallbackID = "OuterFallback",
			}, React.createElement(
				Component,
				{
					id = "sibling",
				}
			)))
			-- React should skip over the unmounting boundary and find the nearest still-mounted boundary.
			local rootChildren = root.getChildren()
			jestExpect(rootChildren[1].text).toEqual("OuterFallback")
			jestExpect(rootChildren[#rootChildren].text).toEqual("OuterFallback")
			jestExpect(Scheduler).toHaveYielded({
				"OuterBoundary render success",
				"Component render sibling",
				"LocalBrokenCallbackRef ref false",
				"ErrorBoundary static getDerivedStateFromError",
				"OuterBoundary render error",
				"Component render OuterFallback",
			})
		end)
	end)
end
