--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/34aa5cfe0d9b6ec4667e02bf46ab34d83dfb2d6d/packages/react/src/ReactCurrentBatchConfig.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

--[[*
 * Keeps track of the current batch's configuration such as how long an update
 * should suspend for if it needs to.
]]
local ReactTypes = require(script.Parent.Parent.ReactTypes)
type BatchConfigTransition = ReactTypes.BatchConfigTransition

type BatchConfig = {
	transition: BatchConfigTransition?,
}

local ReactCurrentBatchConfig: BatchConfig = {
	transition = nil,
}

return ReactCurrentBatchConfig
