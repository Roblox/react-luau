export type Context = "universal_app" | "in_experience" | "plugin" | "unknown"
export type CustomFields = {
	context: Context,
	plugin_name: string?,
}

local plugin = script:FindFirstAncestorWhichIsA("Plugin")

local customFields: CustomFields = {
	context = if plugin then "plugin" else "unknown",
	plugin_name = if plugin then plugin.Name else nil,
}

return customFields
