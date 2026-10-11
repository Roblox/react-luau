--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/shared/reportGlobalError.js
--[[*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local setTimeout = LuauPolyfill.setTimeout
local errorToString = require(script.Parent["ErrorHandling.roblox"]).errorToString

local function reportGlobalError(error_: any)
	-- ROBLOX DEVIATION: Roblox has no reportError or global error event. A deferred
	-- thread error reports the value as uncaught without corrupting React state.
	setTimeout(function()
		error(errorToString(error_), 0)
	end)
end

return reportGlobalError
