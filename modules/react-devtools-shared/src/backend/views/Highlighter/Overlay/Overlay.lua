-- Based on: https://github.com/facebook/react/blob/3e94bce765d355d74f6a60feb4addb6d196e3482/packages/react-devtools-shared/src/backend/views/Highlighter/Overlay.js

local PackageRoot = script.Parent.Parent.Parent.Parent.Parent

local Packages = PackageRoot.Parent
local ReactGlobals = require(Packages.ReactGlobals)
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array

local BackendTypes = require(PackageRoot.backend.types)
type DevToolsHook = BackendTypes.DevToolsHook

local OverlayRect = require(script.Parent.OverlayRect)
local OverlayTip = require(script.Parent.OverlayTip)
type OverlayRect = OverlayRect.OverlayRect

local function getNestedBoundingClientRect(node: GuiBase2d): Rect
	local bounds = node.AbsoluteSize
	local position = node.AbsolutePosition
	return Rect.new(position, position + bounds)
end

local Overlay = {}
Overlay.__index = Overlay

function Overlay.new()
	local self = setmetatable({}, Overlay)
	self.layerCollector = nil :: LayerCollector?

	-- We use a Folder to exempt the overlay from any external layout
	-- influences.
	self.container = Instance.new("Folder")
	self.container.Name = "REACT_DEVTOOLS_OVERLAY"

	-- Use a button to sink inputs under the overlay when clicking
	self.containerFrame = Instance.new("ImageButton")
	self.containerFrame.Name = "OverlayContainer"
	self.containerFrame.Size = UDim2.fromScale(1, 1)
	self.containerFrame.BackgroundTransparency = 1
	self.containerFrame.Image = ""
	self.containerFrame.ZIndex = 1_000_000
	self.containerFrame.Parent = self.container

	self.rectContainer = Instance.new("CanvasGroup")
	self.rectContainer.Name = "OverlayRects"
	self.rectContainer.Size = UDim2.fromScale(1, 1)
	self.rectContainer.BackgroundTransparency = 1
	self.rectContainer.GroupTransparency = 0.3
	self.rectContainer.ZIndex = 1_000_000 + 1
	self.rectContainer.Parent = self.containerFrame

	self.tip = OverlayTip.new(self.containerFrame)
	self.rects = {} :: { OverlayRect }

	return self
end

export type Overlay = typeof(Overlay.new(...))

function Overlay.remove(self: Overlay)
	self.tip:remove()
	for _, rect in self.rects do
		rect:remove()
	end
	table.clear(self.rects)
	self.container.Parent = nil
end

function Overlay.inspect(self: Overlay, nodes: { GuiBase2d }, name: string?)
	-- Get a common layer collector and discard any nodes with a different one
	-- It should be a rare case where one fiber has multiple layer collectors
	-- but it can happen with portals. In that case, some of the nodes won't
	-- be highlighted.
	self.layerCollector = nodes[1]:FindFirstAncestorWhichIsA("LayerCollector")
	if self.layerCollector == nil then
		for _, node in nodes do
			if node:IsA("LayerCollector") then
				self.layerCollector = node
				break
			end
		end
	end

	self.container.Parent = self.layerCollector
	local elements = Array.filter(nodes, function(node: GuiBase2d)
		return node:IsA("LayerCollector")
			or (
				if self.layerCollector
					then node:IsDescendantOf(self.layerCollector)
					else false
			)
	end)

	-- Remove extra rects
	for i = #elements + 1, #self.rects do
		self.rects[i]:remove()
	end

	if #elements == 0 then
		return
	end

	while #self.rects < #elements do
		table.insert(self.rects, OverlayRect.new(self.rectContainer))
	end

	local outerBox = {
		top = math.huge,
		right = -math.huge,
		bottom = -math.huge,
		left = math.huge,
	}
	for index, element in elements do
		local box = getNestedBoundingClientRect(element)

		outerBox.top = math.min(outerBox.top, box.Min.Y)
		outerBox.right = math.max(outerBox.right, box.Max.X)
		outerBox.bottom = math.max(outerBox.bottom, box.Max.Y)
		outerBox.left = math.min(outerBox.left, box.Min.X)

		local rect = self.rects[index]
		rect:update(element)
	end

	if name == nil or name == "" then
		local node = elements[1]
		name = node.Name

		local hook: DevToolsHook? = ReactGlobals.__REACT_DEVTOOLS_GLOBAL_HOOK__
		if hook ~= nil and hook.rendererInterfaces ~= nil then
			local ownerName = nil
			for _, rendererInterface in hook.rendererInterfaces:values() do
				local id = rendererInterface.getFiberIDForNative(node, true)
				if id ~= nil then
					ownerName = rendererInterface.getDisplayNameForFiberID(id, true)
					break
				end
			end

			if ownerName ~= nil then
				name = `{name} (in {ownerName})`
			end
		end
	end

	self.tip:updateText(
		name,
		outerBox.right - outerBox.left,
		outerBox.bottom - outerBox.top
	)

	local tipBoundsWindow: GuiBase2d = if self.layerCollector
		then self.layerCollector
		elseif elements[1]:IsA("LayerCollector") then elements[1]
		else nil
	local tipBounds = if tipBoundsWindow
		then getNestedBoundingClientRect(tipBoundsWindow)
		else Rect.new(Vector2.new(0, 0), Vector2.new(math.huge, math.huge))

	self.tip:updatePosition({
		top = outerBox.top,
		left = outerBox.left,
		height = outerBox.bottom - outerBox.top,
		width = outerBox.right - outerBox.left,
	}, {
		top = tipBounds.Min.Y,
		left = tipBounds.Min.X,
		height = tipBounds.Height,
		width = tipBounds.Width,
	})
end

return {
	new = Overlay.new,
}
