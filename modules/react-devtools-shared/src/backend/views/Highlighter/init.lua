-- ROBLOX upstream: https://github.com/facebook/react/blob/e706721490e50d0bd6af2cd933dbf857fd8b61ed/packages/react-devtools-shared/src/backend/views/Highlighter/index.js

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local PackageRoot = script.Parent.Parent.Parent

local Packages = PackageRoot.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local console = LuauPolyfill.console

local Highlighter = require(script.Highlighter)
local hideOverlay = Highlighter.hideOverlay
local showOverlay = Highlighter.showOverlay

local Bridge = require(PackageRoot.bridge)
type BackendBridge = Bridge.BackendBridge

-- TODO-Roblox: Importing Agent is a cyclic dependency - need to refactor
type Agent = any

local function isVisible(obj: GuiObject)
	local basicCheck = obj.Visible == true

	if obj:IsA("Frame") then
		return basicCheck and obj.BackgroundTransparency < 1
	elseif obj:IsA("CanvasGroup") then
		return basicCheck and obj.BackgroundTransparency < 1 and obj.GroupTransparency < 1
	elseif obj:IsA("TextLabel") and obj:IsA("TextButton") then
		return basicCheck and obj.TextTransparency < 1 and obj.Text ~= ""
	elseif obj:IsA("ImageLabel") and obj:IsA("ImageButton") then
		return basicCheck and obj.ImageTransparency < 1 and obj.Image ~= ""
	else
		return basicCheck
	end
end

local function pickGuiObjectNodes(nodes: { Instance }): { GuiBase2d }
	local relevantNodes = {}
	for _, node in nodes do
		if node:IsA("GuiBase2d") then
			table.insert(relevantNodes, node)
		end
	end
	return relevantNodes
end

local function isInputValid(input: InputObject)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local exports = {}

function exports.setupHighlighter(bridge: BackendBridge, agent: Agent)
	local listenerConnections: { RBXScriptConnection } = {}
	local stopInspectingNative

	-- TODO: Intelligently pick the right container based on context
	local guiContainer: BasePlayerGui? = nil
	local isCoreGui = true
	if isCoreGui then
		guiContainer = game:GetService("CoreGui")
	else
		local localPlayer = Players.LocalPlayer
		if localPlayer ~= nil then
			guiContainer = localPlayer:FindFirstChildOfClass("PlayerGui")
		else
			console.warn("No PlayerGui found for LocalPlayer")
		end
	end

	-- TODO: Throttle this function
	local function selectFiberForNode(node: GuiObject?)
		if node == nil then
			return
		end

		local id = agent:getIDForNode(node)
		if id ~= nil then
			bridge:send("selectFiber", id)
		end
	end

	local function onInputChanged(input: InputObject)
		if guiContainer == nil then
			return
		end

		if not isInputValid(input) then
			return
		end

		local position = input.Position
		local guiObjects = guiContainer:GetGuiObjectsAtPosition(position.X, position.Y)

		-- Get target GUI element
		local target = nil
		local overlay = Highlighter.getOverlay()
		local overlayObj = overlay and overlay.container

		for index, guiObject in guiObjects do
			if overlayObj and guiObject:IsDescendantOf(overlayObj) then
				-- Don't highlight the overlay itself
				continue
			end

			local isLastElement = index == #guiObjects
			if not isVisible(guiObject) and not isLastElement then
				continue
			end

			target = guiObject
			break
		end

		if target == nil then
			hideOverlay()
			return
		end

		-- Don't pass the name explicitly.
		-- It will be inferred from DOM tag and Fiber owner.
		showOverlay({ target }, nil, nil)

		selectFiberForNode(target)
	end

	local lastInputProcessed = false
	local function onInputBegan(input: InputObject, gameProcessedEvent: boolean)
		if not isInputValid(input) then
			return
		end

		lastInputProcessed = gameProcessedEvent
	end

	local function onInputEnded(input: InputObject)
		if not isInputValid(input) then
			return
		end

		-- If the event wasn't processed then the user most likely clicked to
		-- focus the viewport, so we don't want to select any fiber.
		if not lastInputProcessed then
			return
		end

		stopInspectingNative()
		bridge:send("stopInspectingNative", true)
	end

	local function removeInputListeners()
		for _, connection in listenerConnections do
			connection:Disconnect()
		end
		table.clear(listenerConnections)
	end

	local function addInputListeners()
		table.insert(
			listenerConnections,
			UserInputService.InputChanged:Connect(onInputChanged)
		)
		table.insert(
			listenerConnections,
			UserInputService.InputBegan:Connect(onInputBegan)
		)
		table.insert(
			listenerConnections,
			UserInputService.InputEnded:Connect(onInputEnded)
		)
	end

	local function clearNativeElementHighlight()
		hideOverlay()
	end

	local function highlightNativeElement(props: {
		displayName: string | nil,
		hideAfterTimeout: boolean,
		id: number,
		openNativeElementsPanel: boolean,
		rendererID: number,
		scrollIntoView: boolean,
	})
		local displayName = props.displayName
		local hideAfterTimeout = props.hideAfterTimeout
		local id = props.id
		local openNativeElementsPanel = props.openNativeElementsPanel
		local rendererID = props.rendererID
		local _scrollIntoView = props.scrollIntoView

		local renderer = agent._rendererInterfaces[rendererID]
		if renderer == nil then
			console.warn(`Invalid renderer id "{rendererID}" for element "{id}"`)
		end

		local nodes: { Instance }? = nil
		if renderer ~= nil then
			nodes = renderer.findNativeNodesForFiberID(id)
		end

		if nodes ~= nil and nodes[1] ~= nil then
			-- TODO-Roblox: Support scrolling node into view
			-- This would require checking if the node is in a scrollable
			-- container and then scrolling those containers to center the node.
			local relevantNodes = pickGuiObjectNodes(nodes)
			if #relevantNodes == 0 then
				hideOverlay()
				return
			end

			showOverlay(relevantNodes, displayName, hideAfterTimeout)

			if openNativeElementsPanel then
				_G.__REACT_DEVTOOLS_GLOBAL_HOOK__["$0"] = relevantNodes[1]
				bridge:send("syncSelectionToNativeElementsPanel")
			end
		else
			hideOverlay()
		end
	end

	local function startInspectingNative()
		addInputListeners()
	end

	stopInspectingNative = function()
		hideOverlay()
		removeInputListeners()
	end

	bridge:addListener("clearNativeElementHighlight", clearNativeElementHighlight)
	bridge:addListener("highlightNativeElement", highlightNativeElement)
	bridge:addListener("shutdown", stopInspectingNative)
	bridge:addListener("startInspectingNative", startInspectingNative)
	bridge:addListener("stopInspectingNative", stopInspectingNative)
end

return exports
