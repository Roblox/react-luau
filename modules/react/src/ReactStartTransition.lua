--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/34aa5cfe0d9b6ec4667e02bf46ab34d83dfb2d6d/packages/react/src/ReactStartTransition.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Packages = script.Parent.Parent
local ReactGlobals = require(Packages.ReactGlobals)
local LuauPolyfill = require(Packages.LuauPolyfill)
local Set = LuauPolyfill.Set
local ReactTypes = require(Packages.Shared)
local console = ReactTypes.console
local ReactFeatureFlags = ReactTypes.ReactFeatureFlags
local ReactCurrentBatchConfig = ReactTypes.ReactSharedInternals.ReactCurrentBatchConfig

export type StartTransitionOptions = ReactTypes.StartTransitionOptions

local function startTransition(scope: () -> (), options: StartTransitionOptions?): ()
	local prevTransition = ReactCurrentBatchConfig.transition
	ReactCurrentBatchConfig.transition = {}
	local currentTransition = ReactCurrentBatchConfig.transition

	if ReactGlobals.__DEV__ then
		currentTransition._updatedFibers = Set.new()
	end

	if ReactFeatureFlags.enableTransitionTracing then
		if options ~= nil and options.name ~= nil then
			currentTransition.name = options.name
			currentTransition.startTime = -1
		end
	end

	local ok, result = pcall(scope)
	ReactCurrentBatchConfig.transition = prevTransition

	if ReactGlobals.__DEV__ and currentTransition._updatedFibers ~= nil then
		if prevTransition == nil and currentTransition._updatedFibers.size > 10 then
			console.warn(
				"Detected a large number of updates inside startTransition. "
					.. "If this is due to a subscription please re-write it to use React provided hooks. "
					.. "Otherwise concurrent mode guarantees are off the table."
			)
		end
		currentTransition._updatedFibers:clear()
	end

	if not ok then
		error(result, 0)
	end
end

return {
	startTransition = startTransition,
}
