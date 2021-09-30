-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/backend/ReactSymbols.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]
local exports = {}
exports.CONCURRENT_MODE_NUMBER = 0xeacf
exports.CONCURRENT_MODE_SYMBOL_STRING = "Symbol(react.concurrent_mode)"

exports.CONTEXT_NUMBER = 0xeace
exports.CONTEXT_SYMBOL_STRING = "Symbol(react.context)"

exports.DEPRECATED_ASYNC_MODE_SYMBOL_STRING = "Symbol(react.async_mode)"

exports.ELEMENT_NUMBER = 0xeac7
exports.ELEMENT_SYMBOL_STRING = "Symbol(react.element)"

exports.DEBUG_TRACING_MODE_NUMBER = 0xeae1
exports.DEBUG_TRACING_MODE_SYMBOL_STRING = "Symbol(react.debug_trace_mode)"

exports.FORWARD_REF_NUMBER = 0xead0
exports.FORWARD_REF_SYMBOL_STRING = "Symbol(react.forward_ref)"

exports.FRAGMENT_NUMBER = 0xeacb
exports.FRAGMENT_SYMBOL_STRING = "Symbol(react.fragment)"

exports.LAZY_NUMBER = 0xead4
exports.LAZY_SYMBOL_STRING = "Symbol(react.lazy)"

exports.MEMO_NUMBER = 0xead3
exports.MEMO_SYMBOL_STRING = "Symbol(react.memo)"

exports.OPAQUE_ID_NUMBER = 0xeae0
exports.OPAQUE_ID_SYMBOL_STRING = "Symbol(react.opaque.id)"

exports.PORTAL_NUMBER = 0xeaca
exports.PORTAL_SYMBOL_STRING = "Symbol(react.portal)"

exports.PROFILER_NUMBER = 0xead2
exports.PROFILER_SYMBOL_STRING = "Symbol(react.profiler)"

exports.PROVIDER_NUMBER = 0xeacd
exports.PROVIDER_SYMBOL_STRING = "Symbol(react.provider)"

exports.SCOPE_NUMBER = 0xead7
exports.SCOPE_SYMBOL_STRING = "Symbol(react.scope)"

exports.STRICT_MODE_NUMBER = 0xeacc
exports.STRICT_MODE_SYMBOL_STRING = "Symbol(react.strict_mode)"

exports.SUSPENSE_NUMBER = 0xead1
exports.SUSPENSE_SYMBOL_STRING = "Symbol(react.suspense)"

exports.SUSPENSE_LIST_NUMBER = 0xead8
exports.SUSPENSE_LIST_SYMBOL_STRING = "Symbol(react.suspense_list)"

return exports
