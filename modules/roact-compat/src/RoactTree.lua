local Packages = script.Parent.Parent
local ReactRoblox = require(Packages.ReactRoblox)
local inspect = require(Packages.Shared).inspect.inspect

local warnOnce = require(script.Parent.warnOnce)

local function mount(element, parent, key)
	if _G.__DEV__ then
		warnOnce("mount", "Please use the createRoot API in ReactRoblox")
	end

	local rootInstance = Instance.new("Folder")

	local root = ReactRoblox.createLegacyRoot(rootInstance)
	root:render(element)

	if parent ~= nil and typeof(parent) ~= "Instance" then
		warnOnce("mount invalid argument", "Cannot mount into a parent that is not a Roblox Instance\n" .. inspect(parent))
	else
		rootInstance.Parent = parent
	end
	if key ~= nil then
		rootInstance.Name = key
	else
		rootInstance.Name = "ReactLegacyRoot"
	end

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
