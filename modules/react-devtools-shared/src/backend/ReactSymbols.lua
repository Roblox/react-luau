-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/backend/ReactSymbols.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]

-- ROBLOX deviation: It's not clear that Roblox requires separate copies of ReactSymbols, so this is forwarded for now
local Packages = script.Parent.Parent.Parent
return require(Packages.Shared).ReactSymbols
