--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/efd8f6442d1aa7c4566fe812cba03e7e83aaccc3/packages/react-native-renderer/index.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local HostTypes = require(script.client["ReactRobloxHostTypes.roblox"])
export type RootType = HostTypes.RootType
return require(script.client.ReactRoblox)
