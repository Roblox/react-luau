return function()
	local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

	local React = require(script.Parent.ProjectWorkspace.React)
	local ReactRoblox = require(script.Parent.ProjectWorkspace.ReactRoblox)

	--[[
		A TextBox that the user can type into. Takes a callback to be
		triggered when text changes.
	]]
	local function InputTextBox(props)
		local onTextChanged = props.onTextChanged
		local layoutOrder = props.layoutOrder

		return React.createElement("TextBox", {
			LayoutOrder = layoutOrder,
			Text = "Type Here!",
			Size = UDim2.new(1, 0, 0.5, 0),
			[ReactRoblox.Change.Text] = onTextChanged,
		})
	end

	--[[
		A TextLabel that display the given text in reverse.
	]]
	local function ReversedText(props)
		local inputText = props.inputText
		local layoutOrder = props.layoutOrder

		return React.createElement("TextLabel", {
			LayoutOrder = layoutOrder,
			Size = UDim2.new(1, 0, 0.5, 0),
			Text = "Reversed: " .. string.reverse(inputText),
		})
	end

	--[[
		Displays a TextBox and a TextLabel that shows the reverse of
		the TextBox's input in real time
	]]
	local TextReverser = React.Component:extend("TextReverser")

	function TextReverser:init()
		self.state = {
			text = "",
		}
	end

	function TextReverser:render()
		local text = self.state.text

		return React.createElement("Frame", {
			Size = UDim2.new(0, 400, 0, 400),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
		}, {
			React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			React.createElement(InputTextBox, {
				layoutOrder = 1,
				onTextChanged = function(rbx)
					self:setState({
						text = rbx.Text or "",
					})
				end,
			}),
			React.createElement(ReversedText, {
				layoutOrder = 2,
				inputText = text,
			}),
		})
	end

	local app = React.createElement("ScreenGui", nil, {
		TextReverser = React.createElement(TextReverser),
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
