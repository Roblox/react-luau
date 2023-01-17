-- ROBLOX upstream: https://github.com/facebook/react/blob/c5d2fc7127654e43de59fff865b74765a103c4a5/packages/react-reconciler/src/ReactFiberHostConfigWithNoHydration.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local invariant = require(script.Parent.Parent.invariant)

-- Renderers that don't support hydration
-- can re-export everything from this module.

function shim(...)
	invariant(
		false,
		"The current renderer does not support hydration. "
			.. "This error is likely caused by a bug in React. "
			.. "Please file an issue."
	)
end

-- Hydration (when unsupported)
export type SuspenseInstance = any
return {
	supportsHydration = false,
	canHydrateInstance = shim,
	canHydrateTextInstance = shim,
	canHydrateSuspenseInstance = shim,
	isSuspenseInstancePending = shim,
	isSuspenseInstanceFallback = shim,
	registerSuspenseInstanceRetry = shim,
	getNextHydratableSibling = shim,
	getFirstHydratableChild = shim,
	hydrateInstance = shim,
	hydrateTextInstance = shim,
	hydrateSuspenseInstance = shim,
	getNextHydratableInstanceAfterSuspenseInstance = shim,
	commitHydratedContainer = shim,
	commitHydratedSuspenseInstance = shim,
	clearSuspenseBoundary = shim,
	clearSuspenseBoundaryFromContainer = shim,
	didNotMatchHydratedContainerTextInstance = shim,
	didNotMatchHydratedTextInstance = shim,
	didNotHydrateContainerInstance = shim,
	didNotHydrateInstance = shim,
	didNotFindHydratableContainerInstance = shim,
	didNotFindHydratableContainerTextInstance = shim,
	didNotFindHydratableContainerSuspenseInstance = shim,
	didNotFindHydratableInstance = shim,
	didNotFindHydratableTextInstance = shim,
	didNotFindHydratableSuspenseInstance = shim,
}
