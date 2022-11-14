--!strict
-- ROBLOX deviation: this is an extraction of a single state field
-- (and associated mutation/getters) from ReactFiberWorkLooop.new
-- which allows us to break dependency cycles involving that module
-- ROBLOX upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react-reconciler/src/ReactFiberWorkLoop.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local ReactFiberLane = require(script.Parent.ReactFiberLane)
local _workInProgressRootSkippedLanes: Lanes = ReactFiberLane.NoLanes
local mergeLanes = ReactFiberLane.mergeLanes
type Lanes = ReactFiberLane.Lanes
type Lane = ReactFiberLane.Lane

local exports = {}

-- ROBLOX TODO: turn this into newindex property accessor
exports.workInProgressRootSkippedLanes = function(value: Lanes?): Lanes
	if value == nil then
		return _workInProgressRootSkippedLanes
	end

	-- ROBLOX FIXME Luau: Luau should narrow based on guard above
	_workInProgressRootSkippedLanes = value :: Lanes
	return _workInProgressRootSkippedLanes
end

exports.markSkippedUpdateLanes = function(lane: Lane | Lanes): ()
	_workInProgressRootSkippedLanes = mergeLanes(lane, _workInProgressRootSkippedLanes)
end

return exports
