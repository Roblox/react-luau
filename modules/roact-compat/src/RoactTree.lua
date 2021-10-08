--!strict
local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local inspect = LuauPolyfill.util.inspect
local ReactRoblox = require(Packages.ReactRoblox)
type RootType = ReactRoblox.RootType

local warnOnce = require(script.Parent.warnOnce)

local function mount(element: any, parent: any, key: string?)
	if _G.__DEV__ and _G.__COMPAT_WARNINGS__ then
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

type RoactHandle = {
	root: RootType,
	key: string | number,
	parent: any, -- ROBLOX TODO: Instance?
}

local function update(roactHandle: RoactHandle, element)
	if _G.__DEV__ then
		warnOnce("update", "Please use the createRoot API in ReactRoblox")
	end

	local key = roactHandle.key
	local parent = roactHandle.parent
	roactHandle.root:render(ReactRoblox.createPortal({ [key] = element }, parent))

	return roactHandle
end

local function unmount(roactHandle: RoactHandle)
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
