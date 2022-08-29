-- ROBLOX upstream: https://github.com/facebook/react/blob/43363e2795393a00fd77312a16d6b80e626c29de/packages/react-reconciler/src/index.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

--!strict
local ReactInternalTypes = require(script.ReactInternalTypes)
local ReactRootTags = require(script.ReactRootTags)

export type Dispatcher = ReactInternalTypes.Dispatcher
export type Fiber = ReactInternalTypes.Fiber
export type FiberRoot = ReactInternalTypes.FiberRoot

-- ROBLOX deviation: explicit export for use in createReactNoop
export type UpdateQueue<T> = ReactInternalTypes.UpdateQueue<T>

export type RootTag = ReactRootTags.RootTag

-- ROBLOX deviation: In order to allow host config to be spliced in, we export
-- this top-level package as an initializer function that returns the configured
-- reconciler module
-- ROBLOX TODO: this effectively disconnects type checking from above to reconciler to below
local function initialize(config): { [string]: any }
	local ReactFiberHostConfig = require(script.ReactFiberHostConfig)
	for name, implementation in config do
		ReactFiberHostConfig[name] = implementation
	end

	return require(script.ReactFiberReconciler)
end

return initialize
