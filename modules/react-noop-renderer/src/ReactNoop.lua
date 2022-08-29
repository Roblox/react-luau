--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/faa697f4f9afe9f1c98e315b2a9e70f5a74a7a74/packages/react-noop-renderer/src/ReactNoop.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

--[[*
 * This is a renderer of React that doesn't have a render target output.
 * It is useful to demonstrate the internals of the reconciler in isolation
 * and for testing semantics of reconciliation separate from the host
 * environment.
]]

local Packages = script.Parent.Parent
local ReactFiberReconciler = require(Packages.ReactReconciler)
local createReactNoop = require(script.Parent.createReactNoop)

local NoopRenderer = createReactNoop(
	ReactFiberReconciler, -- reconciler
	true -- useMutation
)

return {
	_Scheduler = NoopRenderer._Scheduler,
	getChildren = NoopRenderer.getChildren,
	getPendingChildren = NoopRenderer.getPendingChildren,
	getOrCreateRootContainer = NoopRenderer.getOrCreateRootContainer,
	createRoot = NoopRenderer.createRoot,
	createBlockingRoot = NoopRenderer.createBlockingRoot,
	createLegacyRoot = NoopRenderer.createLegacyRoot,
	getChildrenAsJSX = NoopRenderer.getChildrenAsJSX,
	getPendingChildrenAsJSX = NoopRenderer.getPendingChildrenAsJSX,
	createPortal = NoopRenderer.createPortal,
	render = NoopRenderer.render,
	renderLegacySyncRoot = NoopRenderer.renderLegacySyncRoot,
	renderToRootWithID = NoopRenderer.renderToRootWithID,
	unmountRootWithID = NoopRenderer.unmountRootWithID,
	findInstance = NoopRenderer.findInstance,
	flushNextYield = NoopRenderer.flushNextYield,
	flushWithHostCounters = NoopRenderer.flushWithHostCounters,
	expire = NoopRenderer.expire,
	flushExpired = NoopRenderer.flushExpired,
	batchedUpdates = NoopRenderer.batchedUpdates,
	deferredUpdates = NoopRenderer.deferredUpdates,
	unbatchedUpdates = NoopRenderer.unbatchedUpdates,
	discreteUpdates = NoopRenderer.discreteUpdates,
	flushDiscreteUpdates = NoopRenderer.flushDiscreteUpdates,
	flushSync = NoopRenderer.flushSync,
	flushPassiveEffects = NoopRenderer.flushPassiveEffects,
	act = NoopRenderer.act,
	dumpTree = NoopRenderer.dumpTree,
	getRoot = NoopRenderer.getRoot,
	-- TODO: Remove this after callers migrate to alternatives.
	unstable_runWithPriority = NoopRenderer.unstable_runWithPriority,
}
