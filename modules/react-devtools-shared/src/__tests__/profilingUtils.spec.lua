-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/__tests__/profilingUtils-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

return function()
	local Packages = script.Parent.Parent.Parent
	local JestGlobals = require(Packages.Dev.JestGlobals)
	local jestExpect = JestGlobals.expect

	describe("profiling utils", function()
		local utils
		beforeEach(function()
			utils = require(script.Parent.Parent.devtools.views.Profiler.utils)
		end)
		it("should throw if importing older/unsupported data", function()
			jestExpect(function()
				return utils.prepareProfilingDataFrontendFromExport({
					version = 0,
					dataForRoots = {},
				})
			end).toThrow('Unsupported profiler export version "0"')
		end)
	end)
end
