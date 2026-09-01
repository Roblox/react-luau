--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/react-reconciler/src/ReactFiberTransition.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Packages = script.Parent.Parent

local ReactSharedInternals = require(Packages.Shared).ReactSharedInternals

local ReactCurrentBatchConfig = ReactSharedInternals.ReactCurrentBatchConfig
local entangleAsyncAction =
	require(script.Parent.ReactFiberAsyncAction).entangleAsyncAction

local previousOnStartTransitionFinish = ReactSharedInternals.onStartTransitionFinish
ReactSharedInternals.onStartTransitionFinish = function(transition, returnValue)
	if typeof(returnValue) == "table" and typeof(returnValue.andThen) == "function" then
		entangleAsyncAction(transition, returnValue)
	end

	if previousOnStartTransitionFinish ~= nil then
		previousOnStartTransitionFinish(transition, returnValue)
	end
end

return {
	requestCurrentTransition = function(): { [any]: any }?
		return ReactCurrentBatchConfig.transition
	end,
}
