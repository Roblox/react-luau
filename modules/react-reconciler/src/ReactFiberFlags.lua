--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/37cb732c59863297e48f69ac1f6e2ba1aa1886f0/packages/react-reconciler/src/ReactFiberFlags.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

export type Flags = number

local exports = {}

-- Don't change these two values. They're used by React Dev Tools.
exports.NoFlags = --[[                      ]]
	0b000000000000000000
exports.PerformedWork = --[[                ]]
	0b000000000000000001

-- You can change the rest (and add more).
exports.Placement = --[[                    ]]
	0b000000000000000010
exports.Update = --[[                       ]]
	0b000000000000000100
exports.PlacementAndUpdate = --[[           ]]
	0b000000000000000110
exports.Deletion = --[[                     ]]
	0b000000000000001000
exports.ContentReset = --[[                 ]]
	0b000000000000010000
exports.Callback = --[[                     ]]
	0b000000000000100000
exports.DidCapture = --[[                   ]]
	0b000000000001000000
exports.Ref = --[[                          ]]
	0b000000000010000000
exports.Snapshot = --[[                     ]]
	0b000000000100000000
exports.Passive = --[[                      ]]
	0b000000001000000000
-- TODO (effects) Remove this bit once the new reconciler is synced to the old.
exports.PassiveUnmountPendingDev = --[[     ]]
	0b000010000000000000
exports.Hydrating = --[[                    ]]
	0b000000010000000000
exports.HydratingAndUpdate = --[[           ]]
	0b000000010000000100

-- Passive & Update & Callback & Ref & Snapshot
exports.LifecycleEffectMask = --[[          ]]
	0b000000001110100100

-- Union of all host effects
exports.HostEffectMask = --[[               ]]
	0b000000011111111111

-- These are not really side effects, but we still reuse this field.
exports.Incomplete = --[[                   ]]
	0b000000100000000000
exports.ShouldCapture = --[[                ]]
	0b000001000000000000
exports.ForceUpdateForLegacySuspense = --[[ ]]
	0b000100000000000000

-- Static tags describe aspects of a fiber that are not specific to a render,
-- e.g. a fiber uses a passive effect (even if there are no updates on this particular render).
-- This enables us to defer more work in the unmount case,
-- since we can defer traversing the tree during layout to look for Passive effects,
-- and instead rely on the static flag as a signal that there may be cleanup work.
exports.PassiveStatic = --[[                ]]
	0b001000000000000000

-- Union of side effect groupings as pertains to subtreeFlags
exports.BeforeMutationMask = --[[           ]]
	0b000000001100001010
exports.MutationMask = --[[                 ]]
	0b000000010010011110
exports.LayoutMask = --[[                   ]]
	0b000000000010100100
exports.PassiveMask = --[[                  ]]
	0b000000001000001000

-- Union of tags that don't get reset on clones.
-- This allows certain concepts to persist without recalculting them,
-- e.g. whether a subtree contains passive effects or portals.
exports.StaticMask = --[[                   ]]
	0b001000000000000000

-- These flags allow us to traverse to fibers that have effects on mount
-- without traversing the entire tree after every commit for
-- double invoking
exports.MountLayoutDev = --[[               ]]
	0b010000000000000000
exports.MountPassiveDev = --[[              ]]
	0b100000000000000000

return exports
