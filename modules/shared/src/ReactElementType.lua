--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local ReactTypes = require(script.Parent.ReactTypes)
type React_Element<ElementType> = ReactTypes.React_Element<ElementType>

export type Source = {
	fileName: string,
	lineNumber: number,
}

export type ReactElement = {
	-- deviation: No way to specify string with special characters
	-- $$typeof: any,
	[string]: any,

	type: any,
	key: any,
	ref: any,
	props: any,
	-- ReactFiber
	_owner: any,

	-- __DEV__
	_store: {
		validated: boolean,
		[string]: any,
	},
	-- deviation: No built in element flow types
	_self: React_Element<any>,
	_shadowChildren: any,
	_source: Source,
}

-- deviation: Return something so that the module system is happy
return {}
