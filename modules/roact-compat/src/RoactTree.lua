local Packages = script.Parent.Parent
local ReactRoblox = require(Packages.ReactRoblox)
local Shared = require(Packages.Shared)
local inspect = Shared.inspect.inspect

local warnOnce = require(script.Parent.warnOnce)

local function mount(element, parent, key)
	if _G.__DEV__ then
		warnOnce("mount", "Please use the createRoot API in ReactRoblox")
	end

	if parent ~= nil and typeof(parent) ~= "Instance" then
		error(string.format(
			"Cannot mount element (`%s`) into a parent that is not a Roblox Instance (got type `%s`) \n%s",
			(function()
				if element then
					return tostring(element.type)
				end
				return "<unknown>"
			end)(),
			typeof(parent),
			(function()
				if parent ~= nil then
					return inspect(parent)
				end
				return ""
			end)()
		))
	end

	local rootInstance = parent

	if rootInstance == nil then
		rootInstance = Instance.new("Folder")
		rootInstance.Name = key or "ReactLegacyRoot"
	end

	local root = ReactRoblox.createLegacyRoot(rootInstance)
	root:render(element)

	return root
end

local function update(root, element)
	if _G.__DEV__ then
		warnOnce("update", "Please use the createRoot API in ReactRoblox")
	end

	root:render(element)
	return root
end

local function unmount(root)
	if _G.__DEV__ then
		warnOnce("unmount", "Please use the createRoot API in ReactRoblox")
	end
	root:unmount()
end

return {
	mount = mount,
	update = update,
	unmount = unmount,
}
