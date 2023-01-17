--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/142d4f1c00c66f3d728177082dbc027fd6335115/packages/react/src/ReactMutableSource.js
-- [[
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
-- ]]

local Packages = script.Parent.Parent
local ReactTypes = require(Packages.Shared)
type MutableSourceGetVersionFn = ReactTypes.MutableSourceGetVersionFn
type MutableSource<T> = ReactTypes.MutableSource<T>

local function createMutableSource<Source>(
	source: Source,
	getVersion: MutableSourceGetVersionFn
): MutableSource<Source>
	local mutableSource: MutableSource<Source> = {
		_getVersion = getVersion,
		_source = source,
		_workInProgressVersionPrimary = nil,
		_workInProgressVersionSecondary = nil,
	}

	if _G.__DEV__ then
		mutableSource._currentPrimaryRenderer = nil
		mutableSource._currentSecondaryRenderer = nil
	end

	return mutableSource
end

return createMutableSource
