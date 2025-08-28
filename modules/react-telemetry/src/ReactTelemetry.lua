local Packages = script.Parent.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
local Object = LuauPolyfill.Object

local reportCounter = require(script.Parent.reportCounter)
local customFields = require(script.Parent.customFields)

local ReactTelemetry = {}
ReactTelemetry.customFields = customFields

local function reportNewDevtoolsConnection()
	reportCounter({
		eventName = "react_new_devtools_connection",
		lastUpdated = { 2025, 8, 28 },
		description = "A new connection to React Devtools",
		links = "https://roblox.atlassian.net/wiki/spaces/luauee/pages/3836510338/DevTools+Telemetry",
		customFields = customFields,
	})
end
ReactTelemetry.reportNewDevtoolsConnection = reportNewDevtoolsConnection

local function reportFailedDevtoolsConnection(
	type: "create_client_failed" | "socket_closed"
)
	reportCounter({
		eventName = "react_failed_devtools_connection",
		lastUpdated = { 2025, 8, 28 },
		description = "A failed connection to React Devtools",
		links = "https://roblox.atlassian.net/wiki/spaces/luauee/pages/3836510338/DevTools+Telemetry",
		customFields = Object.assign({}, customFields, {
			error_type = type,
		}),
	})
end
ReactTelemetry.reportFailedDevtoolsConnection = reportFailedDevtoolsConnection

return ReactTelemetry
