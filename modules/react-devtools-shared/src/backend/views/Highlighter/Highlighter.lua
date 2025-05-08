-- ROBLOX upstream: https://github.com/facebook/react/blob/b8390310b14cce89fd26df83f969505b5f129f10/packages/react-devtools-shared/src/backend/views/Highlighter/Highlighter.js

local Overlay = require(script.Parent.Overlay.Overlay)
type Overlay = Overlay.Overlay

local exports = {}

local timeoutThread: thread? = nil
local overlay: Overlay? = nil

local SHOW_DURATION = 2

function exports.hideOverlay()
	if timeoutThread then
		task.cancel(timeoutThread)
	end
	timeoutThread = nil

	if overlay ~= nil then
		overlay:remove()
		overlay = nil
	end
end

function exports.showOverlay(
	elements: { GuiBase2d }?,
	componentName: string?,
	hideAfterTimeout: boolean
)
	if timeoutThread ~= nil then
		task.cancel(timeoutThread)
		timeoutThread = nil
	end

	if elements == nil then
		return
	end

	if overlay == nil then
		overlay = Overlay.new()
	end

	-- Sometimes the object the overlay is attached to is destroyed
	-- In that case, create a new overlay
	if overlay and overlay.container.Parent == nil then
		overlay:remove()
		overlay = Overlay.new()
	end

	assert(overlay, "Luau")
	overlay:inspect(elements, componentName)

	if hideAfterTimeout then
		timeoutThread = task.delay(SHOW_DURATION, function()
			exports.hideOverlay()
		end)
	end
end

function exports.getOverlay(): Overlay?
	return overlay
end

return exports
