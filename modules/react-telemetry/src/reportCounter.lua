local TelemetryService = game:GetService("TelemetryService")

local Packages = script.Parent.Parent
local SafeFlags = require(Packages.SafeFlags)
local ReactGlobals = require(Packages.ReactGlobals)

local FFlagReactTelemetryEnabled =
	SafeFlags.createGetFFlag("ReactTelemetryEnabled", false)()

export type CounterOptions = {
	eventName: string,
	lastUpdated: { number },
	description: string,
	links: string,
	customFields: { [string]: any }?,
	value: number?,
}

local function reportCounter(options: CounterOptions)
	if not FFlagReactTelemetryEnabled then
		return
	end

	local config = {
		eventName = options.eventName,
		backends = { "RobloxTelemetryCounter" },
		lastUpdated = options.lastUpdated,
		description = options.description,
		links = options.links,
	}

	local data = {
		customFields = options.customFields or {},
	}

	local success, result =
		pcall(TelemetryService.LogCounter, TelemetryService, config, data, options.value)

	if ReactGlobals.__DEV__ and not success then
		warn(`React telemetry collection is enabled but log failed: {result}`)
	end
end

return reportCounter
