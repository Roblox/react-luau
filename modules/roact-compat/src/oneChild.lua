-- ROBLOX upstream: https://github.com/Roblox/roact/blob/master/src/oneChild.lua
--[[
	* Copyright (c) Roblox Corporation. All rights reserved.
	* Licensed under the Apache License, Version 2.0 (the "License");
	* you may not use this file except in compliance with the License.
	* You may obtain a copy of the License at
	*
	*     http://www.apache.org/licenses/LICENSE-2.0
	*
	* Unless required by applicable law or agreed to in writing, software
	* distributed under the License is distributed on an "AS IS" BASIS,
	* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	* See the License for the specific language governing permissions and
	* limitations under the License.
]]
local Packages = script.Parent.Parent
local React = require(Packages.React)

local warnOnce = require(script.Parent.warnOnce)

local function oneChild(children)
	if _G.__DEV__ and _G.__COMPAT_WARNINGS__ then
		warnOnce(
			"oneChild",
			"You likely don't need this at all! If you were assigning children "
				.. "via `React.oneChild(someChildren)`, you can simply use "
				.. "`someChildren` directly."
		)
	end

	-- This behavior is a bit different from upstream, so we're adapting current
	-- Roact's logic (which will unwrap a table with a single member)
	if not children then
		return nil
	end

	local key, child = next(children)

	if not child then
		return nil
	end

	local after = next(children, key)

	if after then
		error("Expected at most one child, had more than one child.", 2)
	end

	return React.Children.only(child)
end

return oneChild
