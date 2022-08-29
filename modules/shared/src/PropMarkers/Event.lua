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
--[[
	Index into `Event` to get a prop key for attaching to an event on a Roblox
	Instance.

	Example:

		Roact.createElement("TextButton", {
			Text = "Hello, world!",

			[Roact.Event.MouseButton1Click] = function(rbx)
				print("Clicked", rbx)
			end
		})
]]

local Type = require(script.Parent.Parent["Type.roblox"])

local Event = {}

local eventMetatable = {
	__tostring = function(self)
		return string.format("RoactHostEvent(%s)", self.name)
	end,
}

setmetatable(Event, {
	__index = function(self, eventName)
		local event = {
			[Type] = Type.HostEvent,
			name = eventName,
		}

		setmetatable(event, eventMetatable)

		Event[eventName] = event

		return event
	end,
})

return Event
