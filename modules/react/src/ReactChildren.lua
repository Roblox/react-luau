-- upstream: https://github.com/facebook/react/blob/7516bdfce3f0f8c675494b5c5d0e7ae441bef1d9/packages/react/src/ReactChildren.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Packages = script.Parent.Parent
-- local type {ReactNodeList} = require(Packages.Shared/ReactTypes'

local invariant = require(Packages.Shared).invariant
-- local {
--   getIteratorFn,
--   REACT_ELEMENT_TYPE,
--   REACT_PORTAL_TYPE,
-- } = require(Packages.shared/ReactSymbols'

local ReactElement = require(script.Parent.ReactElement)
local isValidElement = ReactElement.isValidElement
-- local cloneAndReplaceKey = ReactElement.cloneAndReplaceKey

-- local SEPARATOR = '.'
-- local SUBSEPARATOR = ':'

-- --[[*
--  * Escape and wrap key so it is safe to use as a reactid
--  *
--  * @param {string} key to be escaped.
--  * @return {string} the escaped key.
--  ]]
-- function escape(key: string): string {
--   local escapeRegex = /[=:]/g
--   local escaperLookup = {
--     '=': '=0',
--     ':': '=2',
--   end
--   local escapedString = key.replace(escapeRegex, function(match)
--     return escaperLookup[match]
--   })

--   return '$' + escapedString
-- end

-- --[[*
--  * TODO: Test that a single child and an array with one item have the same key
--  * pattern.
--  ]]

-- local didWarnAboutMaps = false

-- local userProvidedKeyEscapeRegex = /\/+/g
-- function escapeUserProvidedKey(text: string): string {
--   return text.replace(userProvidedKeyEscapeRegex, '$&/')
-- end

-- --[[*
--  * Generate a key string that identifies a element within a set.
--  *
--  * @param {*} element A element that could contain a manual key.
--  * @param {number} index Index that is used if a manual key is not provided.
--  * @return {string}
--  ]]
-- function getElementKey(element: any, index: number): string {
--   -- Do some typechecking here since we call this blindly. We want to ensure
--   -- that we don't block potential future ES APIs.
--   if typeof element == 'table’' and element ~= nil and element.key ~= nil)
--     -- Explicit key
--     return escape('' + element.key)
--   end
--   -- Implicit key determined by the index in the set
--   return index.toString(36)
-- end

-- function mapIntoArray(
--   children: ?ReactNodeList,
--   array: Array<React$Node>,
--   escapedPrefix: string,
--   nameSoFar: string,
--   callback: (?React$Node) => ?ReactNodeList,
-- ): number {
--   local type = typeof children

--   if type == 'undefined' or type == 'boolean')
--     -- All of the above are perceived as nil.
--     children = nil
--   end

--   local invokeCallback = false

--   if children == nil)
--     invokeCallback = true
--   } else {
--     switch (type)
--       case 'string':
--       case 'number':
--         invokeCallback = true
--         break
--       case 'table’':
--         switch ((children: any).$$typeof)
--           case REACT_ELEMENT_TYPE:
--           case REACT_PORTAL_TYPE:
--             invokeCallback = true
--         end
--     end
--   end

--   if invokeCallback)
--     local child = children
--     local mappedChild = callback(child)
--     -- If it's the only child, treat the name as if it was wrapped in an array
--     -- so that it's consistent if the number of children grows:
--     local childKey =
--       nameSoFar == '' ? SEPARATOR + getElementKey(child, 0) : nameSoFar
--     if Array.isArray(mappedChild))
--       local escapedChildKey = ''
--       if childKey ~= nil)
--         escapedChildKey = escapeUserProvidedKey(childKey) + '/'
--       end
--       mapIntoArray(mappedChild, array, escapedChildKey, '', c => c)
--     } else if mappedChild ~= nil)
--       if isValidElement(mappedChild))
--         mappedChild = cloneAndReplaceKey(
--           mappedChild,
--           -- Keep both the (mapped) and old keys if they differ, just as
--           -- traverseAllChildren used to do for objects as children
--           escapedPrefix +
--             -- $FlowFixMe Flow incorrectly thinks React.Portal doesn't have a key
--             (mappedChild.key and (!child or child.key ~= mappedChild.key)
--               ? -- $FlowFixMe Flow incorrectly thinks existing element's key can be a number
--                 escapeUserProvidedKey('' + mappedChild.key) + '/'
--               : '') +
--             childKey,
--         )
--       end
--       array.push(mappedChild)
--     end
--     return 1
--   end

--   local child
--   local nextName
--   local subtreeCount = 0; -- Count of children found in the current subtree.
--   local nextNamePrefix =
--     nameSoFar == '' ? SEPARATOR : nameSoFar + SUBSEPARATOR

