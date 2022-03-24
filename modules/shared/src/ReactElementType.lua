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
local LuauPolyfill = require(Packages.LuauPolyfill)
type Object = LuauPolyfill.Object

local flowtypes = require(script.Parent["flowtypes.roblox"])
type React_Element<ElementType> = flowtypes.React_Element<ElementType>
type React_StatelessFunctionalComponent<P> = flowtypes.React_StatelessFunctionalComponent<
	P
>
type React_ComponentType<P> = flowtypes.React_ComponentType<P>

export type Source = {
	fileName: string,
	lineNumber: number,
}
type Key = string | number
-- ROBLOX deviation: we're using the TypeScript definition here, which is more strict
export type ReactElement<P = Object, T = any> = {
	["$$typeof"]: number,

	-- ROBLOX FIXME Luau: Luau has some trouble and inlining the type param from createElement doesn't help
	type: React_StatelessFunctionalComponent<P> | React_ComponentType<P> | string,
	-- type: T,
	key: Key | nil,
	ref: any,
	props: P,

	-- ROBLOX deviation: upstream has this as interface, which is extensible, Luau types are closed by default
	-- ReactFiber
	_owner: any,

	-- __DEV__
	_store: any?,
	_self: React_Element<any>?,
	_shadowChildren: any?,
	_source: Source?,
}

-- deviation: Return something so that the module system is happy
return {}
