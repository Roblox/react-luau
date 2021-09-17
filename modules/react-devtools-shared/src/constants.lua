-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/constants.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

local exports = {}

-- Flip this flag to true to enable verbose console debug logging.
exports.__DEBUG__ = _G.__DEBUG__

exports.TREE_OPERATION_ADD = 1
exports.TREE_OPERATION_REMOVE = 2
exports.TREE_OPERATION_REORDER_CHILDREN = 3
exports.TREE_OPERATION_UPDATE_TREE_BASE_DURATION = 4

exports.LOCAL_STORAGE_FILTER_PREFERENCES_KEY = "React::DevTools::componentFilters"

exports.SESSION_STORAGE_LAST_SELECTION_KEY = "React::DevTools::lastSelection"

exports.SESSION_STORAGE_RECORD_CHANGE_DESCRIPTIONS_KEY =
	"React::DevTools::recordChangeDescriptions"

exports.SESSION_STORAGE_RELOAD_AND_PROFILE_KEY = "React::DevTools::reloadAndProfile"

exports.LOCAL_STORAGE_SHOULD_BREAK_ON_CONSOLE_ERRORS =
	"React::DevTools::breakOnConsoleErrors"

exports.LOCAL_STORAGE_SHOULD_PATCH_CONSOLE_KEY = "React::DevTools::appendComponentStack"

exports.LOCAL_STORAGE_TRACE_UPDATES_ENABLED_KEY = "React::DevTools::traceUpdatesEnabled"

exports.PROFILER_EXPORT_VERSION = 4

exports.CHANGE_LOG_URL =
	"https://github.com/facebook/react/blob/master/packages/react-devtools/CHANGELOG.md"

exports.UNSUPPORTED_VERSION_URL =
	"https://reactjs.org/blog/2019/08/15/new-react-devtools.html#how-do-i-get-the-old-version-back"

-- HACK
--
-- Extracting during build time avoids a temporarily invalid state for the inline target.
-- Sometimes the inline target is rendered before root styles are applied,
-- which would result in e.g. NaN itemSize being passed to react-window list.
--
local COMFORTABLE_LINE_HEIGHT
local COMPACT_LINE_HEIGHT

-- ROBLOX deviation: we won't use the CSS, and don't have a bundler, so always use the 'fallback'
-- We can't use the Webpack loader syntax in the context of Jest,
-- so tests need some reasonably meaningful fallback value.
COMFORTABLE_LINE_HEIGHT = 15
COMPACT_LINE_HEIGHT = 10

exports.COMFORTABLE_LINE_HEIGHT = COMFORTABLE_LINE_HEIGHT
exports.COMPACT_LINE_HEIGHT = COMPACT_LINE_HEIGHT

return exports
