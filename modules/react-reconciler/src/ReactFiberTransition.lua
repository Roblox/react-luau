--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/34aa5cfe0d9b6ec4667e02bf46ab34d83dfb2d6d/packages/react-reconciler/src/ReactFiberTransition.js
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
	requestCurrentTransition = function(): { [any]: any }?
		return ReactCurrentBatchConfig.transition
	end,
}
