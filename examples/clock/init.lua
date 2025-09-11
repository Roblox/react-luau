return function()
	local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

	local React = require(script.Parent.ProjectWorkspace.React)
	local ReactRoblox = require(script.Parent.ProjectWorkspace.ReactRoblox)

	local function ClockApp(props)
		local timeValue = props.time

		return React.createElement("ScreenGui", nil, {
			Main = React.createElement("TextLabel", {
				Size = UDim2.new(0, 400, 0, 300),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Text = "The current time is: " .. timeValue,
			}),
		})
	end

	local rootInstance = Instance.new("Folder")
	rootInstance.Parent = PlayerGui

	local running = true
	local currentTime = 0
	local root = ReactRoblox.createBlockingRoot(rootInstance)
	root:render(React.createElement(ClockApp, {
		time = currentTime,
	}))

	spawn(function()
		while running do
			currentTime = currentTime + 1

			root:render(React.createElement(ClockApp, {
				time = currentTime,
			}))

			wait(1)
		end
	end)

	local function stop()
		running = false
		root:unmount()
		rootInstance.Parent = nil
	end

	return stop
end
