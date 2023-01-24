-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.2/packages/react-cache/index.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]
-- ROBLOX deviation START: simplify
-- local Packages --[[ ROBLOX comment: must define Packages module ]]
-- local LuauPolyfill = require(Packages.LuauPolyfill)
-- local Object = LuauPolyfill.Object
-- local exports = {}
--
-- Object.assign(exports, require(script.src.ReactCacheOld))
-- return exports
return require(script.ReactCacheOld)
-- ROBLOX deviation END
