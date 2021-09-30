return function()

	local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui
	
	local React = require(script.Parent.ProjectWorkspace.React)
	local ReactRoblox = require(script.Parent.ProjectWorkspace.ReactRoblox)

	local app = React.createElement("ScreenGui", nil, {
		Main = React.createElement("TextLabel", {
			Size = UDim2.new(0, 400, 0, 300),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Text = "Hello, React!",
		}),
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