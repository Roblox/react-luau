--!strict
--[[
	* Copyright (c) Roblox Corporation. All rights reserved.
	* Licensed under the MIT License (the "License");
	* you may not use this file except in compliance with the License.
	* You may obtain a copy of the License at
	*
	*     https://opensource.org/licenses/MIT
	*
	* Unless required by applicable law or agreed to in writing, software
	* distributed under the License is distributed on an "AS IS" BASIS,
	* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	* See the License for the specific language governing permissions and
	* limitations under the License.
]]

local Packages = script.Parent.Parent
local console = require(Packages.Shared).console

local warnedAbout = {}

local function warnOnce(name: string, message: string)
	if not warnedAbout[name] then
		console.warn(
			"The legacy Roact API '%s' is deprecated, and will be removed "
				.. "in a future release.\n\n%s",
			name,
			message
		)
	end
	warnedAbout[name] = true
end

return warnOnce
