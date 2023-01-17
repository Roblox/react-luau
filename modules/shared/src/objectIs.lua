--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/6faf6f5eb1705eef39a1d762d6ee381930f36775/packages/shared/objectIs.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

--[[*
 * inlined Object.is polyfill to avoid requiring consumers ship their own
 * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/is
 ]]
local function is(x: any, y: any): boolean
	return x == y and (x ~= 0 or 1 / x == 1 / y) or x ~= x and y ~= y -- eslint-disable-line no-self-compare
end

-- deviation: Object isn't a global in lua, so `Object.is` will never exist
local objectIs = is

return objectIs
