-- Based on: https://github.com/facebook/react/blob/8e5adfbd7e605bda9c5e96c10e015b3dc0df688e/packages/react-devtools-extensions/src/renderer.js

--[[
    In order to support launching DevTools after the client has started, the
    renderer needs to be injected before any other scripts. The hook will look
    for the presence of a global __REACT_DEVTOOLS_ATTACH__ and attach an
    injected renderer early.
]]

local Packages = script.Parent.Parent
local ReactGlobals = require(Packages.ReactGlobals)
local ReactDevtoolsShared = require(Packages.ReactDevtoolsShared)

local attach
ReactGlobals.__REACT_DEVTOOLS_ATTACH__ = function(...)
	-- Importing the renderer module immediately causes React to initialize
	-- prematurely and error. We import lazily here to avoid this, because
	-- React will be initialized by the time this function is called.
	if attach == nil then
		attach = ReactDevtoolsShared.backend.getRendererLazy().attach
	end

	return attach(...)
end

return nil
