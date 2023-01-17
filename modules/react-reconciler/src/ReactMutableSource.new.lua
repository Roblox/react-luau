-- ROBLOX upstream: https://github.com/facebook/react/blob/142d4f1c00c66f3d728177082dbc027fd6335115/packages/react-reconciler/src/ReactMutableSource.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

local Packages = script.Parent.Parent
-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console

type Array<T> = { [number]: T }
local exports = {}

local ReactTypes = require(Packages.Shared)
type MutableSource<T> = ReactTypes.MutableSource<T>
type MutableSourceVersion = ReactTypes.MutableSourceVersion

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type FiberRoot = ReactInternalTypes.FiberRoot

local isPrimaryRenderer = require(script.Parent.ReactFiberHostConfig).isPrimaryRenderer

-- Work in progress version_ numbers only apply to a single render,
-- and should be reset before starting a new render.
-- This tracks which mutable sources need to be reset after a render.
local workInProgressSources: Array<MutableSource<any>> = {}

local rendererSigil
if _G.__DEV__ then
	-- Used to detect multiple renderers using the same mutable source.
	rendererSigil = {}
end

exports.markSourceAsDirty = function(mutableSource: MutableSource<any>)
	table.insert(workInProgressSources, mutableSource)
end

exports.resetWorkInProgressVersions = function()
	for i, mutableSource in workInProgressSources do
		if isPrimaryRenderer then
			mutableSource._workInProgressVersionPrimary = nil
		else
			mutableSource._workInProgressVersionSecondary = nil
		end
	end
	table.clear(workInProgressSources)
end

exports.getWorkInProgressVersion =
	function(mutableSource: MutableSource<any>): nil | MutableSourceVersion
		if isPrimaryRenderer then
			return mutableSource._workInProgressVersionPrimary
		else
			return mutableSource._workInProgressVersionSecondary
		end
	end

exports.setWorkInProgressVersion =
	function(mutableSource: MutableSource<any>, version_: MutableSourceVersion)
		if isPrimaryRenderer then
			mutableSource._workInProgressVersionPrimary = version_
		else
			mutableSource._workInProgressVersionSecondary = version_
		end
		table.insert(workInProgressSources, mutableSource)
	end

exports.warnAboutMultipleRenderersDEV = function(mutableSource: MutableSource<any>)
	if _G.__DEV__ then
		if isPrimaryRenderer then
			if mutableSource._currentPrimaryRenderer == nil then
				mutableSource._currentPrimaryRenderer = rendererSigil
			elseif mutableSource._currentPrimaryRenderer ~= rendererSigil then
				console.error(
					"Detected multiple renderers concurrently rendering the "
						.. "same mutable source. This is currently unsupported."
				)
			end
		else
			if mutableSource._currentSecondaryRenderer == nil then
				mutableSource._currentSecondaryRenderer = rendererSigil
			elseif mutableSource._currentSecondaryRenderer ~= rendererSigil then
				console.error(
					"Detected multiple renderers concurrently rendering the "
						.. "same mutable source. This is currently unsupported."
				)
			end
		end
	end
end

-- Eager reads the version of a mutable source and stores it on the root.
-- This ensures that the version used for server rendering matches the one
-- that is eventually read during hydration.
-- If they don't match there's a potential tear and a full deopt render is required.
exports.registerMutableSourceForHydration =
	function(root: FiberRoot, mutableSource: MutableSource<any>)
		local getVersion = mutableSource._getVersion
		local version_ = getVersion(mutableSource._source)

		-- TODO Clear this data once all pending hydration work is finished.
		-- Retaining it forever may interfere with GC.
		if root.mutableSourceEagerHydrationData == nil then
			root.mutableSourceEagerHydrationData = { mutableSource, version_ }
		else
			-- ROBLOX FIXME: having trouble with type coercion in this case
			-- table.insert(root.mutableSourceEagerHydrationData, mutableSource)
			-- table.insert(root.mutableSourceEagerHydrationData, version_)
		end
	end

return exports
