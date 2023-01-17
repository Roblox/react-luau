--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/ddd1faa1972b614dfbfae205f2aa4a6c0b39a759/packages/react-reconciler/src/ReactFiberTransition.js
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

return {
	NoTransition = 0,
	requestCurrentTransition = function(): number
		return ReactCurrentBatchConfig.transition
	end,
}
