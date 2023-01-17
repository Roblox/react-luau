--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/9ac42dd074c42b66ecc0334b75200b1d2989f892/packages/react-reconciler/src/ReactFiberHostConfig.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

--[[ eslint-disable react-internal/invariant-args ]]

-- ROBLOX FIXME: Cannot carry types over via the module overriding that's in use
-- here; this is a particularly tricky case of cross-dependency type definitions
-- Use a common set of typedefs across ReactTestHostConfig and ReactRobloxHostTypes
type Object = { [string]: any }

export type Instance = Object
export type HostInstance = Instance
export type TextInstance = Instance
export type Container = Object
export type HostContext = Object
export type HydratableInstance = Instance | SuspenseInstance
export type SuspenseInstance = Object
export type PublicInstance = HostInstance

export type Type = string
export type Props = Object
export type ChildSet = {} -- void, unused
export type RendererInspectionConfig = Object

-- if _G.__NO_LOADMODULE__ then
local exports: { [string]: any } = {}
return exports
-- end

-- -- We expect that our Rollup, Jest, and Flow configurations
-- -- always shim this module with the corresponding host config
-- -- (either provided by a renderer, or a generic shim for npm).
-- --
-- -- We should never resolve to this file, but it exists to make
-- -- sure that if we *do* accidentally break the configuration,
-- -- the failure isn't silent.

-- -- deviation: FIXME (roblox): is there a way to configure luau to account for this module
-- -- being shimmed?
-- error('This module must be shimmed by a specific renderer.')
