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

	-- Since we use portals to actually parent to the provided parent argument,
	-- the container instance that we provide to createLegacyRoot is just a
	-- dummy instance.
	local root = ReactRoblox.createLegacyRoot(Instance.new("Folder"))
	if parent == nil then
		parent = Instance.new("Folder")
		parent.Name = "Target"
	end
	if key == nil then
		key = "ReactLegacyRoot"
	end
	root:render(ReactRoblox.createPortal({ [key] = element }, parent))

	return {
		root = root,
		-- To preserve the same key and portal to the same parent on update, we
		-- need to stash them in the opaque "tree" reference returned by `mount`
		parent = parent,
		key = key,
	}
end

local function update(roactHandle, element)
	if _G.__DEV__ then
		warnOnce("update", "Please use the createRoot API in ReactRoblox")
	end

	local key = roactHandle.key
	local parent = roactHandle.parent
	roactHandle.root:render(ReactRoblox.createPortal({ [key] = element }, parent))

	return roactHandle
end

local function unmount(roactHandle)
	if _G.__DEV__ then
		warnOnce("unmount", "Please use the createRoot API in ReactRoblox")
	end
	roactHandle.root:unmount()
end

return {
	mount = mount,
	update = update,
	unmount = unmount,
}
