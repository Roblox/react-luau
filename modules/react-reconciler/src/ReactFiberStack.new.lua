-- ROBLOX upstream: https://github.com/facebook/react/blob/17f582e0453b808860be59ed3437c6a426ae52de/packages/react-reconciler/src/ReactFiberStack.new.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local Packages = script.Parent.Parent
-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber

type Array<T> = { [number]: T }
-- deviation: use this table when pushing nil values
type null = {}
local NULL: null = {}

export type StackCursor<T> = { current: T }

local valueStack: Array<any> = {}

local fiberStack: Array<Fiber | null>

if _G.__DEV__ then
	fiberStack = {}
end

local index = 0

local function createCursor<T>(defaultValue: T): StackCursor<T>
	return {
		current = defaultValue,
	}
end

local function isEmpty(): boolean
	return index == 0
end

local function pop<T>(cursor: StackCursor<T>, fiber: Fiber): ()
	if index < 1 then
		if _G.__DEV__ then
			console.error("Unexpected pop.")
		end
		return
	end

	if _G.__DEV__ then
		-- ROBLOX TODO: workaround for Luau analysis bug
		if fiber ~= fiberStack[index] :: Fiber then
			console.error("Unexpected Fiber popped.")
		end
	end

	local value = valueStack[index]
	if value == NULL then
		-- ROBLOX TODO: this is a sort of incorrect typing in upstream
		cursor.current = nil :: any
	else
		cursor.current = value
	end

	valueStack[index] = nil

	if _G.__DEV__ then
		fiberStack[index] = nil
	end

	index -= 1
end

local function push<T>(cursor: StackCursor<T>, value: T, fiber: Fiber): ()
	index += 1

	local stackValue = cursor.current
	if stackValue == nil then
		valueStack[index] = NULL
	else
		valueStack[index] = stackValue
	end

	if _G.__DEV__ then
		fiberStack[index] = fiber
	end

	cursor.current = value
end

local function checkThatStackIsEmpty()
	if _G.__DEV__ then
		if index ~= 0 then
			console.error("Expected an empty stack. Something was not reset properly.")
		end
	end
end

local function resetStackAfterFatalErrorInDev()
	if _G.__DEV__ then
		index = 0
		-- ROBLOX deviation: Original js simply sets `length`
		table.clear(valueStack)
		table.clear(fiberStack)
	end
end

return {
	createCursor = createCursor,
	isEmpty = isEmpty,
	pop = pop,
	push = push,
	-- DEV only:
	checkThatStackIsEmpty = checkThatStackIsEmpty,
	resetStackAfterFatalErrorInDev = resetStackAfterFatalErrorInDev,
}
