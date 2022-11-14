--!strict
-- ROBLOX upstream: https://github.com/Roblox/roact/blob/master/src/createSignal.lua
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

type Function = (...any) -> ...any
--[[
	This is a simple signal implementation that has a dead-simple API.

		local signal = createSignal()

		local disconnect = signal:subscribe(function(foo)
			print("Cool foo:", foo)
		end)

		signal:fire("something")

		disconnect()
]]

type Connection = { callback: Function, disconnected: boolean }
type Map<K, V> = { [K]: V }

local function createSignal(): ((Function) -> (() -> ()), (...any) -> ())
	local connections: Map<Function, Connection> = {}
	local suspendedConnections = {}
	local firing = false

	local function subscribe(callback)
		assert(
			typeof(callback) == "function",
			"Can only subscribe to signals with a function."
		)

		local connection = {
			callback = callback,
			disconnected = false,
		}

		-- If the callback is already registered, don't add to the suspendedConnection. Otherwise, this will disable
		-- the existing one.
		if firing and not connections[callback] then
			suspendedConnections[callback] = connection
		end

		connections[callback] = connection

		local function disconnect()
			assert(
				not connection.disconnected,
				"Listeners can only be disconnected once."
			)

			connection.disconnected = true
			connections[callback] = nil
			suspendedConnections[callback] = nil
		end

		return disconnect
	end

	local function fire(...)
		firing = true
		for callback, connection in connections do
			if not connection.disconnected and not suspendedConnections[callback] then
				callback(...)
			end
		end

		firing = false

		-- ROBLOX performance: use table.clear
		table.clear(suspendedConnections)
	end

	return subscribe, fire
end

return createSignal
