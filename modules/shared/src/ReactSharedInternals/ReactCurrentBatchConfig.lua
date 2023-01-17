--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/92fcd46cc79bbf45df4ce86b0678dcef3b91078d/packages/react/src/ReactCurrentBatchConfig.js
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
local ReactCurrentBatchConfig = {
	transition = 0,
}

return ReactCurrentBatchConfig
