--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/utils.js
-- /*
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  */
--  * LICENSE file in the root directory of this source tree.

local Packages = script.Parent.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local WeakMap = LuauPolyfill.WeakMap
local Number = LuauPolyfill.Number
local Object = LuauPolyfill.Object
type WeakMap<K, V> = LuauPolyfill.WeakMap<K, V>
type Function = (...any) -> ...any
type Object = LuauPolyfill.Object
type Array<T> = LuauPolyfill.Array<T>
local JSON = game:GetService("HttpService")

local exports = {}

-- ROBLOX TODO: pull in smarter cache when there's a performance reason to do so
-- local LRU = require()
-- ROBLOX deviation: pull in getComponentName for Lua-specific logic to extract component names
local Shared = require(Packages.Shared)
local getComponentName = Shared.getComponentName

local ReactIs = require(Packages.ReactIs)
local isElement = ReactIs.isElement
local typeOf = ReactIs.typeOf
local ContextConsumer = ReactIs.ContextConsumer
local ContextProvider = ReactIs.ContextProvider
local ForwardRef = ReactIs.ForwardRef
local Fragment = ReactIs.Fragment
local Lazy = ReactIs.Lazy
local Memo = ReactIs.Memo
local Portal = ReactIs.Portal
local Profiler = ReactIs.Profiler
local StrictMode = ReactIs.StrictMode
local Suspense = ReactIs.Suspense
local ReactSymbols = require(Packages.Shared).ReactSymbols
local SuspenseList = ReactSymbols.REACT_SUSPENSE_LIST_TYPE
local constants = require(script.Parent.constants)
local TREE_OPERATION_ADD = constants.TREE_OPERATION_ADD
local TREE_OPERATION_REMOVE = constants.TREE_OPERATION_REMOVE
local TREE_OPERATION_REORDER_CHILDREN = constants.TREE_OPERATION_REORDER_CHILDREN
local TREE_OPERATION_UPDATE_TREE_BASE_DURATION =
	constants.TREE_OPERATION_UPDATE_TREE_BASE_DURATION
local types = require(script.Parent.types)
local ElementTypeRoot = types.ElementTypeRoot
local LOCAL_STORAGE_FILTER_PREFERENCES_KEY =
	constants.LOCAL_STORAGE_FILTER_PREFERENCES_KEY
local LOCAL_STORAGE_SHOULD_BREAK_ON_CONSOLE_ERRORS =
	constants.LOCAL_STORAGE_SHOULD_BREAK_ON_CONSOLE_ERRORS
local LOCAL_STORAGE_SHOULD_PATCH_CONSOLE_KEY =
	constants.LOCAL_STORAGE_SHOULD_PATCH_CONSOLE_KEY
local ComponentFilterElementType = types.ComponentFilterElementType
local ElementTypeHostComponent = types.ElementTypeHostComponent
local ElementTypeClass = types.ElementTypeClass
local ElementTypeForwardRef = types.ElementTypeForwardRef
local ElementTypeFunction = types.ElementTypeFunction
local ElementTypeMemo = types.ElementTypeMemo
local storage = require(script.Parent.storage)
local localStorageGetItem = storage.localStorageGetItem
local localStorageSetItem = storage.localStorageSetItem
local hydration = require(script.Parent.hydration)
local meta = hydration.meta
type ComponentFilter = types.ComponentFilter
type ElementType = types.ElementType

local cachedDisplayNames: WeakMap<Function, string> = WeakMap.new()

-- On large trees, encoding takes significant time.
-- Try to reuse the already encoded strings.
-- ROBLOX TODO: implement this when there's a performance issue in Studio tools driving it
-- local encodedStringCache = LRU({max = 1000})

exports.alphaSortKeys = function(
	a: string | number, -- ROBLOX deviation: | Symbol,
	b: string | number -- ROBLOX deviation: | Symbol,
): boolean
	-- ROBLOX deviation: passed to table.sort(), which returns a bool
	return tostring(a) > tostring(b)
