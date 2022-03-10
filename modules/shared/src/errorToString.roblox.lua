--!strict
local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
type Error = LuauPolyfill.Error
type Object = LuauPolyfill.Object
type Array<T> = LuauPolyfill.Array<T>
local inspect = LuauPolyfill.util.inspect

return function(error_: Error | Object | string | Array<any>): string
	local message
	if typeof(error_) == "table" then
		if (error_ :: Error).message and (error_ :: Error).stack then
			message = (error_ :: Error).message
				.. "\n"
				.. tostring((error_ :: Error).stack)
		else
			message = inspect(error_)
		end
	else
		message = inspect(error_)
	end

	return message
end
