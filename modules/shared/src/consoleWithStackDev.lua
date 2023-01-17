-- ROBLOX upstream: https://github.com/facebook/react/blob/cb141681750c8221ac799074df09df2bb448c7a4/packages/shared/consoleWithStackDev.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
]]
local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local console = LuauPolyfill.console
local Array = LuauPolyfill.Array

local ReactSharedInternals = require(script.Parent.ReactSharedInternals)
-- In DEV, calls to console.warn and console.error get replaced
-- by calls to these methods by a Babel plugin.
--
-- In PROD (or in packages without access to React internals),
-- they are left as they are instead.

-- deviation: declare this ahead of time so that `warn` and `error` are able to
-- reference it
local printWarning

local exports = {}
exports.warn = function(format, ...)
	if _G.__DEV__ then
		printWarning("warn", format, { ... })
	end
end
exports.error = function(format, ...)
	if _G.__DEV__ then
		printWarning("error", format, { ... })
	end
end

function printWarning(level, format, args)
	-- When changing this logic, you might want to also
	-- update consoleWithStackDev.www.js as well.
	if _G.__DEV__ then
		local ReactDebugCurrentFrame = ReactSharedInternals.ReactDebugCurrentFrame
		local stack = ReactDebugCurrentFrame.getStackAddendum()

		if stack ~= "" then
			format ..= "%s"
			-- deviation: no array `concat` function in lua
			args = Array.slice(args, 1)
			table.insert(args, stack)
		end

		local argsWithFormat = Array.map(args, tostring)
		-- Careful: RN currently depends on this prefix
		table.insert(argsWithFormat, 1, "Warning: " .. format)
		-- We intentionally don't use spread (or .apply) directly because it
		-- breaks IE9: https://github.com/facebook/react/issues/13610
		-- eslint-disable-next-line react-internal/no-production-logging
		console[level](unpack(argsWithFormat))
	end
end

return exports
