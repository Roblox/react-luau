--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/d17086c7c813402a550d15a2f56dc43f1dbd1735/packages/react-reconciler/src/SchedulerWithReactIntegration.new.js
--[[
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

-- deviation: Type definition and values extracted from
-- SchedulerWithReactIntegration.new. This helps avoid a cyclic dependency that
-- can occur between SchedulerWithReactIntegration.new, ReactFiberLanes, and
-- various files that depend upon them

export type ReactPriorityLevel = number

local exports: { [string]: ReactPriorityLevel } = {
	-- // Except for NoPriority, these correspond to Scheduler priorities. We use
	-- // ascending numbers so we can compare them like numbers. They start at 90 to
	-- // avoid clashing with Scheduler's priorities.
	ImmediatePriority = 99,
	UserBlockingPriority = 98,
	NormalPriority = 97,
	LowPriority = 96,
	IdlePriority = 95,
	-- // NoPriority is the absence of priority. Also React-only.
	NoPriority = 90,
}

return exports
