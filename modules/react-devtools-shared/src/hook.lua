-- ROBLOX upstream: https://raw.githubusercontent.com/facebook/react/v17.0.1/packages/react-devtools-shared/src/hook.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]
local Packages = script.Parent.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array

local console = require(script.Parent.backend.console)
local patchConsole = console.patch
local registerRendererWithConsole = console.registerRenderer

local window = _G

local exports = {}

exports.installHook = function(target)
	if target["__REACT_DEVTOOLS_GLOBAL_HOOK__"] then
		return nil
	end

	local function detectReactBuildType(renderer)
		-- ROBLOX deviation: don't need to check build type in the same way as JS
		return "production"
	end
	local function checkDCE(fn)
		-- ROBLOX deviation: noop
	end

	-- ROBLOX deviation: start at 1
	local uidCounter = 1
	local function PREFIX_INCREMENT()
		uidCounter += 1
		return uidCounter
	end

	local hasDetectedBadDCE = false

	local fiberRoots = {}
	local rendererInterfaces = {}
	local listeners = {}
	local renderers = {}
	local hook = {
		rendererInterfaces = rendererInterfaces,
		listeners = listeners,
		renderers = renderers,
		supportsFiber = true,
		checkDCE = checkDCE,
	}

	function hook.inject(renderer)
		local id = PREFIX_INCREMENT()

		renderers[id] = renderer

		local reactBuildType = (function()
			if hasDetectedBadDCE then
				return "deadcode"
			end
			return detectReactBuildType(renderer)
		end)()

		-- ROBLOX deviation: instead of checking if `process.env.NODE_ENV ~= "production"`
		-- we use the __DEV__ global
		if _G.__DEV__ then
			pcall(function()
				local appendComponentStack = window.__REACT_DEVTOOLS_APPEND_COMPONENT_STACK__
					~= false
				local breakOnConsoleErrors = window.__REACT_DEVTOOLS_BREAK_ON_CONSOLE_ERRORS__
					== true

				-- The installHook() function is injected by being stringified in the browser,
				-- so imports outside of this function do not get included.
				--
				-- Normally we could check "type patchConsole === 'function'",
				-- but Webpack wraps imports with an object (e.g. _backend_console__WEBPACK_IMPORTED_MODULE_0__)
				-- and the object itself will be undefined as well for the reasons mentioned above,
				-- so we use try/catch instead.
				if appendComponentStack or breakOnConsoleErrors then
					registerRendererWithConsole(renderer)
					patchConsole({
						appendComponentStack,
						breakOnConsoleErrors,
					})
				end
			end)
		end

		local attach = target.__REACT_DEVTOOLS_ATTACH__

		if type(attach) == "function" then
			local rendererInterface = attach(hook, id, renderer, target)
			hook.rendererInterfaces[id] = rendererInterface
		end

		hook.emit("renderer", {
			id = id,
			renderer = renderer,
			reactBuildType = reactBuildType,
		})
		return id
	end

	function hook.sub(event: string, fn: (any) -> ())
		hook.on(event, fn)
		return function()
			return hook.off(event, fn)
		end
	end
	function hook.on(event, fn)
		if not listeners[event] then
			listeners[event] = {}
		end
		table.insert(listeners[event], fn)
	end
	function hook.off(event, fn)
		if not listeners[event] then
			return
		end

		local index = Array.indexOf(listeners[event], fn)

		if index ~= -1 then
			Array.splice(listeners[event], index, 1)
		end
		if #listeners[event] == 0 then
			listeners[event] = nil
		end
	end
	function hook.emit(event, data)
		if listeners[event] then
			for _, fn in pairs(listeners[event]) do
				fn(data)
			end
		end
	end
	function hook.getFiberRoots(rendererID)
		local roots = fiberRoots

		if not roots[rendererID] then
			roots[rendererID] = {}
		end

		return roots[rendererID]
	end
	function hook.onCommitFiberUnmount(rendererID, fiber)
		local rendererInterface = rendererInterfaces[rendererID]

		if rendererInterface ~= nil then
			rendererInterface.handleCommitFiberUnmount(fiber)
		end
	end
	function hook.onCommitFiberRoot(rendererID, root, priorityLevel)
		local mountedRoots = hook.getFiberRoots(rendererID)
		local current = root.current
		local isKnownRoot = mountedRoots[root] ~= nil
		local isUnmounting = current.memoizedState == nil
			or current.memoizedState.element == nil

		if not isKnownRoot and not isUnmounting then
			mountedRoots[root] = true
		elseif isKnownRoot and isUnmounting then
			mountedRoots[root] = nil
		end

		local rendererInterface = rendererInterfaces[rendererID]

		if rendererInterface ~= nil then
			rendererInterface.handleCommitFiberRoot(root, priorityLevel)
		end
	end

	target["__REACT_DEVTOOLS_GLOBAL_HOOK__"] = hook
	return hook
end

return exports
