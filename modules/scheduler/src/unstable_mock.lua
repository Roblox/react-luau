--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
*]]
local Tracing = require(script.Parent.Tracing)
local TracingSubscriptions = require(script.Parent.TracingSubscriptions)
-- ROBLOX deviation: export Tracing type from the package exports to avoid direct file access
export type Interaction = Tracing.Interaction

local initializeScheduler = require(script.Parent.Scheduler)
local HostConfig = require(script.Parent.forks["SchedulerHostConfig.mock"])

local Scheduler = initializeScheduler(HostConfig)

local exports = {}
exports.tracing = {}
-- ROBLOX FIXME Luau: need to fix CLI-56768 to remove any casts
for key, value in Scheduler :: any do
	exports[key] = value
end
for key, value in Tracing :: any do
	exports.tracing[key] = value
end
for key, value in TracingSubscriptions :: any do
	exports.tracing[key] = value
end

exports.unstable_flushAllWithoutAsserting = HostConfig.unstable_flushAllWithoutAsserting
exports.unstable_flushNumberOfYields = HostConfig.unstable_flushNumberOfYields
exports.unstable_flushExpired = HostConfig.unstable_flushExpired
exports.unstable_clearYields = HostConfig.unstable_clearYields
exports.unstable_flushUntilNextPaint = HostConfig.unstable_flushUntilNextPaint
exports.unstable_flushAll = HostConfig.unstable_flushAll
exports.unstable_yieldValue = HostConfig.unstable_yieldValue
exports.unstable_advanceTime = HostConfig.unstable_advanceTime
exports.unstable_Profiling = Scheduler.unstable_Profiling

return exports
