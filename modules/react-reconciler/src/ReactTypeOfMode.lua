-- ROBLOX upstream: https://github.com/facebook/react/blob/22dc2e42bdc00d87fc19c5e75fc7c0b3fdcdc572/packages/react-reconciler/src/ReactTypeOfMode.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

export type TypeOfMode = number

return {
	NoMode = 0b00000,
	StrictMode = 0b00001,
	-- TODO: Remove BlockingMode and ConcurrentMode by reading from the root
	-- tag instead
	BlockingMode = 0b00010,
	ConcurrentMode = 0b00100,
	ProfileMode = 0b01000,
	DebugTracingMode = 0b10000,
}
