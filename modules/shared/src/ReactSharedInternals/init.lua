--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/607148673b3156d051d1fed17cd49e83698dce54/packages/react/src/ReactSharedInternals.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
]]

--[[
	ROBLOX deviation: ReactSharedInternals captures singleton state across the
	whole workspace. This file and the modules it requires were moved from React
	to untangle a cyclic workspace member dependency.

	Before:
	* ReactSharedInternals (and the 5 associated modules) lived in React
	* React had a dependency on Shared
	* Shared reached into React source to re-export ReactSharedInternals (cycle)

	After:
	* ReactSharedInternals (and the 5 associated modules) live in Shared
	* React depends on Shared
	* Shared has no intra-workspace dependencies (no cycles)
]]
local Packages = script.Parent.Parent
local console = require(Packages.LuauPolyfill).console
local function onlyInTestError(functionName: string)
	return function()
		console.error(functionName .. " is only available in tests, not in production")
	end
end

-- import assign from 'object-assign';
local ReactCurrentDispatcher = require(script.ReactCurrentDispatcher)
export type Dispatcher = ReactCurrentDispatcher.Dispatcher
local ReactCurrentBatchConfig = require(script.ReactCurrentBatchConfig)
local ReactCurrentOwner = require(script.ReactCurrentOwner)
local ReactDebugCurrentFrame = require(script.ReactDebugCurrentFrame)
local IsSomeRendererActing = require(script.IsSomeRendererActing)

local ReactSharedInternals = {
	ReactCurrentDispatcher = ReactCurrentDispatcher,
	ReactCurrentBatchConfig = ReactCurrentBatchConfig,
	ReactCurrentOwner = ReactCurrentOwner,
	IsSomeRendererActing = IsSomeRendererActing,
	-- ROBLOX deviation: Luau type checking requires us to have a consistent export shape regardless of __DEV__
	-- ROBLOX TODO: use if-expressions when all clients are on 503+
	ReactDebugCurrentFrame = if _G.__DEV__
		then ReactDebugCurrentFrame
		else {
			setExtraStackFrame = function(_: string?): ()
				onlyInTestError("setExtraStackFrame")
			end,
		},
	-- deviation: We shouldn't have to worry about duplicate bundling here
	-- Used by renderers to avoid bundling object-assign twice in UMD bundles:
	-- assign,
}

return ReactSharedInternals