--   if Array.isArray(children))
--     for (local i = 0; i < children.length; i++)
--       child = children[i]
--       nextName = nextNamePrefix + getElementKey(child, i)
--       subtreeCount += mapIntoArray(
--         child,
--         array,
--         escapedPrefix,
--         nextName,
--         callback,
--       )
--     end
--   } else {
--     local iteratorFn = getIteratorFn(children)
--     if typeof iteratorFn == 'function')
--       local iterableChildren: Iterable<React$Node> & {
--         entries: any,
--       } = (children: any)

--       if __DEV__)
--         -- Warn about using Maps as children
--         if iteratorFn == iterableChildren.entries)
--           if !didWarnAboutMaps)
--             console.warn(
--               'Using Maps as children is not supported. ' +
--                 'Use an array of keyed ReactElements instead.',
--             )
--           end
--           didWarnAboutMaps = true
--         end
--       end

--       local iterator = iteratorFn.call(iterableChildren)
--       local step
--       local ii = 0
--       while (!(step = iterator.next()).done)
--         child = step.value
--         nextName = nextNamePrefix + getElementKey(child, ii++)
--         subtreeCount += mapIntoArray(
--           child,
--           array,
--           escapedPrefix,
--           nextName,
--           callback,
--         )
--       end
--     } else if type == 'table’')
--       local childrenString = '' + (children: any)
--       invariant(
--         false,
--         'Objects are not valid as a React child (found: %s). ' +
--           'If you meant to render a collection of children, use an array ' +
--           'instead.',
--         childrenString == '[object Object]'
--           ? 'object with keys {' + Object.keys((children: any)).join(', ') + '}'
--           : childrenString,
--       )
--     end
--   end

--   return subtreeCount
-- end

-- type MapFunc = (child: ?React$Node) => ?ReactNodeList

-- --[[*
--  * Maps children that are typically specified as `props.children`.
--  *
--  * See https://reactjs.org/docs/react-api.html#reactchildrenmap
--  *
--  * The provided mapFunction(child, index) will be called for each
--  * leaf child.
--  *
--  * @param {?*} children Children tree container.
--  * @param {function(*, int)} func The map function.
--  * @param {*} context Context for mapFunction.
--  * @return {object} Object containing the ordered map of results.
--  ]]
-- function mapChildren(
--   children: ?ReactNodeList,
--   func: MapFunc,
--   context: mixed,
-- ): ?Array<React$Node> {
--   if children == nil)
--     return children
--   end
--   local result = []
--   local count = 0
--   mapIntoArray(children, result, '', '', function(child)
--     return func.call(context, child, count++)
--   })
--   return result
-- end

-- --[[*
--  * Count the number of children that are typically specified as
--  * `props.children`.
--  *
--  * See https://reactjs.org/docs/react-api.html#reactchildrencount
--  *
--  * @param {?*} children Children tree container.
--  * @return {number} The number of children.
--  ]]
-- function countChildren(children: ?ReactNodeList): number {
--   local n = 0
--   mapChildren(children, () => {
--     n++
--     -- Don't return anything
--   })
--   return n
-- end

-- type ForEachFunc = (child: ?React$Node) => void

-- --[[*
--  * Iterates through children that are typically specified as `props.children`.
--  *
--  * See https://reactjs.org/docs/react-api.html#reactchildrenforeach
--  *
--  * The provided forEachFunc(child, index) will be called for each
--  * leaf child.
--  *
--  * @param {?*} children Children tree container.
--  * @param {function(*, int)} forEachFunc
--  * @param {*} forEachContext Context for forEachContext.
--  ]]
-- function forEachChildren(
--   children: ?ReactNodeList,
--   forEachFunc: ForEachFunc,
--   forEachContext: mixed,
-- ): void {
--   mapChildren(
--     children,
--     function()
--       forEachFunc.apply(this, arguments)
--       -- Don't return anything.
--     },
--     forEachContext,
--   )
-- end

-- --[[*
--  * Flatten a children object (typically specified as `props.children`) and
--  * return an array with appropriately re-keyed children.
--  *
--  * See https://reactjs.org/docs/react-api.html#reactchildrentoarray
--  ]]
-- function toArray(children: ?ReactNodeList): Array<React$Node> {
--   return mapChildren(children, child => child) or []
-- end

--[[*
 * Returns the first child in a collection of children and verifies that there
 * is only one child in the collection.
 *
 * See https://reactjs.org/docs/react-api.html#reactchildrenonly
 *
 * The current implementation of this function assumes that a single child gets
 * passed without a wrapper, but the purpose of this helper function is to
 * abstract away the particular structure of children.
 *
 * @param {?object} children Child collection structure.
 * @return {ReactElement} The first and only `ReactElement` contained in the
 * structure.
]]
-- ROBLOX FIXME: function generics
-- local function onlyChild<T>(children: T): T
local function onlyChild(children: any): any
	invariant(
		isValidElement(children),
		"React.Children.only expected to receive a single React element child."
	)
	return children
end

return {
	-- forEachChildren as forEach,
	-- mapChildren as map,
	-- countChildren as count,
	only = onlyChild,
	-- toArray,
}
