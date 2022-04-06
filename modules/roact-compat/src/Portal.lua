--!strict
local Packages = script.Parent.Parent
local ReactRoblox = require(Packages.ReactRoblox)

local warnOnce = require(script.Parent.warnOnce)

local function PortalComponent(props)
	if _G.__DEV__ and _G.__COMPAT_WARNINGS__ then
		warnOnce("Roact.Portal", "Please use the createPortal API on ReactRoblox instead")
	end
	return ReactRoblox.createPortal(props.children, props.target)
end

return PortalComponent
