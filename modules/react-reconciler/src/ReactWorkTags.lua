-- ROBLOX upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react-reconciler/src/ReactWorkTags.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

export type WorkTag = number

return {
	FunctionComponent = 0,
	ClassComponent = 1,
	IndeterminateComponent = 2, -- Before we know whether it is function or class
	HostRoot = 3, -- Root of a host tree. Could be nested inside another node.
	HostPortal = 4, -- A subtree. Could be an entry point to a different renderer.
	HostComponent = 5,
	HostText = 6,
	Fragment = 7,
	Mode = 8,
	ContextConsumer = 9,
	ContextProvider = 10,
	ForwardRef = 11,
	Profiler = 12,
	SuspenseComponent = 13,
	MemoComponent = 14,
	SimpleMemoComponent = 15,
	LazyComponent = 16,
	IncompleteClassComponent = 17,
	DehydratedFragment = 18,
	SuspenseListComponent = 19,
	FundamentalComponent = 20,
	ScopeComponent = 21,
	Block = 22,
	OffscreenComponent = 23,
	LegacyHiddenComponent = 24,
}
