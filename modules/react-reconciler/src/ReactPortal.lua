-- ROBLOX upstream: https://github.com/facebook/react/blob/142d4f1c00c66f3d728177082dbc027fd6335115/packages/react-reconciler/src/ReactPortal.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Packages = script.Parent.Parent

local REACT_PORTAL_TYPE = require(Packages.Shared).ReactSymbols.REACT_PORTAL_TYPE

local ReactTypes = require(Packages.Shared)
type ReactNodeList = ReactTypes.ReactNodeList
type ReactPortal = ReactTypes.ReactPortal

local function createPortal(
	children: ReactNodeList,
	containerInfo: any,
	-- TODO: figure out the API for cross-renderer implementation.
	implementation: any,
	key: string?
): ReactPortal
	if key ~= nil then
		key = tostring(key)
	end
	return {
		-- This tag allow us to uniquely identify this as a React Portal
		["$$typeof"] = REACT_PORTAL_TYPE,
		key = key,
		children = children,
		containerInfo = containerInfo,
		implementation = implementation,
	}
end

return {
	createPortal = createPortal,
}
