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
local React = require(Packages.React)

local warnOnce = require(script.Parent.warnOnce)

return function(elements)
	if _G.__DEV__ and _G.__COMPAT_WARNINGS__ then
		warnOnce(
			"createFragment",
			"Please instead use:\n\tReact.createElement(React.Fragment, ...)"
		)
	end
	return React.createElement(React.Fragment, nil, elements)
end
