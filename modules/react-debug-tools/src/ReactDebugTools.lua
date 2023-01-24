-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.2/packages/react-debug-tools/src/ReactDebugTools.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]
local exports = {}
local reactDebugHooksModule = require(script.Parent.ReactDebugHooks)
-- ROBLOX deviation START: add re-exporting of types
export type HooksNode = reactDebugHooksModule.HooksNode
export type HooksTree = reactDebugHooksModule.HooksTree
-- ROBLOX deviation END
local inspectHooks = reactDebugHooksModule.inspectHooks
local inspectHooksOfFiber = reactDebugHooksModule.inspectHooksOfFiber
exports.inspectHooks = inspectHooks
exports.inspectHooksOfFiber = inspectHooksOfFiber
return exports
