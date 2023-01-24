-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.2/packages/react-debug-tools/index.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 ]]
-- ROBLOX deviation START: simplify and re-export types
-- local Packages --[[ ROBLOX comment: must define Packages module ]]
-- local LuauPolyfill = require(Packages.LuauPolyfill)
-- local Object = LuauPolyfill.Object
-- local exports = {}
-- Object.assign(exports, require(script.src.ReactDebugTools))
-- return exports
local reactDebugToolsModule = require(script.ReactDebugTools)
export type HooksNode = reactDebugToolsModule.HooksNode
export type HooksTree = reactDebugToolsModule.HooksTree
return reactDebugToolsModule
-- ROBLOX deviation END
