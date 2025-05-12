-- Based on: https://github.com/facebook/react/blob/12adaffef7105e2714f82651ea51936c563fe15c/packages/react-devtools-core/src/backend.js

local HttpService = game:GetService("HttpService")
local WebSocketService = game:GetService("WebSocketService")

local Packages = script.Parent.Parent
local ReactDevtoolsShared = require(Packages.ReactDevtoolsShared)
local LuauPolyfill = require(Packages.LuauPolyfill)

local Object = LuauPolyfill.Object

local Agent = ReactDevtoolsShared.backend.agent
local Bridge = ReactDevtoolsShared.bridge
local installHook = ReactDevtoolsShared.hook.installHook
local initBackend = ReactDevtoolsShared.backend.initBackend
local __DEBUG__ = ReactDevtoolsShared.constants.__DEBUG__
local getDefaultComponentFilters = ReactDevtoolsShared.utils.getDefaultComponentFilters

type BackendBridge = ReactDevtoolsShared.BackendBridge
type ComponentFilter = ReactDevtoolsShared.ComponentFilter
type DevtoolsHook = ReactDevtoolsShared.DevtoolsHook

local serializeTable = require(script.Parent.utils.serializeTable)

type Array<T> = { T }

export type ConnectOptions = {
	host: string?,
	port: number?,
	useHttps: boolean?,
	isAppActive: (() -> boolean)?,
}

local hook = installHook(_G)
local savedComponentFilters: Array<ComponentFilter> = getDefaultComponentFilters()

local function debugPrint(methodName: string, ...: any)
	if __DEBUG__ then
		print(`[core/backend] {methodName}`, ...)
	end
end

local function connectToDevtools(options_: ConnectOptions?)
	if hook == nil then
		-- Devtools wasn't injected into this context
		return
	end

	local options: ConnectOptions = options_ or {}
	local host = options.host or "localhost"
	local useHttps = if options.useHttps == nil then false else options.useHttps
	local port = options.port or 8097
	local isAppActive = options.isAppActive or function()
		return true
	end

	local protocol = if useHttps then "wss" else "ws"
	local retryTimeoutThread: thread? = nil

	local function scheduleRetry()
		if retryTimeoutThread == nil then
			retryTimeoutThread = task.delay(2, function()
				connectToDevtools(options)
			end)
		end
	end

	if not isAppActive() then
		scheduleRetry()
		return
	end

	local bridge: BackendBridge? = nil
	local agent

	local messageListeners = {}
	local uri = `{protocol}://{host}:{port}`

	local function handleClose()
		debugPrint("Socket.on('close')")

		if bridge ~= nil then
			bridge:shutdown()
		end

		scheduleRetry()
	end

	local function handleMessage(event: any)
		local success, data = pcall(function()
			if type(event) == "string" then
				local data = HttpService:JSONDecode(event)
				debugPrint("Socket.on('message')", data)
				return data
			else
				error(`Bad data received from socket: {event} (of type {typeof(event)})`)
			end
		end)

		if not success then
			error(
				`[React DevTools] Failed to parse JSON: {event.data} (got error: {data})`
			)
		end

		for _, fn in messageListeners do
			local success, result = pcall(fn :: any, data)
			if not success then
				error(
					`[React DevTools] Error calling listener with data: {data}\n{result}`
				)
			end
		end
	end

	local success, socket = pcall(function()
		return WebSocketService:CreateClient(uri)
	end)

	if success == false then
		warn(
			`[React DevTools] Could not connect to DevTools. Attempted to connect to "{uri}" ({socket})`
		)
		scheduleRetry()
		return
	end

	socket.Closed:Connect(handleClose)
	socket.MessageReceived:Connect(handleMessage)
	socket.Opened:Connect(function()
		bridge = Bridge.new({
			listen = function(fn)
				table.insert(messageListeners, fn)
				return function()
					local index = table.find(messageListeners, fn)
					if index then
						table.remove(messageListeners, index)
					end
				end
			end,
			send = function(event: string, payload: any, transferable: Array<any>?)
				if socket.ConnectionState == Enum.WebSocketState.Open then
					debugPrint("wall.send()", event, payload)

					payload = serializeTable(payload)

					local SERDE_TO_NULL = newproxy()

					if event == "inspectedElement" then
						if payload.type == "full-data" then
							local defaultValue = {
								displayName = SERDE_TO_NULL,
								context = SERDE_TO_NULL,
								hooks = SERDE_TO_NULL,
								props = SERDE_TO_NULL,
								state = SERDE_TO_NULL,
								key = SERDE_TO_NULL,
								owners = SERDE_TO_NULL,
								source = SERDE_TO_NULL,
								rootType = SERDE_TO_NULL,
								rendererPackageName = SERDE_TO_NULL,
								rendererVersion = SERDE_TO_NULL,
							}

							payload.value = Object.assign(defaultValue, payload.value)
						end
					end

					socket:Send(HttpService:JSONEncode({
						event = event,
						payload = payload,
					}))
				else
					debugPrint(
						"wall.send()",
						"Shutting down bridge because of closed WebSocket connection"
					)

					if bridge ~= nil then
						bridge:shutdown()
					end

					scheduleRetry()
				end
			end,
		})

		assert(bridge, "Luau")

		bridge:addListener(
			"inspectElement",
			function(data: { id: number, rendererID: number })
				local id = data.id
				local rendererId = data.rendererID

				if agent then
					local renderer = agent._rendererInterfaces[rendererId]
					if renderer ~= nil then
						local nodes = renderer.findNativeNodesForFiberID(id)
						if nodes ~= nil and next(nodes) ~= nil then
							local node = nodes[1]
							agent:emit("showNativeHighlight", node)
						end
					end
				end
			end
		)

		bridge:addListener(
			"updateComponentFilters",
			function(componentFilters: Array<ComponentFilter>)
				-- Save filter changes in memory, in case DevTools is reloaded.
				-- In that case, the renderer will already be using the updated
				-- values. We'll lose these in between backend reloads but that
				-- can't be helped.
				savedComponentFilters = componentFilters
			end
		)

		-- The renderer interface doesn't read saved component filters directly,
		-- because they are generally stored in localStorage within the context
		-- of the extension. Because of this it relies on the extension to pass
		-- filters. In the case of the standalone DevTools being used with a
		-- website, saved filters are injected along with the backend script tag
		-- so we shouldn't override them here. This injection strategy doesn't
		-- work for React Native though. Ideally the backend would save the
		-- filters itself, but RN doesn't provide a sync storage solution. So
		-- for now we just fall back to using the default filters...
		if _G.__REACT_DEVTOOLS_COMPONENT_FILTERS__ == nil then
			bridge:send("overrideComponentFilters", savedComponentFilters)
		end

		agent = Agent.new(bridge) :: any
		agent:addListener("shutdown", function()
			-- If we received 'shutdown' from `agent`, we assume the `bridge` is
			-- already shutting down, and that caused the 'shutdown' event on
			-- the `agent`, so we don't need to call `bridge.shutdown()` here.
			hook:emit("shutdown")
		end)

		initBackend(hook, agent :: any, _G)
	end)
end

return {
	connectToDevtools = connectToDevtools,
}
