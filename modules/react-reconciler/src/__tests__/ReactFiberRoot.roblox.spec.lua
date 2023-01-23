-- awaiting pull request: https://github.com/facebook/react/pull/20155
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 * @jest-environment node
]]

local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local jest = JestGlobals.jest
local beforeEach = JestGlobals.beforeEach
local it = JestGlobals.it

local ReactFiberRoot
local ReactRootTags

beforeEach(function()
	jest.resetModules()

	ReactFiberRoot = require(script.Parent.Parent["ReactFiberRoot.new"])
	ReactRootTags = require(script.Parent.Parent.ReactRootTags)
end)

it("should properly initialize a fiber created with createFiberRoot", function()
	local fiberRoot =
		ReactFiberRoot.createFiberRoot({}, ReactRootTags.BlockingRoot, false)

	jestExpect(fiberRoot.current).toBeDefined()
	jestExpect(fiberRoot.current.updateQueue).toBeDefined()
end)
