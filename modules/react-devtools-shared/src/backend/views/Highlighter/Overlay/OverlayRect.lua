local OverlayRect = {}
OverlayRect.__index = OverlayRect

function OverlayRect.new(container: GuiBase2d)
	local self = setmetatable({}, OverlayRect)
	self.container = container

	local node = Instance.new("Frame")
	node.Name = "OverlayRect"
	node.BackgroundTransparency = 1
	node.Parent = container
	self.node = node

	local padding = Instance.new("Frame")
	padding.Name = "OverlayRectPadding"
	padding.BackgroundColor3 = Color3.fromRGB(77, 200, 0)
	padding.Size = UDim2.fromScale(1, 1)
	padding.BackgroundTransparency = 0.4
	padding.BorderSizePixel = 0
	padding.Parent = node
	self.padding = padding

	local content = Instance.new("Frame")
	content.Name = "OverlayRectContent"
	content.BackgroundColor3 = Color3.fromRGB(120, 170, 210)
	content.Size = UDim2.fromScale(1, 1)
	content.BorderSizePixel = 0
	content.ZIndex = 2
	content.Parent = node
	self.content = content

	return self
end

export type OverlayRect = typeof(OverlayRect.new(...))

function OverlayRect.remove(self: OverlayRect)
	self.node:Destroy()
end

function OverlayRect.update(self: OverlayRect, element: GuiBase2d)
	local size = element.AbsoluteSize
	local position = element.AbsolutePosition

	local padding = element:FindFirstChildOfClass("UIPadding")
	if padding then
		local top = (padding.PaddingTop.Scale * size.Y) + padding.PaddingTop.Offset
		local left = (padding.PaddingLeft.Scale * size.X) + padding.PaddingLeft.Offset
		local bottom = (padding.PaddingBottom.Scale * size.Y)
			+ padding.PaddingBottom.Offset
		local right = (padding.PaddingRight.Scale * size.X) + padding.PaddingRight.Offset

		self.content.Position = UDim2.fromOffset(left, top)
		self.content.Size = UDim2.fromOffset(size.X - left - right, size.Y - top - bottom)
	else
		self.content.Position = UDim2.fromOffset(0, 0)
		self.content.Size = UDim2.fromOffset(size.X, size.Y)
	end

	self.node.Size = UDim2.fromOffset(size.X, size.Y)
	self.node.Position = UDim2.fromOffset(position.X, position.Y)
end

return {
	new = OverlayRect.new,
}