end

exports.getAllEnumerableKeys = function(obj: Object): Array<string | number> -- | Symbol>
	-- ROBLOX TODO: we probably need to enumerate inheritance chain metatables
	return Object.keys(obj)
end

exports.getDisplayName = function(type_: any, fallbackName: string?): string
	fallbackName = fallbackName or "Anonymous"
	local nameFromCache = cachedDisplayNames:get(type_)

	if nameFromCache ~= nil then
		return nameFromCache :: string
	end

	-- ROBLOX FIXME: Luau type narrowing doesn't understand the or "anonymous" above
	local displayName: string = fallbackName :: string

	-- The displayName property is not guaranteed to be a string.
	-- It's only safe to use for our purposes if it's a string.
	-- github.com/facebook/react-devtools/issues/803
	-- ROBLOX deviation START: Luau datatypes don't have a displayName property, so we use .__componentName
	if typeof(type_) == "table" and typeof(type_.__componentName) == "string" then
		displayName = type_.__componentName
		-- ROBLOX deviation END
	elseif
		typeof(type_) == "table"
		and typeof(type_.name) == "string"
		and type_.name ~= ""
	then
		displayName = type_.name
		-- ROBLOX deviation: use the Lua logic in getComponentName to extract names of function components
	elseif typeof(type_) == "function" then
		displayName = getComponentName(type_) or displayName
	end

	cachedDisplayNames:set(type_, displayName)

	return displayName
end

local uidCounter: number = 0

exports.getUID = function(): number
	uidCounter += 1
	return uidCounter
end

-- ROBLOX deviation: string encoding not required
-- exports.utfDecodeString = function(str): string
-- end
-- exports.utfEncodeString = function(str): string
-- end

