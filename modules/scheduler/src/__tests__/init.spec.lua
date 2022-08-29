-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/__tests__/setupTests.js
--[[**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 *
 * LICENSE file in the root directory of this source tree.
 * @flow
 *]]
 return function()
	local Packages = script.Parent.Parent.Parent
	local RobloxJest = require(Packages.Dev.RobloxJest)
	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local getJestMatchers = require(script.Parent.Parent["getJestMatchers.roblox"])

	beforeAll(function()
		jestExpect.extend(getJestMatchers(jestExpect))
		jestExpect.extend(RobloxJest.Matchers)
	end)
end
