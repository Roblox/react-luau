--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react-reconciler/src/ReactFiberErrorDialog.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

-- This module is forked in different environments.
-- By default, return `true` to log errors to the console.
-- Forks can return `false` if this isn't desirable.
local exports = {}

exports.showErrorDialog = function(boundary, errorInfo): boolean
	-- ROBLOX TODO: we may replace this with something that sends telemetry LUAFDN-222
	return true
end

return exports
