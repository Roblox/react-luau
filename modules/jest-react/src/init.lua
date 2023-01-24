-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.2/packages/jest-react/index.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 ]]
local Packages = script.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Object = LuauPolyfill.Object
local exports = {}
-- ROBLOX deviation START: extract to variable, fix import and export type
--  Object.assign(exports, require(script.src.JestReact))
local jestReactModule = Object.assign(exports, require(script.JestReact))
return exports :: typeof(exports) & typeof(jestReactModule)
-- ROBLOX deviation END
