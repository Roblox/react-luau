-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/backend/console.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

local Types = require(script.Parent.types)
type ReactRenderer = Types.ReactRenderer

local exports = {}

-- ROBLOX FIXME: Stub for now
function exports.patch(
	_object: {
		appendComponentStack: boolean,
		breakOnConsoleErrors: boolean,
	}
): () end

function exports.unpatch(): () end

function exports.error(...)
	error(...)
end

function exports.warn(...)
	warn(...)
end

function exports.log(...)
	print(...)
end

function exports.registerRenderer(_renderer: ReactRenderer): () end

return exports
