-- ROBLOX upstream: https://github.com/facebook/react/blob/34aa5cfe0d9b6ec4667e02bf46ab34d83dfb2d6d/packages/react-reconciler/src/ReactHookEffectTags.js#L12-L20
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

export type HookFlags = number

return {
	--[[  ]]
	NoFlags = 0b0000,

	-- Represents whether effect should fire.
	--[[ ]]
	HasEffect = 0b0001,

	-- Represents the phase in which the effect (not the clean-up) fires.
	--[[ ]]
	Insertion = 0b0010,
	--[[    ]]
	Layout = 0b0100,
	--[[   ]]
	Passive = 0b1000,
}
