--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/861811347b8fa936b4a114fc022db9b8253b3d86/packages/react-reconciler/src/__tests__/ReactConfigurableErrorLogging-test.js
--[[*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 ]]

local Packages = script.Parent.Parent.Parent.Parent

local React
local ReactRoblox
local Scheduler
local Error

local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local it = JestGlobals.it
local jest = JestGlobals.jest
local jestExpect = JestGlobals.expect

beforeEach(function()
	jest.resetModules()
	jest.useFakeTimers()
	React = require(Packages.React)
	ReactRoblox = require(Packages.ReactRoblox)
	Scheduler = require(Packages.Scheduler)
	Error = require(Packages.LuauPolyfill).Error
end)

describe("ReactConfigurableErrorLogging", function()
	it("should log errors that occur during the begin phase", function()
		local ErrorThrowingComponent = React.Component:extend("ErrorThrowingComponent")
		function ErrorThrowingComponent:init()
			error(Error.new("constructor error"), 0)
		end
		function ErrorThrowingComponent:render()
			return React.createElement("Frame")
		end

		local uncaughtErrors = {}
		local caughtErrors = {}
		local recoverableErrors = {}
		local root = ReactRoblox.createRoot(Instance.new("Folder"), {
			onUncaughtError = function(error_, errorInfo)
				table.insert(uncaughtErrors, error_)
				table.insert(uncaughtErrors, errorInfo)
			end,
			onCaughtError = function(error_, errorInfo)
				table.insert(caughtErrors, error_)
				table.insert(caughtErrors, errorInfo)
			end,
			onRecoverableError = function(error_, errorInfo)
				table.insert(recoverableErrors, error_)
				table.insert(recoverableErrors, errorInfo)
			end,
		})

		root:render(React.createElement("Frame", nil, {
			Child = React.createElement(ErrorThrowingComponent),
		}))
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(uncaughtErrors[1].message).toBe("constructor error")
		jestExpect(uncaughtErrors[2].componentStack).toContain("ErrorThrowingComponent")
		jestExpect(uncaughtErrors[2].componentStack).toContain("Frame")
		jestExpect(caughtErrors).toEqual({})
		jestExpect(recoverableErrors).toEqual({})
	end)

	it("should log errors that occur during the commit phase", function()
		local ErrorThrowingComponent = React.Component:extend("ErrorThrowingComponent")
		function ErrorThrowingComponent:componentDidMount()
			error(Error.new("componentDidMount error"), 0)
		end
		function ErrorThrowingComponent:render()
			return React.createElement("Frame")
		end

		local uncaughtErrors = {}
		local caughtErrors = {}
		local root = ReactRoblox.createRoot(Instance.new("Folder"), {
			onUncaughtError = function(error_, errorInfo)
				table.insert(uncaughtErrors, error_)
				table.insert(uncaughtErrors, errorInfo)
			end,
			onCaughtError = function(error_, errorInfo)
				table.insert(caughtErrors, error_)
				table.insert(caughtErrors, errorInfo)
			end,
		})

		root:render(React.createElement("Frame", nil, {
			Child = React.createElement(ErrorThrowingComponent),
		}))
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(uncaughtErrors[1].message).toBe("componentDidMount error")
		jestExpect(uncaughtErrors[2].componentStack).toContain("ErrorThrowingComponent")
		jestExpect(uncaughtErrors[2].componentStack).toContain("Frame")
		jestExpect(caughtErrors).toEqual({})
	end)

	it("should ignore errors thrown in log method to prevent cycle", function()
		local ErrorBoundary = React.Component:extend("ErrorBoundary")
		function ErrorBoundary:init()
			self.state = {}
		end
		function ErrorBoundary:componentDidCatch(error_)
			self:setState({ error = error_ })
		end
		function ErrorBoundary:render()
			if self.state.error ~= nil then
				return nil
			end
			return self.props.children
		end

		local function ErrorThrowingComponent()
			error(Error.new("render error"), 0)
		end

		local uncaughtErrors = {}
		local caughtErrors = {}
		local boundaryRef = React.createRef()
		local root = ReactRoblox.createRoot(Instance.new("Folder"), {
			onUncaughtError = function(error_, errorInfo)
				table.insert(uncaughtErrors, error_)
				table.insert(uncaughtErrors, errorInfo)
			end,
			onCaughtError = function(error_, errorInfo)
				table.insert(caughtErrors, error_)
				table.insert(caughtErrors, errorInfo)
				error(Error.new("onCaughtError error"), 0)
			end,
		})

		root:render(React.createElement("Frame", nil, {
			Boundary = React.createElement(ErrorBoundary, { ref = boundaryRef }, {
				Child = React.createElement("Frame", nil, {
					Throws = React.createElement(ErrorThrowingComponent),
				}),
			}),
		}))
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(uncaughtErrors).toEqual({})
		jestExpect(caughtErrors[1].message).toBe("render error")
		jestExpect(caughtErrors[2].componentStack).toContain("ErrorThrowingComponent")
		jestExpect(caughtErrors[2].componentStack).toContain("ErrorBoundary")
		jestExpect(caughtErrors[2].errorBoundary).toBe(boundaryRef.current)
		jestExpect(function()
			jest.runAllTimers()
		end).toThrow("onCaughtError error")
	end)

	it("should log errors caught by a derived-state boundary", function()
		local ErrorBoundary = React.Component:extend("ErrorBoundary")
		function ErrorBoundary:init()
			self.state = { didError = false }
		end
		function ErrorBoundary.getDerivedStateFromError()
			return { didError = true }
		end
		function ErrorBoundary:render()
			if self.state.didError then
				return nil
			end
			return self.props.children
		end

		local function ErrorThrowingComponent()
			error(Error.new("render error"), 0)
		end

		local caughtErrors = {}
		local boundaryRef = React.createRef()
		local root = ReactRoblox.createRoot(Instance.new("Folder"), {
			onCaughtError = function(error_, errorInfo)
				table.insert(caughtErrors, error_)
				table.insert(caughtErrors, errorInfo)
			end,
		})

		root:render(React.createElement(ErrorBoundary, { ref = boundaryRef }, {
			Child = React.createElement(ErrorThrowingComponent),
		}))
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(caughtErrors[1].message).toBe("render error")
		jestExpect(caughtErrors[2].componentStack).toContain("ErrorThrowingComponent")
		jestExpect(caughtErrors[2].componentStack).toContain("ErrorBoundary")
		jestExpect(caughtErrors[2].errorBoundary).toBe(boundaryRef.current)
	end)

	it("should report a successful concurrent render recovery", function()
		local didThrow = false
		local function ErrorThrowingComponent()
			if not didThrow then
				didThrow = true
				error(Error.new("render error"), 0)
			end
			return React.createElement("Frame")
		end

		local uncaughtErrors = {}
		local caughtErrors = {}
		local recoverableErrors = {}
		local root = ReactRoblox.createRoot(Instance.new("Folder"), {
			onUncaughtError = function(error_, errorInfo)
				table.insert(uncaughtErrors, error_)
				table.insert(uncaughtErrors, errorInfo)
			end,
			onCaughtError = function(error_, errorInfo)
				table.insert(caughtErrors, error_)
				table.insert(caughtErrors, errorInfo)
			end,
			onRecoverableError = function(error_, errorInfo)
				table.insert(recoverableErrors, error_)
				table.insert(recoverableErrors, errorInfo)
			end,
		})

		root:render(React.createElement(ErrorThrowingComponent))
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(uncaughtErrors).toEqual({})
		jestExpect(caughtErrors).toEqual({})
		jestExpect(recoverableErrors[1].message).toBe(
			"There was an error during concurrent rendering but React was able to recover by "
				.. "instead synchronously rendering the entire root."
		)
		jestExpect(recoverableErrors[1].cause.message).toBe("render error")
		jestExpect(recoverableErrors[2].componentStack).toContain(
			"ErrorThrowingComponent"
		)
	end)
end)
