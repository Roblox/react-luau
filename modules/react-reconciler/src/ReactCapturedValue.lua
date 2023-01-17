--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react-reconciler/src/ReactCapturedValue.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber

local getStackByFiberInDevAndProd =
	require(script.Parent.ReactFiberComponentStack).getStackByFiberInDevAndProd

export type CapturedValue<T> = {
	value: T,
	source: Fiber | nil,
	stack: string | nil,
}

local exports = {}

exports.createCapturedValue = function<T>(value: T, source: Fiber | nil): CapturedValue<T>
	-- If the value is an error, call this function immediately after it is thrown
	-- so the stack is accurate.
	return {
		value = value,
		source = source,
		stack = getStackByFiberInDevAndProd(source),
	}
end

return exports
