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

local LuauPolyfill = require(Packages.LuauPolyfill)
local ReactSymbols = require(Packages.Shared).ReactSymbols

local ReactTypes = require(Packages.Shared)
type Binding<T> = ReactTypes.ReactBinding<T>
type BindingUpdater<T> = ReactTypes.ReactBindingUpdater<T>

local Symbol = LuauPolyfill.Symbol
local createSignal = require(script.Parent["createSignal.roblox"])

local BindingImpl = Symbol("BindingImpl")

type BindingInternal<T> = {
	["$$typeof"]: typeof(ReactSymbols.REACT_BINDING_TYPE),
	value: T,

	getValue: (BindingInternal<T>) -> T,
	-- FIXME Luau: can't define recursive types with different parameters
	map: <U>(BindingInternal<T>, (T) -> U) -> any,

	update: (T) -> (),
	subscribe: ((T) -> ()) -> (() -> ()),
}

local BindingInternalApi = {}

local bindingPrototype = {}

function bindingPrototype.getValue<T>(binding: BindingInternal<T>): T
	return BindingInternalApi.getValue(binding)
end

function bindingPrototype.map<T, U>(
	binding: BindingInternal<T>,
	predicate: (T) -> U
): Binding<U>
	return BindingInternalApi.map(binding, predicate)
end

local BindingPublicMeta = {
	__index = bindingPrototype,
	__tostring = function(self)
		return string.format("RoactBinding(%s)", tostring(self:getValue()))
	end,
}

function BindingInternalApi.update<T>(binding: any, newValue: T)
	return (binding[BindingImpl] :: BindingInternal<T>).update(newValue)
end

function BindingInternalApi.subscribe<T>(binding: any, callback: (T) -> ())
	return (binding[BindingImpl] :: BindingInternal<T>).subscribe(callback)
end

function BindingInternalApi.getValue<T>(binding: any): T
	return (binding[BindingImpl] :: BindingInternal<T>):getValue()
end

function BindingInternalApi.create<T>(initialValue: T): (Binding<T>, BindingUpdater<T>)
	local subscribe, fire = createSignal()
	local impl = {
		value = initialValue,
		subscribe = subscribe,
	}

	function impl.update(newValue: T)
		impl.value = newValue
		fire(newValue)
	end

	function impl.getValue()
		return impl.value
	end

	local source
	if _G.__DEV__ then
		-- ROBLOX TODO: LUAFDN-619 - improve debug stacktraces for bindings
		source = debug.traceback("Binding created at:", 3)
	end

	return (setmetatable({
		["$$typeof"] = ReactSymbols.REACT_BINDING_TYPE,
		[BindingImpl] = impl,
		_source = source,
	}, BindingPublicMeta) :: any) :: Binding<T>,
		impl.update
end

function BindingInternalApi.map<T, U>(
	upstreamBinding: BindingInternal<T>,
	predicate: (T) -> U
): Binding<U>
	if _G.__DEV__ then
		-- ROBLOX TODO: More informative error messages here
		assert(
			typeof(upstreamBinding) == "table"
				and upstreamBinding["$$typeof"] == ReactSymbols.REACT_BINDING_TYPE,
			"Expected `self` to be a binding"
		)
		assert(typeof(predicate) == "function", "Expected arg #1 to be a function")
	end

	local impl = {}

	function impl.subscribe(callback)
		return BindingInternalApi.subscribe(upstreamBinding, function(newValue)
			callback(predicate(newValue))
		end)
	end

	function impl.update(newValue)
		error("Bindings created by Binding:map(fn) cannot be updated directly", 2)
	end

	function impl.getValue()
		return predicate(upstreamBinding:getValue())
	end

	local source
	if _G.__DEV__ then
		-- ROBLOX TODO: LUAFDN-619 - improve debug stacktraces for bindings
		source = debug.traceback("Mapped binding created at:", 3)
	end

	return (
		setmetatable({
			["$$typeof"] = ReactSymbols.REACT_BINDING_TYPE,
			[BindingImpl] = impl,
			_source = source,
		}, BindingPublicMeta) :: any
	) :: Binding<U>
end

-- The `join` API is used statically, so the input will be a table with values
-- typed as the public Binding type
function BindingInternalApi.join<T>(
	upstreamBindings: { [string | number]: Binding<any> }
): Binding<T>
	if _G.__DEV__ then
		assert(typeof(upstreamBindings) == "table", "Expected arg #1 to be of type table")

		for key, value in upstreamBindings do
			if
				typeof(value) ~= "table"
				or (value :: any)["$$typeof"] ~= ReactSymbols.REACT_BINDING_TYPE
			then
				local message = ("Expected arg #1 to contain only bindings, but key %q had a non-binding value"):format(
					tostring(key)
				)
				error(message, 2)
			end
		end
	end

	local impl = {}

	local function getValue()
		local value = {}

		-- ROBLOX FIXME Luau: needs CLI-56711 resolved to eliminate ipairs()
		for key, upstream in pairs(upstreamBindings) do
			value[key] = upstream:getValue()
		end

		return value
	end

	function impl.subscribe(callback)
		-- ROBLOX FIXME: type refinements
		local disconnects: any = {}

		for key, upstream in upstreamBindings do
			disconnects[key] = BindingInternalApi.subscribe(upstream, function(newValue)
				callback(getValue())
			end)
		end

		return function()
			if disconnects == nil then
				return
			end

			for _, disconnect in disconnects do
				disconnect()
			end

			disconnects = nil
		end
	end

	function impl.update(newValue)
		error("Bindings created by joinBindings(...) cannot be updated directly", 2)
	end

	function impl.getValue()
		return getValue()
	end

	local source
	if _G.__DEV__ then
		-- ROBLOX TODO: LUAFDN-619 - improve debug stacktraces for bindings
		source = debug.traceback("Joined binding created at:", 2)
	end

	return (
		setmetatable({
			["$$typeof"] = ReactSymbols.REACT_BINDING_TYPE,
			[BindingImpl] = impl,
			_source = source,
		}, BindingPublicMeta) :: any
	) :: Binding<T>
end

return BindingInternalApi
