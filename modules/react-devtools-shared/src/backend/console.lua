-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/backend/console.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

local console = {}

-- ROBLOX FIXME: Stub for now
function console.patch() end

function console.unpatch() end

function console.error(...)
	error(...)
end

function console.warn(...)
	warn(...)
end

function console.log(...)
	print(...)
end

function console.registerRenderer() end

return console
