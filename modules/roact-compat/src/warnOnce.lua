--!strict
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
