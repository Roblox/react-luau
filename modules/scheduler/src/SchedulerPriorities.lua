--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/00748c53e183952696157088a858352cc77b0010/packages/scheduler/src/SchedulerHostConfig.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
* @flow
]]

export type PriorityLevel = number

-- TODO: Use symbols?
return {
	NoPriority = 0,
	ImmediatePriority = 1,
	UserBlockingPriority = 2,
	NormalPriority = 3,
	LowPriority = 4,
	IdlePriority = 5,
}
