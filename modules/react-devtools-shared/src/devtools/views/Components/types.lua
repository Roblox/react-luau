-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/devtools/views/Components/types.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

local Packages = script.Parent.Parent.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
type Array<T> = LuauPolyfill.Array<T>
type Object = LuauPolyfill.Object

local ReactShared = require(Packages.Shared)
type Source = ReactShared.Source
local Hydration = require(script.Parent.Parent.Parent.Parent.hydration)
type Dehydrated = Hydration.Dehydrated
type Unserializable = Hydration.Unserializable

local ReactDevtoolsSharedTypes = require(script.Parent.Parent.Parent.Parent.types)
type ElementType = ReactDevtoolsSharedTypes.ElementType

-- Each element on the frontend corresponds to a Fiber on the backend.
-- Some of its information (e.g. id, type, displayName) come from the backend.
-- Other bits (e.g. weight and depth) are computed on the frontend for windowing and display purposes.
-- Elements are updated on a push basis– meaning the backend pushes updates to the frontend when needed.
export type Element = {
	id: number,
	parentID: number,
	children: Array<number>,
	type: ElementType,
	displayName: string | nil,
	key: number | string | nil,

	hocDisplayNames: nil | Array<string>,

	-- Should the elements children be visible in the tree?
	isCollapsed: boolean,

	-- Owner (if available)
	ownerID: number,

	-- How many levels deep within the tree is this element?
	-- This determines how much indentation (left padding) should be used in the Elements tree.
	depth: number,

	-- How many nodes (including itself) are below this Element within the tree.
	-- This property is used to quickly determine the total number of Elements,
	-- and the Element at any given index (for windowing purposes).
	weight: number,
}

export type Owner = {
	displayName: string | nil,
	id: number,
	hocDisplayNames: Array<string> | nil,
	type: ElementType,
}

export type OwnersList = { id: number, owners: Array<Owner> | nil }

export type InspectedElement = {
	id: number,

	-- Does the current renderer support editable hooks and function props?
	canEditHooks: boolean,
	canEditFunctionProps: boolean,

	-- Does the current renderer support advanced editing interface?
	canEditHooksAndDeletePaths: boolean,
	canEditHooksAndRenamePaths: boolean,
	canEditFunctionPropsDeletePaths: boolean,
	canEditFunctionPropsRenamePaths: boolean,

	-- Is this Suspense, and can its value be overridden now?
	canToggleSuspense: boolean,

	-- Can view component source location.
	canViewSource: boolean,

	-- Does the component have legacy context attached to it.
	hasLegacyContext: boolean,

	-- Inspectable properties.
	context: Object | nil,
	hooks: Object | nil,
	props: Object | nil,
	state: Object | nil,
	key: number | string | nil,

	-- List of owners
	owners: Array<Owner> | nil,

	-- Location of component in source code.
	source: Source | nil,

	type: ElementType,

	-- Meta information about the root this element belongs to.
	rootType: string | nil,

	-- Meta information about the renderer that created this element.
	rendererPackageName: string | nil,
	rendererVersion: string | nil,
}

-- TODO: Add profiling type

export type DehydratedData = {
	cleaned: Array<Array<string | number>>,
	data: string
		| Dehydrated
		| Unserializable
		| Array<Dehydrated>
		| Array<Unserializable>
		| { [string]: string | Dehydrated | Unserializable },
	unserializable: Array<Array<string | number>>,
}

return {}
