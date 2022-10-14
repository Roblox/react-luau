--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/events.js
-- /*
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  */

local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Map = LuauPolyfill.Map
type Array<T> = LuauPolyfill.Array<T>
type Map<K, V> = LuauPolyfill.Map<K, V>
type Function = (...any) -> ...any
type ElementType<T, U> = any
type EventListener = (...ElementType<any, string>) -> ...any

export type EventEmitter<Events> = {
	listenersMap: Map<string, Array<Function>>,
	-- ROBLOX TODO: function generics <Event: $Keys<Events>>(
	addListener: (
		self: EventEmitter<Events>,
		event: string,
		listener: EventListener
	) -> (),
	-- ROBLOX TODO: function generics <Event: $Keys<Events>>(
	emit: (EventEmitter<Events>, string, ...ElementType<Events, string>) -> (),
	removeAllListeners: (EventEmitter<Events>) -> (),
	-- ROBLOX deviation: Luau doesn't support $Keys<Events> for first non-self param
	removeListener: (self: EventEmitter<Events>, event: string, listener: Function) -> (),
}
type EventEmitter_statics = {
	new: () -> EventEmitter<any>,
}
local EventEmitter: EventEmitter<any> & EventEmitter_statics =
	({} :: any) :: EventEmitter<any> & EventEmitter_statics
local EventEmitterMetatable = { __index = EventEmitter }

function EventEmitter.new(): EventEmitter<any>
	local self = {}
	self.listenersMap = Map.new()

	return (setmetatable(self, EventEmitterMetatable) :: any) :: EventEmitter<any>
end

function EventEmitter:addListener(event: string, listener: EventListener): ()
	local listeners = self.listenersMap:get(event)
	if listeners == nil then
		self.listenersMap:set(event, { listener })
	else
		local index = Array.indexOf(listeners :: Array<EventListener>, listener)
		if index < 1 then
			table.insert(listeners, listener)
		end
	end
end

-- ROBLOX deviation: Luau doesn't support $Keys<Events> for first non-self param
function EventEmitter:emit(event: string, ...: ElementType<string, string>): ()
	local listeners = self.listenersMap:get(event)
	if listeners ~= nil then
		if #listeners == 1 then
			-- No need to clone or try/catch
			local listener = listeners[1]
			listener(...)
		else
			local didThrow = false
			local caughtError = nil
			local clonedListeners = table.clone(listeners)
			for _, listener in clonedListeners do
				local ok, error_ = pcall(function(...)
					listener(...)
					return nil
				end, ...)
				if not ok then
					didThrow = true
					caughtError = error_
				end
			end
			if didThrow then
				error(caughtError)
			end
		end
	end
end

function EventEmitter:removeAllListeners(): ()
	self.listenersMap:clear()
end

-- ROBLOX deviation: Luau doesn't support $Keys<Events> for first non-self param
function EventEmitter:removeListener(event: string, listener: Function): ()
	local listeners = self.listenersMap:get(event)

	if listeners ~= nil then
		local index = Array.indexOf(listeners, listener)

		if index >= 1 then
			Array.splice(listeners, index, 1)
		end
	end
end

return EventEmitter