-- ROBLOX deviation: don't binary encode strings, so operations Array can include strings
exports.printOperationsArray = function(operations: Array<number | string>)
	-- The first two values are always rendererID and rootID
	local rendererID = operations[1] :: number
	local rootID = operations[2] :: number
	local logs = {
		string.format(
			"operations for renderer:%s and root:%s",
			tostring(rendererID),
			tostring(rootID)
		),
	}

	-- ROBLOX deviation: 1-indexing so start at 3
	local i = 3

	-- ROBLOX deviation: use POSTFIX_INCREMENT instead of return i++
	local function POSTFIX_INCREMENT()
		local tmp = i
		i += 1
		return tmp
	end

	-- Reassemble the string table.
	local stringTable: Array<string> = {
		-- ROBLOX deviation: Use the empty string
		"", -- ID = 0 corresponds to the empty string.
	}
	local stringTableSize = operations[POSTFIX_INCREMENT()] :: number
	local stringTableEnd = i + stringTableSize

	-- ROBLOX deviation: adjust bounds due to 1-based indexing
	while i < stringTableEnd do
		-- ROBLOX deviation: don't binary encode strings, so store string directly rather than length
		-- local nextLength = operations[POSTFIX_INCREMENT()]
		-- local nextString = exports.utfDecodeString(Array.slice(operations, i, i + nextLength)
		local nextString = operations[POSTFIX_INCREMENT()] :: string
		table.insert(stringTable, nextString)
	end

	while i < #operations do
		local operation = operations[i] :: number

		if operation == TREE_OPERATION_ADD then
			local id = operations[i + 1] :: number
			local type_ = operations[i + 2] :: ElementType

			i += 3

			if type_ == ElementTypeRoot then
				table.insert(logs, string.format("Add new root node %d", id))

				i += 1 -- supportsProfiling
				i += 1 -- hasOwnerMetadata
			else
				local parentID = operations[i] :: number
				i += 1

				i += 1 -- ownerID

				local displayNameStringID = operations[i] :: number
				local displayName = stringTable[displayNameStringID + 1]
				i += 1

				i += 1 -- key

				table.insert(
					logs,
					string.format(
						"Add node %d (%s) as child of %d",
						id,
						displayName or "null",
						parentID
					)
				)
			end
		elseif operation == TREE_OPERATION_REMOVE then
			local removeLength = operations[i + 1] :: number
			i += 2

			for removeIndex = 1, removeLength do
				local id = operations[i] :: number
				i += 1

				table.insert(logs, string.format("Remove node %d", id))
			end
		elseif operation == TREE_OPERATION_REORDER_CHILDREN then
			local id = operations[i + 1] :: number
			local numChildren = operations[i + 2] :: number
			i += 3
			local children = Array.slice(operations, i, i + numChildren)
			i += numChildren

			table.insert(
				logs,
				string.format(
					"Re-order node %d children %s",
					id,
					Array.join(children, ",")
				)
			)
		elseif operation == TREE_OPERATION_UPDATE_TREE_BASE_DURATION then
			-- Base duration updates are only sent while profiling is in progress.
			-- We can ignore them at this point.
			-- The profiler UI uses them lazily in order to generate the tree.
			i += 3
		else
			error(string.format("Unsupported Bridge operation %d", operation))
		end
	end

	print(table.concat(logs, "\n  "))
end

exports.getDefaultComponentFilters = function(): Array<ComponentFilter>
	return {
		{
			type = ComponentFilterElementType,
			value = ElementTypeHostComponent,
			isEnabled = true,
		},
	}
end
exports.getSavedComponentFilters = function(): Array<ComponentFilter>
	local ok, result = pcall(function()
		local raw = localStorageGetItem(LOCAL_STORAGE_FILTER_PREFERENCES_KEY)
		if raw ~= nil then
			return JSON:JSONDecode(raw)
		end
		return nil
	end)
	if not ok then
		return exports.getDefaultComponentFilters()
	end

	return result
end
exports.saveComponentFilters = function(componentFilters: Array<ComponentFilter>): ()
	localStorageSetItem(
		LOCAL_STORAGE_FILTER_PREFERENCES_KEY,
		JSON:JSONEncode(componentFilters)
	)
end
exports.getAppendComponentStack = function(): boolean
	local ok, result = pcall(function()
		local raw = localStorageGetItem(LOCAL_STORAGE_SHOULD_PATCH_CONSOLE_KEY)
		if raw ~= nil then
			return JSON:JSONDecode(raw)
		end
		return nil
	end)
	if not ok then
		return true
	end

	return result
end
exports.setAppendComponentStack = function(value: boolean): ()
	localStorageSetItem(LOCAL_STORAGE_SHOULD_PATCH_CONSOLE_KEY, JSON:JSONEncode(value))
end
exports.getBreakOnConsoleErrors = function(): boolean
	local ok, result = pcall(function()
		local raw = localStorageGetItem(LOCAL_STORAGE_SHOULD_BREAK_ON_CONSOLE_ERRORS)
		if raw ~= nil then
			return JSON:JSONDecode(raw)
		end
		return nil
	end)
	if ok then
		return result
	end
	return false
end

exports.setBreakOnConsoleErrors = function(value: boolean): ()
	localStorageSetItem(
		LOCAL_STORAGE_SHOULD_BREAK_ON_CONSOLE_ERRORS,
		JSON:JSONEncode(value)
	)
end
exports.separateDisplayNameAndHOCs = function(
	displayName: string | nil,
	type_: ElementType
): (string | nil, Array<string> | nil)
	if displayName == nil then
		return nil, nil
	end

	local hocDisplayNames: Array<string>? = nil

	if
		type_ == ElementTypeClass
		or type_ == ElementTypeForwardRef
		or type_ == ElementTypeFunction
		or type_ == ElementTypeMemo
	then
		-- ROBLOX deviation START: use find instead of indexOf and gmatch instead of /[^()]+/g
		if string.find(displayName :: string, "(", 1, true) then
			local hocTable: Array<string> = {}
			for match in string.gmatch(displayName :: string, "[^()]+") do
				table.insert(hocTable, match)
			end

			-- ROBLOX note: Pull the last one out as the displayName
			local count = #hocTable
			local lastMatch = hocTable[count]
			hocTable[count] = nil

			displayName = lastMatch
			hocDisplayNames = hocTable
		end
		-- ROBLOX Deviation END
	end

	if type_ == ElementTypeMemo then
		if hocDisplayNames == nil then
			hocDisplayNames = { "Memo" }
		else
			Array.unshift(hocDisplayNames :: Array<string>, "Memo")
		end
	elseif type_ == ElementTypeForwardRef then
		if hocDisplayNames == nil then
			hocDisplayNames = { "ForwardRef" }
		else
			Array.unshift(hocDisplayNames :: Array<string>, "ForwardRef")
		end
	end
	return displayName, hocDisplayNames
end

-- Pulled from preact-compat
-- https://github.com/developit/preact-compat/blob/7c5de00e7c85e2ffd011bf3af02899b63f699d3a/src/index.js#L349
exports.shallowDiffers = function(prev: Object, next_: Object): boolean
	for key, value in prev do
		if next_[key] ~= value then
			return true
		end
	end
	return false
end

exports.getInObject = function(object: Object, path: Array<string | number>): any
	return Array.reduce(path, function(reduced: Object, attr: any): any
		if reduced then
			if reduced[attr] ~= nil then
				return reduced[attr]
			end
			-- ROBLOX deviation: no iterators in Symbol polyfill
			-- if typeof(reduced[Symbol.iterator]) == "function" then
			-- 	return Array.from(reduced)[attr]
			-- end
		end

		return nil
	end, object)
end
exports.deletePathInObject = function(object: Object?, path: Array<string | number>)
	local length = #path
	local last = path[length] :: number

	if object ~= nil then
		local parent = exports.getInObject(object :: Object, Array.slice(path, 0, length))

		if parent then
			if Array.isArray(parent) then
				Array.splice(parent, last, 1)
			else
				parent[last] = nil
			end
		end
	end
end
exports.renamePathInObject = function(
	object: Object?,
	oldPath: Array<string | number>,
	newPath: Array<string | number>
)
	local length = #oldPath

	if object ~= nil then
		local parent =
			exports.getInObject(object :: Object, Array.slice(oldPath, 1, length))

		if parent then
			local lastOld = oldPath[length] :: number
			local lastNew = newPath[length] :: number

			parent[lastNew] = parent[lastOld]

			if Array.isArray(parent) then
				Array.splice(parent, lastOld, 1)
			else
				parent[lastOld] = nil
			end
		end
	end
end
exports.setInObject = function(object: Object?, path: Array<string | number>, value)
	local length = #path
	local last = path[length]

	if object ~= nil then
		local parent = exports.getInObject(object :: Object, Array.slice(path, 1, length))

		if parent then
			parent[last] = value
		end
	end
end

-- ROBLOX deviation: Luau can't express enumeration of literals
-- export type DataType =
--   | 'array'
--   | 'array_buffer'
--   | 'bigint'
--   | 'boolean'
--   | 'data_view'
--   | 'date'
--   | 'function'
--   | 'html_all_collection'
--   | 'html_element'
--   | 'infinity'
--   | 'iterator'
--   | 'opaque_iterator'
--   | 'nan'
--   | 'null'
--   | 'number'
--   | 'object'
--   | 'react_element'
--   | 'regexp'
--   | 'string'
--   | 'symbol'
--   | 'typed_array'
--   | 'undefined'
--   | 'unknown';
export type DataType = string

-- /**
--  * Get a enhanced/artificial type string based on the object instance
--  */
exports.getDataType = function(data: Object?): DataType
	if data == nil then
		return "null"
		-- ROBLOX deviation: no undefined in Lua
		-- elseif data == nil then
		--     return'undefined'
	end

	if isElement(data) then
		return "react_element"
	end

	-- ROBLOX deviation: only applies to web
	-- if (typeof HTMLElement !== 'undefined' && data instanceof HTMLElement) {
	--     return 'html_element';
	--   }

	local type_ = typeof(data)
	if type_ == "bigint" then
		return "bigint"
	elseif type_ == "boolean" then
		return "boolean"
	elseif type_ == "function" then
		return "function"
	elseif type_ == "number" then
		if Number.isNaN(data) then
			return "nan"
		elseif not Number.isFinite(data) then
			return "infinity"
		else
			return "number"
		end
	elseif type_ == "object" then
		if Array.isArray(data) then
			return "array"

			-- ROBLOX deviation: only applies to web
			-- elseif ArrayBuffer.isView(data) then
			-- return Object.hasOwnProperty(data.constructor, 'BYTES_PER_ELEMENT')
			-- and 'typed_array'
			-- or 'data_view'
			-- elseif data.constructor and data.constructor.name == 'ArrayBuffer' then
			-- HACK This ArrayBuffer check is gross is there a better way?
			-- We could try to create a new DataView with the value.
			-- If it doesn't error, we know it's an ArrayBuffer,
			-- but this seems kind of awkward and expensive.
			-- return 'array_buffer'
			-- elseif typeof(data[Symbol.iterator]) == 'function' then
			-- return data[Symbol.iterator]() == data
			--   ? 'opaque_iterator'
			--   : 'iterator'
			-- elseif (data.constructor and data.constructor.name == 'RegExp'then
			-- return 'regexp'
			-- else
			-- const toStringValue = Object.prototype.toString.call(data)
			-- if (toStringValue == '[object Date]'then
			--   return 'date'
			-- elseif (toStringValue == '[object HTMLAllCollection]'then
			--   return 'html_all_collection'
			-- }
			--   }
		else
			return "object"
		end
	elseif type_ == "string" then
		return "string"
		-- ROBLOX TODO? detect our Symbol polyfill here?
		-- elseif type_ == 'symbol' then
		--   return 'symbol'
	elseif type_ == "nil" then
		-- ROBLOX deviation: skip web-specific stuff
		--   if (
		-- Object.prototype.toString.call(data) == '[object HTMLAllCollection]'
		--   then
		-- return 'html_all_collection'
		--   }
		return "nil"
	else
		return "unknown"
	end
end

exports.getDisplayNameForReactElement = function(element): string | nil
	local elementType = typeOf(element)
	if elementType == ContextConsumer then
		return "ContextConsumer"
	elseif elementType == ContextProvider then
		return "ContextProvider"
	elseif elementType == ForwardRef then
		return "ForwardRef"
	elseif elementType == Fragment then
		return "Fragment"
	elseif elementType == Lazy then
		return "Lazy"
	elseif elementType == Memo then
		return "Memo"
	elseif elementType == Portal then
		return "Portal"
	elseif elementType == Profiler then
		return "Profiler"
	elseif elementType == StrictMode then
		return "StrictMode"
	elseif elementType == Suspense then
		return "Suspense"
	elseif elementType == SuspenseList then
		return "SuspenseList"
	else
		local type_ = if element then element.type else nil
		if typeof(type_) == "string" then
			return type_
		elseif typeof(type_) == "function" then
			return exports.getDisplayName(type_, "Anonymous")
		elseif type_ ~= nil then
			return "NotImplementedInDevtools"
		else
			return "Element"
		end
	end
end

local MAX_PREVIEW_STRING_LENGTH = 50

local function truncateForDisplay(string_: string, length: number?)
	length = length or MAX_PREVIEW_STRING_LENGTH

	if string.len(string_) > (length :: number) then
		return string.sub(string_, 1, (length :: number) + 1) .. "…"
	else
		return string_
	end
end

-- Attempts to mimic Chrome's inline preview for values.
-- For example, the following value...
--   {
--      foo: 123,
--      bar: "abc",
--      baz: [true, false],
--      qux: { ab: 1, cd: 2 }
--   };
--
-- Would show a preview of...
--   {foo: 123, bar: "abc", baz: Array(2), qux: {…}}
--
-- And the following value...
--   [
--     123,
--     "abc",
--     [true, false],
--     { foo: 123, bar: "abc" }
--   ];
--
-- Would show a preview of...
--   [123, "abc", Array(2), {…}]

function exports.formatDataForPreview(data: Object, showFormattedValue: boolean): string
	if data[meta.type] ~= nil then
		return (function()
			if showFormattedValue then
				return data[meta.preview_long]
			end
			return data[meta.preview_short]
		end)()
	end

	local type_ = exports.getDataType(data)

	if type_ == "html_element" then
		return string.format("<%s />", truncateForDisplay(string.lower(data.tagName)))
	elseif type_ == "function" then
		return truncateForDisplay(string.format(
			"ƒ %s() {}",
			(function()
				if typeof(data.name) == "function" then
					return ""
				end
				return data.name
			end)()
		))
	elseif type_ == "string" then
		return string.format('"%s"', tostring(data))
		-- ROBLOX TODO? should we support our RegExp and Symbol polyfills here?
		-- elseif type_ == 'bigint' then
		-- elseif type_ == 'regexp' then
		-- elseif type_ == 'symbol' then
	elseif type_ == "react_element" then
		return string.format(
			"<%s />",
			truncateForDisplay(exports.getDisplayNameForReactElement(data) or "Unknown")
		)
		-- elseif type_ == 'array_buffer' then
		-- elseif type_ == 'data_view' then
	elseif type_ == "array" then
		local array: Array<any> = data :: any
		if showFormattedValue then
			local formatted = ""
			for i = 1, #array do
				if i > 1 then
					formatted ..= ", "
				end
				formatted = formatted .. exports.formatDataForPreview(array[i], false)
				if string.len(formatted) > MAX_PREVIEW_STRING_LENGTH then
					-- Prevent doing a lot of unnecessary iteration...
					break
				end
			end
			return string.format("[%s]", truncateForDisplay(formatted))
		else
			local length = (function()
				if array[#meta] ~= nil then
					return array[#meta]
				end
				return #array
			end)()
			return string.format("Array(%s)", length)
		end
		-- ROBLOX deviation: don't implement web-specifics
		-- elseif type_ == 'typed_array' then
		-- elseif type_ == 'iterator' then
		-- elseif type_ == 'opaque_iterator' then
		-- ROBLOX TODO? should we support Luau's datetime object?
		-- elseif type_ == 'date' then
	elseif type_ == "object" then
		if showFormattedValue then
			local keys = exports.getAllEnumerableKeys(data)
			table.sort(keys, exports.alphaSortKeys)

			local formatted = ""
			for i = 1, #keys do
				local key = keys[i] :: string
				if i > 1 then
					formatted = formatted .. ", "
				end
				formatted = formatted
					.. string.format(
						"%s: %s",
						tostring(key),
						exports.formatDataForPreview(data[key], false)
					)
				if string.len(formatted) > MAX_PREVIEW_STRING_LENGTH then
					-- Prevent doing a lot of unnecessary iteration...
					break
				end
			end
			return string.format("{%s}", truncateForDisplay(formatted))
		else
			return "{…}"
		end
	elseif
		type_ == "boolean"
		or type_ == "number"
		or type_ == "infinity"
		or type_ == "nan"
		or type_ == "null"
		or type_ == "undefined"
	then
		return tostring(data)
	else
		local ok, result = pcall(truncateForDisplay, "" .. tostring(data))
		return if ok then result else "unserializable"
	end
end

return exports
