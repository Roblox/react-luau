return function()
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local PlayerGui = LocalPlayer.PlayerGui
	local Mouse = LocalPlayer:GetMouse()

	local COUNT = 500
	local React = require(script.Parent.ProjectWorkspace.React)
	local ReactRoblox = require(script.Parent.ProjectWorkspace.ReactRoblox)

	local BindingExample = React.Component:extend("BindingExample")

	local function Follower(props)
		return React.createElement("Frame", {
			Size = UDim2.fromOffset(12, 12),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = props.position,
			BackgroundColor3 = props.color,
		})
	end

	function BindingExample:init()
		self.binding, self.updateBinding = React.createBinding({})
	end

	function BindingExample:render()
		local followers = {}
		for i = 0, COUNT do
			followers[i] = React.createElement(Follower, {
				position = self.binding:map(function(lastPositions)
					return lastPositions[i]
				end),
				color = Color3.new(i / COUNT, 0, i / COUNT),
			})
		end

		return followers
	end

	function BindingExample:componentDidMount()
		local incrementor = 1

		self.mouseConnection = Mouse.Move:Connect(function()
			local positions = self.binding:getValue()
			positions[incrementor % COUNT + 1] = UDim2.fromOffset(Mouse.X, Mouse.Y)
			self.updateBinding(positions)
			incrementor += 1
		end)
	end

	function BindingExample:componentWillUnmount()
		self.mouseConnection:Disconnect()
	end

	local app = React.createElement("ScreenGui", nil, {
		BindingExample = React.createElement(BindingExample),
	})

	local rootInstance = Instance.new("Folder")
	rootInstance.Parent = PlayerGui

	local root = ReactRoblox.createBlockingRoot(rootInstance)
	root:render(app)

	local function stop()
		root:unmount()
		rootInstance.Parent = nil
	end

	return stop
end