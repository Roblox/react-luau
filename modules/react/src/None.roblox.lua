--!strict
-- code derived from https://github.com/Roblox/roact/blob/master/src/None.lua
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
local LuauPolyfill = require(Packages.LuauPolyfill)

-- Roact uses `Object.assign` internally to assign new state values; the same
-- None value should give us the proper semantics. We can re-export this value
-- as React.None for easy use, and to mirror Roact.None in legacy Roact.
return LuauPolyfill.Object.None
