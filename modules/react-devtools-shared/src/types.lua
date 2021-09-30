-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/types.js
-- /*
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  */

type Array<T> = { [number]: T }
type Function = (...any) -> ...any
local exports = {}

-- WARNING
-- The values below are referenced by ComponentFilters (which are saved via localStorage).
-- Do not change them or it will break previously saved user customizations.
--
-- If new element types are added, use new numbers rather than re-ordering existing ones.
-- Changing these types is also a backwards breaking change for the standalone shell,
-- since the frontend and backend must share the same values-
-- and the backend is embedded in certain environments (like React Native).

export type Wall = {
	listen: (Function) -> Function,
	send: (string, any, Array<any>) -> (),
}

exports.ElementTypeClass = 1
exports.ElementTypeContext = 2
exports.ElementTypeFunction = 5
exports.ElementTypeForwardRef = 6
exports.ElementTypeHostComponent = 7
exports.ElementTypeMemo = 8
exports.ElementTypeOtherOrUnknown = 9
exports.ElementTypeProfiler = 10
exports.ElementTypeRoot = 11
exports.ElementTypeSuspense = 12
exports.ElementTypeSuspenseList = 13

-- Different types of elements displayed in the Elements tree.
-- These types may be used to visually distinguish types,
-- or to enable/disable certain functionality.
-- ROBLOX deviation: Luau doesn't support literals as types: 1 | 2 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13
export type ElementType = number

-- WARNING
-- The values below are referenced by ComponentFilters (which are saved via localStorage).
-- Do not change them or it will break previously saved user customizations.
-- If new filter types are added, use new numbers rather than re-ordering existing ones.
exports.ComponentFilterElementType = 1
exports.ComponentFilterDisplayName = 2
exports.ComponentFilterLocation = 3
exports.ComponentFilterHOC = 4

-- ROBLOX deviation: Luau doesn't support literals as types: 1 | 2 | 3 | 4
export type ComponentFilterType = number

-- Hide all elements of types in this Set.
-- We hide host components only by default.
export type ElementTypeComponentFilter = {
	isEnabled: boolean,
	-- ROBLOX deviation: Luau doesn't support literals as types: 1
	type: number,
	value: ElementType,
}

-- Hide all elements with displayNames or paths matching one or more of the RegExps in this Set.
-- Path filters are only used when elements include debug source location.
export type RegExpComponentFilter = {
	isEnabled: boolean,
	isValid: boolean,
	-- ROBLOX deviation: Luau doesn't support literals as types: 2 | 3
	type: number,
	value: string,
}

export type BooleanComponentFilter = {
	isEnabled: boolean,
	isValid: boolean,
	-- ROBLOX deviation: Luau doesn't support literals as types: 4
	type: number,
}

export type ComponentFilter =
	BooleanComponentFilter
	| ElementTypeComponentFilter
	| RegExpComponentFilter

return exports
