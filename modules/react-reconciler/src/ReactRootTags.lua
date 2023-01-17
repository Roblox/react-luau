-- ROBLOX upstream: https://github.com/facebook/react/blob/c5d2fc7127654e43de59fff865b74765a103c4a5/packages/react-reconciler/src/ReactRootTags.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

export type RootTag = number

return {
	LegacyRoot = 0,
	BlockingRoot = 1,
	ConcurrentRoot = 2,
}
