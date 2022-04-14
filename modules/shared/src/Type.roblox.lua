--[[
	Contains markers for annotating objects with types.

	To set the type of an object, use `Type` as a key and the actual marker as
	the value:

		local foo = {
			[Type] = Type.Foo,
		}
]]

local Symbol = require(script.Parent["Symbol.roblox"])

local Type = newproxy(true)

local TypeInternal = {}

local function addType(name)
	TypeInternal[name] = Symbol.named("Roact" .. name)
end

addType("HostChangeEvent")
addType("HostEvent")

function TypeInternal.of(value)
	if typeof(value) ~= "table" then
		return nil
	end

	return value[Type]
end

getmetatable(Type).__index = TypeInternal

getmetatable(Type).__tostring = function()
	return "RoactType"
end

return Type
