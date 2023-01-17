-- ROBLOX upstream: https://github.com/facebook/react/blob/c5d2fc7127654e43de59fff865b74765a103c4a5/packages/react-reconciler/src/ReactFiberHostConfigWithNoPersistence.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local invariant = require(script.Parent.Parent.invariant)

-- Renderers that don't support persistence
-- can re-export everything from this module.

local function shim(...)
	invariant(
		false,
		"The current renderer does not support persistence. "
			.. "This error is likely caused by a bug in React. "
			.. "Please file an issue."
	)
end

-- Persistence (when unsupported)
return {
	supportsPersistence = false,
	cloneInstance = shim,
	cloneFundamentalInstance = shim,
	createContainerChildSet = shim,
	appendChildToContainerChildSet = shim,
	finalizeContainerChildren = shim,
	replaceContainerChildren = shim,
	cloneHiddenInstance = shim,
	cloneHiddenTextInstance = shim,
}
