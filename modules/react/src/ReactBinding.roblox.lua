local Packages = script.Parent.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
local ReactSymbols = require(Packages.Shared).ReactSymbols

local Symbol = LuauPolyfill.Symbol
local createSignal = require(script.Parent["createSignal.roblox"])

local BindingImpl = Symbol("BindingImpl")

local BindingInternalApi = {}

local bindingPrototype = {}

function bindingPrototype:getValue()
	return BindingInternalApi.getValue(self)
end

function bindingPrototype:map(predicate)
	return BindingInternalApi.map(self, predicate)
end

local BindingPublicMeta = {
	__index = bindingPrototype,
	__tostring = function(self)
		return string.format("RoactBinding(%s)", tostring(self:getValue()))
	end,
}

function BindingInternalApi.update(binding, newValue)
	return binding[BindingImpl].update(newValue)
end

function BindingInternalApi.subscribe(binding, callback)
	return binding[BindingImpl].subscribe(callback)
end

function BindingInternalApi.getValue(binding)
	return binding[BindingImpl].getValue()
end

function BindingInternalApi.create(initialValue)
	local impl = {
		value = initialValue,
		changeSignal = createSignal(),
	}

	function impl.subscribe(callback)
		return impl.changeSignal:subscribe(callback)
	end

	function impl.update(newValue)
		impl.value = newValue
		impl.changeSignal:fire(newValue)
	end

	function impl.getValue()
		return impl.value
	end

	local source
	if _G.__DEV__ then
		-- ROBLOX TODO: LUAFDN-619 - improve debug stacktraces for bindings
		source = debug.traceback("Binding created at:", 3)
	end

	return setmetatable({
		["$$typeof"] = ReactSymbols.REACT_BINDING_TYPE,
		[BindingImpl] = impl,
		_source = source,
	}, BindingPublicMeta), impl.update
end

function BindingInternalApi.map(upstreamBinding, predicate)
	if _G.__DEV__ then
		-- ROBLOX TODO: More informative error messages here
		assert(
			typeof(upstreamBinding) == "table" and upstreamBinding["$$typeof"] == ReactSymbols.REACT_BINDING_TYPE,
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

	return setmetatable({
		["$$typeof"] = ReactSymbols.REACT_BINDING_TYPE,
		[BindingImpl] = impl,
		_source = source,
	}, BindingPublicMeta)
end

function BindingInternalApi.join(upstreamBindings)
	if _G.__DEV__ then
		assert(typeof(upstreamBindings) == "table", "Expected arg #1 to be of type table")

		for key, value in pairs(upstreamBindings) do
			if typeof(value) ~= "table" or value["$$typeof"] ~= ReactSymbols.REACT_BINDING_TYPE then
				local message = (
					"Expected arg #1 to contain only bindings, but key %q had a non-binding value"
				):format(
					tostring(key)
				)
				error(message, 2)
			end
		end
	end

	local impl = {}

	local function getValue()
		local value = {}

		for key, upstream in pairs(upstreamBindings) do
			value[key] = upstream:getValue()
		end

		return value
	end

	function impl.subscribe(callback)
		-- ROBLOX FIXME: type refinements
		local disconnects: any = {}

		for key, upstream in pairs(upstreamBindings) do
			disconnects[key] = BindingInternalApi.subscribe(upstream, function(newValue)
				callback(getValue())
			end)
		end

		return function()
			if disconnects == nil then
				return
			end

			for _, disconnect in pairs(disconnects) do
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

	return setmetatable({
		["$$typeof"] = ReactSymbols.REACT_BINDING_TYPE,
		[BindingImpl] = impl,
		_source = source,
	}, BindingPublicMeta)
end

return BindingInternalApi