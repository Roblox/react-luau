-- ROBLOX upstream: https://github.com/facebook/react/blob/702fad4b1b48ac8f626ed3f35e8f86f5ea728084/packages/react-dom/src/__tests__/ReactDOMComponentTree-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Packages = script.Parent.Parent.Parent.Parent

local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local jest = JestGlobals.jest
local beforeEach = JestGlobals.beforeEach
local it = JestGlobals.it

local React
local ReactRoblox
local reactRobloxRoot
local ReactRobloxComponentTree
local Scheduler
local parent

beforeEach(function()
	jest.resetModules()
	jest.useFakeTimers()
	local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
	ReactFeatureFlags.debugRenderPhaseSideEffectsForStrictMode = false

	React = require(Packages.React)
	ReactRoblox = require(Packages.ReactRoblox)
	Scheduler = require(Packages.Scheduler)
	ReactRobloxComponentTree = require(script.Parent.Parent.ReactRobloxComponentTree)
	parent = Instance.new("Folder")
	reactRobloxRoot = ReactRoblox.createRoot(parent)
end)

it("getClosestInstanceFromNode should return a cached instance", function()
	reactRobloxRoot:render(
		React.createElement(
			"Frame",
			{},
			{ Label = React.createElement("TextLabel", { Text = "Hello" }) }
		)
	)

	Scheduler.unstable_flushAllWithoutAsserting()

	local labelNode =
		ReactRobloxComponentTree.getClosestInstanceFromNode(parent.Frame.Label)
	jestExpect(labelNode.memoizedProps.Text).toEqual("Hello")
end)

it("getClosestInstanceFromNode should return portaled instances", function()
	local portalContainer1 = Instance.new("Frame")
	local portalContainer2 = Instance.new("Frame")
	local portalContainer3 = Instance.new("Frame")

	reactRobloxRoot:render({
		React.createElement("TextLabel", { key = "a", Text = "normal[0]" }),
		ReactRoblox.createPortal({
			React.createElement("TextLabel", { key = "b", Text = "portal1[0]" }),
			ReactRoblox.createPortal(
				React.createElement("TextLabel", { key = "c", Text = "portal2[0]" }),
				portalContainer2
			),
			ReactRoblox.createPortal(
				React.createElement("TextLabel", { key = "d", Text = "portal3[0]" }),
				portalContainer3
			),
			React.createElement("TextLabel", { key = "e", Text = "portal1[1]" }),
		}, portalContainer1),
		React.createElement("TextLabel", { key = "f", Text = "normal[1]" }),
	})

	Scheduler.unstable_flushAllWithoutAsserting()

	local portal3Label = ReactRobloxComponentTree.getClosestInstanceFromNode(
		portalContainer3:GetChildren()[1]
	)
	jestExpect(portal3Label.memoizedProps.Text).toEqual("portal3[0]")
end)
