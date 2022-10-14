--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/backend/index.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]

local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array

local Agent = require(script.agent)
type Agent = Agent.Agent

local types = require(script.types)
export type DevToolsHook = types.DevToolsHook
export type ReactRenderer = types.ReactRenderer
export type RendererInterface = types.RendererInterface

type Object = { [string]: any }

local function initBackend(hook: DevToolsHook, agent: Agent, global: Object): () -> ()
	if hook == nil then
		-- DevTools didn't get injected into this page (maybe b'c of the contentType).
		return function() end
	end
	local subs = {
		hook.sub("renderer-attached", function(
			args: {
				id: number,
				renderer: ReactRenderer,
				rendererInterface: RendererInterface,
			}
		)
			local id = args.id
			local rendererInterface = args.rendererInterface

			agent:setRendererInterface(id, rendererInterface)

			-- Now that the Store and the renderer interface are connected,
			-- it's time to flush the pending operation codes to the frontend.
			rendererInterface.flushInitialOperations()
		end),
		hook.sub("unsupported-renderer-version", function(id: number)
			agent:onUnsupportedRenderer(id)
		end),

		hook.sub("operations", function(...)
			agent:onHookOperations(...)
		end),
		hook.sub("traceUpdates", function(...)
			agent:onTraceUpdates(...)
		end),

		-- TODO Add additional subscriptions required for profiling mode
	}

	local attachRenderer = function(id: number, renderer: ReactRenderer)
		-- ROBLOX deviation: require attach lazily to avoid the require of renderer causing Roact to initialize prematurely.
		local attach = require(script.renderer).attach

		local rendererInterface = hook.rendererInterfaces[id]

		-- Inject any not-yet-injected renderers (if we didn't reload-and-profile)
		if rendererInterface == nil then
			if type(renderer.findFiberByHostInstance) == "function" then
				-- react-reconciler v16+
				rendererInterface = attach(hook, id, renderer, global)
			elseif renderer.ComponentTree then
				-- react-dom v15
				-- ROBLOX deviation: Not needed
				-- rendererInterface = attachLegacy(hook, id, renderer, global)
			else
				-- Older react-dom or other unsupported renderer version
			end
			if rendererInterface ~= nil then
				hook.rendererInterfaces[id] = rendererInterface
			end
		end

		-- Notify the DevTools frontend about new renderers.
		-- This includes any that were attached early (via __REACT_DEVTOOLS_ATTACH__).
		if rendererInterface ~= nil then
			hook.emit("renderer-attached", {
				id = id,
				renderer = renderer,
				rendererInterface = rendererInterface,
			})
		else
			hook.emit("unsupported-renderer-version", id)
		end
	end

	-- Connect renderers that have already injected themselves.
	for id, renderer in hook.renderers do
		attachRenderer(id, renderer)
	end

	-- Connect any new renderers that injected themselves.
	table.insert(
		subs,
		hook.sub("renderer", function(args: { id: number, renderer: ReactRenderer })
			local id = args.id
			local renderer = args.renderer
			attachRenderer(id, renderer)
		end)
	)

	hook.emit("react-devtools", agent)
	hook.reactDevtoolsAgent = agent
	local function onAgentShutdown()
		Array.forEach(subs, function(fn)
			fn()
		end)
		hook.rendererInterfaces:forEach(function(rendererInterface)
			rendererInterface.cleanup()
		end)
		hook.reactDevtoolsAgent = nil
	end
	agent:addListener("shutdown", onAgentShutdown)
	table.insert(subs, function()
		agent:removeListener("shutdown", onAgentShutdown)
	end)

	return function()
		for _, fn in subs do
			fn()
		end
	end
end

return {
	initBackend = initBackend,
	agent = require(script.agent),
	NativeStyleEditor = {
		types = require(script.NativeStyleEditor.types),
	},
}
