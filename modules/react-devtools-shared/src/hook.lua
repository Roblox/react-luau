--!strict
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
local Map = LuauPolyfill.Map
local Set = LuauPolyfill.Set
type Set<T> = LuauPolyfill.Set<T>
type Map<K, V> = LuauPolyfill.Map<K, V>
type Function = (...any) -> any
local exports = {}

local console = require(script.Parent.backend.console)
local patchConsole = console.patch
local registerRendererWithConsole = console.registerRenderer

local BackendTypes = require(script.Parent.backend.types)
type DevToolsHook = BackendTypes.DevToolsHook

local window = _G

exports.installHook = function(target: any): DevToolsHook | nil
	if target["__REACT_DEVTOOLS_GLOBAL_HOOK__"] then
		return nil
	end

	-- ROBLOX deviation: hoist decls to top
	local hook: DevToolsHook
	-- ROBLOX deviation: always false, only relevant in context of optimizing bundler
	local hasDetectedBadDCE = false
	-- TODO: More meaningful names for "rendererInterfaces" and "renderers".
	local fiberRoots = {}
	local rendererInterfaces = Map.new()
	local listeners = {}
	local renderers = Map.new()

	local function detectReactBuildType(renderer)
		-- ROBLOX TODO? do we need to distinguish between prod and dev bundles?
		return "production"
	end
	local function checkDCE(fn: Function)
		-- ROBLOX deviation: not needed in the absence of optimizing bundler
	end

	-- ROBLOX deviation: start at 1
	local uidCounter = 1
	local function PREFIX_INCREMENT()
		uidCounter += 1
		return uidCounter
	end

	local function inject(renderer)
		local id = PREFIX_INCREMENT()

		renderers:set(id, renderer)

		local reactBuildType = if hasDetectedBadDCE
			then "deadcode"
			else detectReactBuildType(renderer)

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
						appendComponentStack = appendComponentStack,
						breakOnConsoleErrors = breakOnConsoleErrors,
					})
				end
			end)
		end

		local attach = target.__REACT_DEVTOOLS_ATTACH__

		if type(attach) == "function" then
			local rendererInterface = attach(hook, id, renderer, target)
			hook.rendererInterfaces:set(id, rendererInterface)
		end

		hook.emit("renderer", {
			id = id,
			renderer = renderer,
			reactBuildType = reactBuildType,
		})
		return id
	end

	local function sub(event: string, fn: (any) -> ())
		hook.on(event, fn)
		return function()
			return hook.off(event, fn)
		end
	end
	local function on(event, fn)
		if not listeners[event] then
			listeners[event] = {}
		end
		table.insert(listeners[event], fn)
	end
	local function off(event, fn)
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
	local function emit(event, data)
		if listeners[event] then
			for _, fn in listeners[event] do
				fn(data)
			end
		end
	end
	local function getFiberRoots(rendererID)
		local roots = fiberRoots

		if not roots[rendererID] then
			roots[rendererID] = Set.new()
		end

		return roots[rendererID]
	end
	local function onCommitFiberUnmount(rendererID, fiber)
		local rendererInterface = rendererInterfaces:get(rendererID)

		if rendererInterface ~= nil then
			rendererInterface.handleCommitFiberUnmount(fiber)
		end
	end
	local function onCommitFiberRoot(rendererID, root, priorityLevel)
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

		local rendererInterface = rendererInterfaces:get(rendererID)

		if rendererInterface ~= nil then
			rendererInterface.handleCommitFiberRoot(root, priorityLevel)
		end
	end

	hook = {
		rendererInterfaces = rendererInterfaces,
		listeners = listeners,
		-- Fast Refresh for web relies on this.
		renderers = renderers,

		emit = emit,
		getFiberRoots = getFiberRoots,
		inject = inject,
		on = on,
		off = off,
		sub = sub,

		-- This is a legacy flag.
		-- React v16 checks the hook for this to ensure DevTools is new enough.
		supportsFiber = true,

		-- React calls these methods.
		checkDCE = checkDCE,
		onCommitFiberUnmount = onCommitFiberUnmount,
		onCommitFiberRoot = onCommitFiberRoot,
	}

	target["__REACT_DEVTOOLS_GLOBAL_HOOK__"] = hook
	return hook
end

return exports
