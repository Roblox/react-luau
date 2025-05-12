type Box = { top: number, left: number, width: number, height: number }

local function calculatePosition(dims: Box, bounds: Box, size: Vector2)
	local tipHeight = math.max(size.Y, 20)
	local tipWidth = math.max(size.X, 60)
	local margin = 5

	local top: number
	if dims.top + dims.height + tipHeight <= bounds.top + bounds.height then
		if dims.top + dims.height < bounds.top + 0 then
			top = bounds.top + margin
		else
			top = dims.top + dims.height + margin
		end
	elseif dims.top - tipHeight <= bounds.top + bounds.height then
		if dims.top - tipHeight - margin < bounds.top + margin then
			top = bounds.top + margin
		else
			top = dims.top - tipHeight - margin
		end
	else
		top = bounds.top + bounds.height - tipHeight - margin
	end

	local left = dims.left + margin
	if dims.left < bounds.left then
		left = bounds.left + margin
	end
	if dims.left + tipWidth > bounds.left + bounds.width then
		left = bounds.left + bounds.width - tipWidth - margin
	end

	return Vector2.new(left, top)
end

local OverlayTip = {}
OverlayTip.__index = OverlayTip

function OverlayTip.new(container: GuiBase2d)
	local self = setmetatable({}, OverlayTip)

	local background = Instance.new("Frame")
	background.Name = "OverlayTip"
	background.BackgroundColor3 = Color3.fromHex("#333740")
	background.AutomaticSize = Enum.AutomaticSize.XY
	background.Size = UDim2.fromScale(0, 0)
	background.BorderSizePixel = 0
	background.ZIndex = 1_000_000 + 1
	self.background = background

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalFlex = Enum.UIFlexAlignment.Fill
	layout.Padding = UDim.new(0, 6)
	layout.Parent = background

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.PaddingLeft = UDim.new(0, 6)
	padding.PaddingRight = UDim.new(0, 6)
	padding.Parent = background

	local cornerRadius = Instance.new("UICorner")
	cornerRadius.CornerRadius = UDim.new(0, 2)
	cornerRadius.Parent = background

	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.Size = UDim2.fromScale(0, 0)
	name.AutomaticSize = Enum.AutomaticSize.XY
	name.BackgroundTransparency = 1
	name.LayoutOrder = 1
	name.Font = Enum.Font.BuilderSansBold
	name.TextColor3 = Color3.fromHex("#ee78e6")
	name.TextSize = 16
	name.Parent = background
	self.nameLabel = name

	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.Size = UDim2.fromOffset(1, 0)
	divider.BackgroundColor3 = Color3.fromHex("#aaaaaa")
	divider.BorderSizePixel = 0
	divider.LayoutOrder = 2
	divider.Parent = background

	local dimensions = Instance.new("TextLabel")
	dimensions.Name = "Dimensions"
	dimensions.Size = UDim2.fromScale(0, 0)
	dimensions.AutomaticSize = Enum.AutomaticSize.XY
	dimensions.BackgroundTransparency = 1
	dimensions.LayoutOrder = 3
	dimensions.Font = Enum.Font.BuilderSansBold
	dimensions.TextColor3 = Color3.fromHex("#d7d7d7")
	dimensions.TextSize = 16
	dimensions.Parent = background
	self.dimensionsLabel = dimensions

	background.Parent = container

	return self
end

export type OverlayTip = typeof(OverlayTip.new(...))

function OverlayTip.remove(self: OverlayTip)
	self.background:Destroy()
end

function OverlayTip.updateText(
	self: OverlayTip,
	name: string,
	width: number,
	height: number
)
	self.nameLabel.Text = name
	self.dimensionsLabel.Text = `{math.round(width)}px x {math.round(height)}px`
end

function OverlayTip.updatePosition(self: OverlayTip, dims: Box, bounds: Box)
	local position = calculatePosition(dims, bounds, self.background.AbsoluteSize)
	self.background.Position = UDim2.fromOffset(position.X, position.Y)
end

return {
	new = OverlayTip.new,
}
