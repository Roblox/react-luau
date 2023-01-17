--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/a457e02ae3a2d3903fcf8748380b1cc293a2445e/packages/react/src/IsSomeRendererActing.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

--[[*
 * Used by act() to track whether you're inside an act() scope.
 ]]

local IsSomeRendererActing = {
	current = false,
}
return IsSomeRendererActing
