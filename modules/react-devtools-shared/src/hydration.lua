-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/hydration.js
-- /*
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  */

local Packages = script.Parent.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
local Symbol = LuauPolyfill.Symbol
type Array<T> = { [number]: T }
type Object = { [string]: any }

-- ROBLOX FIXME: !!! THIS FILE IS A STUB WITH BAREBONES FOR UTILS TEST
local function unimplemented(functionName)
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("!!! " .. functionName .. " was called, but is stubbed! ")
end

local exports = {}

--ROBLOX TODO: circular dependency, inline for now and submit PR to fix upstream
--local ComponentsTypes = require(script.Parent.devtools.views.Components.types)
export type DehydratedData = {
	cleaned: Array<Array<string | number>>,
	data: string | Dehydrated | Unserializable | Array<Dehydrated> | Array<Unserializable> | {
		[string]: string | Dehydrated | Unserializable,
	},
	unserializable: Array<Array<string | number>>,
}

exports.meta = {
	inspectable = Symbol("inspectable"),
	inspected = Symbol("inspected"),
	name = Symbol("name"),
	preview_long = Symbol("preview_long"),
	preview_short = Symbol("preview_short"),
	readonly = Symbol("readonly"),
	size = Symbol("size"),
	type = Symbol("type"),
	unserializable = Symbol("unserializable"),
}

export type Dehydrated = {
	inspectable: boolean,
	name: string | nil,
	preview_long: string | nil,
	preview_short: string | nil,
	readonly: boolean?,
	size: number?,
	type: string,
}

-- Typed arrays and other complex iteratable objects (e.g. Map, Set, ImmutableJS) need special handling.
-- These objects can't be serialized without losing type information,
-- so a "Unserializable" type wrapper is used (with meta-data keys) to send nested values-
-- while preserving the original type and name.
export type Unserializable = {
	name: string | nil,
	preview_long: string | nil,
	preview_short: string | nil,
	readonly: boolean?,
	size: number?,
	type: string,
	unserializable: boolean,
	-- ...
}

-- This threshold determines the depth at which the bridge "dehydrates" nested data.
-- Dehydration means that we don't serialize the data for e.g. postMessage or stringify,
-- unless the frontend explicitly requests it (e.g. a user clicks to expand a props object).
--
-- Reducing this threshold will improve the speed of initial component inspection,
-- but may decrease the responsiveness of expanding objects/arrays to inspect further.
local _LEVEL_THRESHOLD = 2

-- /**
--  * Generate the dehydrated metadata for complex object instances
--  */
exports.createDehydrated = function(
	type: string,
	inspectable: boolean,
	data: Object,
	cleaned: Array<Array<string | number>>,
	path: Array<string | number>
): Dehydrated
	unimplemented("createDehydrated")
	error("unimplemented createDehydrated")
end

-- /**
--  * Strip out complex data (instances, functions, and data nested > LEVEL_THRESHOLD levels deep).
--  * The paths of the stripped out objects are appended to the `cleaned` list.
--  * On the other side of the barrier, the cleaned list is used to "re-hydrate" the cleaned representation into
--  * an object with symbols as attributes, so that a sanitized object can be distinguished from a normal object.
--  *
--  * Input: {"some": {"attr": fn()}, "other": AnInstance}
--  * Output: {
--  *   "some": {
--  *     "attr": {"name": the fn.name, type: "function"}
--  *   },
--  *   "other": {
--  *     "name": "AnInstance",
--  *     "type": "object",
--  *   },
--  * }
--  * and cleaned = [["some", "attr"], ["other"]]
--  */
exports.dehydrate = function(
	data: Object,
	cleaned: Array<Array<string | number>>,
	unserializable: Array<Array<string | number>>,
	path: Array<string | number>,
	isPathAllowed: (Array<string | number>) -> boolean,
	level: number?
): string | Dehydrated | Unserializable | Array<Dehydrated> | Array<Unserializable> | {
	[string]: string | Dehydrated | Unserializable, --[[...]]
}
	if level == nil then
		level = 0
	end
	unimplemented("dehydrate")
	return "!!! UNIMPLEMENTED !!!"
end

exports.fillInPath =
	function(object: Object, data: DehydratedData, path: Array<string | number>, value: any): ()
		unimplemented("fillInPath")
	end

exports.hydrate = function(
	object: any,
	cleaned: Array<Array<string | number>>,
	unserializable: Array<Array<string | number>>
): Object
	unimplemented("hydrate")
	return {}
end

return exports
