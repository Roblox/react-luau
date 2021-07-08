-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/storage.js
-- /*
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  */

local exports = {}
if _G.__LOCALSTORAGE__ == nil then
	_G.__LOCALSTORAGE__ = {}
end

if _G.__SESSIONSTORAGE__ == nil then
	_G.__SESSIONSTORAGE__ = {}
end

-- ROBLOX FIXME: what's a high-performance storage that for temporal (current DM lifetime) and permanent (beyond current DM lifetime)
local localStorage = _G.__LOCALSTORAGE__
local sessionStorage = _G.__SESSIONSTORAGE__

exports.localStorageGetItem = function(key: string): any
	return localStorage[key]
end
exports.localStorageRemoveItem = function(key: string): ()
	localStorage[key] = nil
end
exports.localStorageSetItem = function(key: string, value: any): ()
	localStorage[key] = value
end
exports.sessionStorageGetItem = function(key: string): any
	return sessionStorage[key]
end
exports.sessionStorageRemoveItem = function(key: string): ()
	sessionStorage[key] = nil
end
exports.sessionStorageSetItem = function(key: string, value: any): ()
	sessionStorage[key] = value
end

return exports
