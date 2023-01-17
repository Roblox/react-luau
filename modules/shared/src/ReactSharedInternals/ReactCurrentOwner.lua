--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/376d5c1b5aa17724c5fea9412f8fcde14a7b23f1/packages/react/src/ReactCurrentOwner.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

--[[*
 * Keeps track of the current owner.
 *
 * The current owner is the component who should own any components that are
 * currently being constructed.
]]
local ReactCurrentOwner = {
	--[[*
   * @internal
   * @type {ReactComponent}
   ]]
	-- ROBLOX deviation START: upstream types this as Fiber, but that would incur a circular dependency between reconciler and shared
	current = nil :: any,
	-- ROBLOX deviation END
}

return ReactCurrentOwner
