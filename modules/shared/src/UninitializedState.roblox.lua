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
--!strict
local console = require(script.Parent.console)

-- ROBLOX DEVIATION: Initialize state to a singleton that warns on access and errors on assignment
-- initial state singleton
local UninitializedState = {}

setmetatable(UninitializedState, {
	__index = function(table, key)
		if _G.__DEV__ then
			console.warn(
				"Attempted to access uninitialized state. Use setState to initialize state"
			)
		end
		return nil
	end,
	__newindex = function(table, key)
		if _G.__DEV__ then
			console.error(
				"Attempted to directly mutate state. Use setState to assign new values to state."
			)
		end
		return nil
	end,
	__tostring = function(self)
		return "<uninitialized component state>"
	end,
	__metatable = "UninitializedState",
})

return UninitializedState
