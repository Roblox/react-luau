-- ROBLOX upstream: https://github.com/facebook/react/blob/3cde22a84e246fc5361f038bf0c23405b2572c22/packages/react-reconciler/src/ReactTestSelectors.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]
local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
type Set<T> = { [T]: boolean }
type Array<T> = LuauPolyfill.Array<T>
type Function = (...any) -> ...any
type Object = LuauPolyfill.Object

-- local type {Fiber} = require(Packages.react-reconciler/src/ReactInternalTypes'
-- local type {Instance} = require(Packages../ReactFiberHostConfig'

-- local invariant = require(Packages.shared/invariant'
-- local {HostComponent, HostText} = require(Packages.react-reconciler/src/ReactWorkTags'
-- local getComponentName = require(Packages.shared/getComponentName'

local ReactFiberHostConfig = require(script.Parent.ReactFiberHostConfig)
local supportsTestSelectors = ReactFiberHostConfig.supportsTestSelectors
-- local {
--   findFiberRoot,
--   getBoundingRect,
--   getInstanceFromNode,
--   getTextContent,
--   isHiddenSubtree,
--   matchAccessibilityRole,
--   setFocusIfFocusable,
--   setupIntersectionObserver,
--   ,
-- } = require(Packages../ReactFiberHostConfig'

-- local COMPONENT_TYPE = 0b000
-- local HAS_PSEUDO_CLASS_TYPE = 0b001
-- local ROLE_TYPE = 0b010
-- local TEST_NAME_TYPE = 0b011
-- local TEXT_TYPE = 0b100

-- if typeof Symbol == 'function' and Symbol.for)
--   local symbolFor = Symbol.for
--   COMPONENT_TYPE = symbolFor('selector.component')
--   HAS_PSEUDO_CLASS_TYPE = symbolFor('selector.has_pseudo_class')
--   ROLE_TYPE = symbolFor('selector.role')
--   TEST_NAME_TYPE = symbolFor('selector.test_id')
--   TEXT_TYPE = symbolFor('selector.text')
-- end

-- type Type = Symbol | number

-- type ComponentSelector = {|
--   $$typeof: Type,
--   value: React$AbstractComponent<empty, mixed>,
-- |}

-- type HasPsuedoClassSelector = {|
--   $$typeof: Type,
--   value: Array<Selector>,
-- |}

-- type RoleSelector = {|
--   $$typeof: Type,
--   value: string,
-- |}

-- type TextSelector = {|
--   $$typeof: Type,
--   value: string,
-- |}

-- type TestNameSelector = {|
--   $$typeof: Type,
--   value: string,
-- |}

-- type Selector =
--   | ComponentSelector
--   | HasPsuedoClassSelector
--   | RoleSelector
--   | TextSelector
--   | TestNameSelector

local exports = {}

-- exports.createComponentSelector(
--   component: React$AbstractComponent<empty, mixed>,
-- ): ComponentSelector {
--   return {
--     $$typeof: COMPONENT_TYPE,
--     value: component,
--   }
-- end

-- exports.createHasPsuedoClassSelector(
--   selectors: Array<Selector>,
-- ): HasPsuedoClassSelector {
--   return {
--     $$typeof: HAS_PSEUDO_CLASS_TYPE,
--     value: selectors,
--   }
-- end

-- exports.createRoleSelector(role: string): RoleSelector {
--   return {
--     $$typeof: ROLE_TYPE,
--     value: role,
--   }
-- end

-- exports.createTextSelector(text: string): TextSelector {
--   return {
--     $$typeof: TEXT_TYPE,
--     value: text,
--   }
-- end

-- exports.createTestNameSelector(id: string): TestNameSelector {
--   return {
--     $$typeof: TEST_NAME_TYPE,
--     value: id,
--   }
-- end

-- function findFiberRootForHostRoot(hostRoot: Instance): Fiber {
--   local maybeFiber = getInstanceFromNode((hostRoot: any))
--   if maybeFiber ~= nil)
--     invariant(
--       typeof maybeFiber.memoizedProps['data-testname'] == 'string',
--       'Invalid host root specified. Should be either a React container or a node with a testname attribute.',
--     )
--     return ((maybeFiber: any): Fiber)
--   } else {
--     local fiberRoot = findFiberRoot(hostRoot)
--     invariant(
--       fiberRoot ~= nil,
--       'Could not find React container within specified host subtree.',
--     )
--     -- The Flow type for FiberRoot is a little funky.
--     -- createFiberRoot() cheats this by treating the root as :any and adding stateNode lazily.
--     return ((fiberRoot: any).stateNode.current: Fiber)
--   }
-- end

-- function matchSelector(fiber: Fiber, selector: Selector): boolean {
--   switch (selector.$$typeof)
--     case COMPONENT_TYPE:
--       if fiber.type == selector.value)
--         return true
--       }
--       break
--     case HAS_PSEUDO_CLASS_TYPE:
--       return hasMatchingPaths(
--         fiber,
--         ((selector: any): HasPsuedoClassSelector).value,
--       )
--     case ROLE_TYPE:
--       if fiber.tag == HostComponent)
--         local node = fiber.stateNode
--         if
--           matchAccessibilityRole(node, ((selector: any): RoleSelector).value)
--         )
--           return true
--         }
--       }
--       break
--     case TEXT_TYPE:
--       if fiber.tag == HostComponent or fiber.tag == HostText)
--         local textContent = getTextContent(fiber)
--         if
--           textContent ~= nil and
--           textContent.indexOf(((selector: any): TextSelector).value) >= 0
--         )
--           return true
--         }
--       }
--       break
--     case TEST_NAME_TYPE:
--       if fiber.tag == HostComponent)
--         local dataTestID = fiber.memoizedProps['data-testname']
--         if
--           typeof dataTestID == 'string' and
--           dataTestID.toLowerCase() ==
--             ((selector: any): TestNameSelector).value.toLowerCase()
--         )
--           return true
--         }
--       }
--       break
--     default:
--       invariant(null, 'Invalid selector type %s specified.', selector)
--       break
--   }

--   return false
-- end

-- function selectorToString(selector: Selector): string | nil {
--   switch (selector.$$typeof)
--     case COMPONENT_TYPE:
--       local displayName = getComponentName(selector.value) or 'Unknown'
--       return `<${displayName}>`
--     case HAS_PSEUDO_CLASS_TYPE:
--       return `:has(${selectorToString(selector) or ''})`
--     case ROLE_TYPE:
--       return `[role="${((selector: any): RoleSelector).value}"]`
--     case TEXT_TYPE:
--       return `"${((selector: any): TextSelector).value}"`
--     case TEST_NAME_TYPE:
--       return `[data-testname="${((selector: any): TestNameSelector).value}"]`
--     default:
--       invariant(null, 'Invalid selector type %s specified.', selector)
--       break
--   }

--   return nil
-- end

-- function findPaths(root: Fiber, selectors: Array<Selector>): Array<Fiber> {
--   local matchingFibers: Array<Fiber> = []

--   local stack = [root, 0]
--   local index = 0
--   while (index < stack.length)
--     local fiber = ((stack[index++]: any): Fiber)
--     local selectorIndex = ((stack[index++]: any): number)
--     local selector = selectors[selectorIndex]

--     if fiber.tag == HostComponent and isHiddenSubtree(fiber))
--       continue
--     } else {
--       while (selector ~= nil and matchSelector(fiber, selector))
--         selectorIndex++
--         selector = selectors[selectorIndex]
--       }
--     }

--     if selectorIndex == selectors.length)
--       matchingFibers.push(fiber)
--     } else {
--       local child = fiber.child
--       while (child ~= nil)
--         stack.push(child, selectorIndex)
--         child = child.sibling
--       }
--     }
--   }

--   return matchingFibers
-- end

-- -- Same as findPaths but with eager bailout on first match
-- function hasMatchingPaths(root: Fiber, selectors: Array<Selector>): boolean {
--   local stack = [root, 0]
--   local index = 0
--   while (index < stack.length)
--     local fiber = ((stack[index++]: any): Fiber)
--     local selectorIndex = ((stack[index++]: any): number)
--     local selector = selectors[selectorIndex]

--     if fiber.tag == HostComponent and isHiddenSubtree(fiber))
--       continue
--     } else {
--       while (selector ~= nil and matchSelector(fiber, selector))
--         selectorIndex++
--         selector = selectors[selectorIndex]
--       }
--     }

--     if selectorIndex == selectors.length)
--       return true
--     } else {
--       local child = fiber.child
--       while (child ~= nil)
--         stack.push(child, selectorIndex)
--         child = child.sibling
--       }
--     }
--   }

--   return false
-- end

-- exports.findAllNodes(
--   hostRoot: Instance,
--   selectors: Array<Selector>,
-- ): Array<Instance> {
--   if !supportsTestSelectors)
--     invariant(false, 'Test selector API is not supported by this renderer.')
--   }

--   local root = findFiberRootForHostRoot(hostRoot)
--   local matchingFibers = findPaths(root, selectors)

--   local instanceRoots: Array<Instance> = []

--   local stack = Array.from(matchingFibers)
--   local index = 0
--   while (index < stack.length)
--     local node = ((stack[index++]: any): Fiber)
--     if node.tag == HostComponent)
--       if isHiddenSubtree(node))
--         continue
--       }
--       instanceRoots.push(node.stateNode)
--     } else {
--       local child = node.child
--       while (child ~= nil)
--         stack.push(child)
--         child = child.sibling
--       }
--     }
--   }

--   return instanceRoots
-- end

-- exports.getFindAllNodesFailureDescription(
--   hostRoot: Instance,
--   selectors: Array<Selector>,
-- ): string | nil {
--   if !supportsTestSelectors)
--     invariant(false, 'Test selector API is not supported by this renderer.')
--   }

--   local root = findFiberRootForHostRoot(hostRoot)

--   local maxSelectorIndex: number = 0
--   local matchedNames = []

--   -- The logic of this loop should be kept in sync with findPaths()
--   local stack = [root, 0]
--   local index = 0
--   while (index < stack.length)
--     local fiber = ((stack[index++]: any): Fiber)
--     local selectorIndex = ((stack[index++]: any): number)
--     local selector = selectors[selectorIndex]

--     if fiber.tag == HostComponent and isHiddenSubtree(fiber))
--       continue
--     } else if matchSelector(fiber, selector))
--       matchedNames.push(selectorToString(selector))
--       selectorIndex++

--       if selectorIndex > maxSelectorIndex)
--         maxSelectorIndex = selectorIndex
--       }
--     }

--     if selectorIndex < selectors.length)
--       local child = fiber.child
--       while (child ~= nil)
--         stack.push(child, selectorIndex)
--         child = child.sibling
--       }
--     }
--   }

--   if maxSelectorIndex < selectors.length)
--     local unmatchedNames = []
--     for (local i = maxSelectorIndex; i < selectors.length; i++)
--       unmatchedNames.push(selectorToString(selectors[i]))
--     }

--     return (
--       'findAllNodes was able to match part of the selector:\n' +
--       `  ${matchedNames.join(' > ')}\n\n` +
--       'No matching component was found for:\n' +
--       `  ${unmatchedNames.join(' > ')}`
--     )
--   }

--   return nil
-- end

export type BoundingRect = {
	x: number,
	y: number,
	width: number,
	height: number,
}

-- exports.findBoundingRects(
--   hostRoot: Instance,
--   selectors: Array<Selector>,
-- ): Array<BoundingRect> {
--   if !supportsTestSelectors)
--     invariant(false, 'Test selector API is not supported by this renderer.')
--   }

--   local instanceRoots = findAllNodes(hostRoot, selectors)

--   local boundingRects: Array<BoundingRect> = []
--   for (local i = 0; i < instanceRoots.length; i++)
--     boundingRects.push(getBoundingRect(instanceRoots[i]))
--   }

--   for (local i = boundingRects.length - 1; i > 0; i--)
--     local targetRect = boundingRects[i]
--     local targetLeft = targetRect.x
--     local targetRight = targetLeft + targetRect.width
--     local targetTop = targetRect.y
--     local targetBottom = targetTop + targetRect.height

--     for (local j = i - 1; j >= 0; j--)
--       if i ~= j)
--         local otherRect = boundingRects[j]
--         local otherLeft = otherRect.x
--         local otherRight = otherLeft + otherRect.width
--         local otherTop = otherRect.y
--         local otherBottom = otherTop + otherRect.height

--         -- Merging all rects to the minimums set would be complicated,
--         -- but we can handle the most common cases:
--         -- 1. completely overlapping rects
--         -- 2. adjacent rects that are the same width or height (e.g. items in a list)
--         --
--         -- Even given the above constraints,
--         -- we still won't end up with the fewest possible rects without doing multiple passes,
--         -- but it's good enough for this purpose.

--         if
--           targetLeft >= otherLeft and
--           targetTop >= otherTop and
--           targetRight <= otherRight and
--           targetBottom <= otherBottom
--         )
--           -- Complete overlapping rects; remove the inner one.
--           boundingRects.splice(i, 1)
--           break
--         } else if
--           targetLeft == otherLeft and
--           targetRect.width == otherRect.width and
--           !(otherBottom < targetTop) and
--           !(otherTop > targetBottom)
--         )
--           -- Adjacent vertical rects; merge them.
--           if otherTop > targetTop)
--             otherRect.height += otherTop - targetTop
--             otherRect.y = targetTop
--           }
--           if otherBottom < targetBottom)
--             otherRect.height = targetBottom - otherTop
--           }

--           boundingRects.splice(i, 1)
--           break
--         } else if
--           targetTop == otherTop and
--           targetRect.height == otherRect.height and
--           !(otherRight < targetLeft) and
--           !(otherLeft > targetRight)
--         )
--           -- Adjacent horizontal rects; merge them.
--           if otherLeft > targetLeft)
--             otherRect.width += otherLeft - targetLeft
--             otherRect.x = targetLeft
--           }
--           if otherRight < targetRight)
--             otherRect.width = targetRight - otherLeft
--           }

--           boundingRects.splice(i, 1)
--           break
--         }
--       }
--     }
--   }

--   return boundingRects
-- end

-- exports.focusWithin(
--   hostRoot: Instance,
--   selectors: Array<Selector>,
-- ): boolean {
--   if !supportsTestSelectors)
--     invariant(false, 'Test selector API is not supported by this renderer.')
--   }

--   local root = findFiberRootForHostRoot(hostRoot)
--   local matchingFibers = findPaths(root, selectors)

--   local stack = Array.from(matchingFibers)
--   local index = 0
--   while (index < stack.length)
--     local fiber = ((stack[index++]: any): Fiber)
--     if isHiddenSubtree(fiber))
--       continue
--     }
--     if fiber.tag == HostComponent)
--       local node = fiber.stateNode
--       if setFocusIfFocusable(node))
--         return true
--       }
--     }
--     local child = fiber.child
--     while (child ~= nil)
--       stack.push(child)
--       child = child.sibling
--     }
--   }

--   return false
-- end

local commitHooks: Array<Function> = {}

exports.onCommitRoot = function(): ()
	if supportsTestSelectors then
		for i, commitHook in commitHooks do
			commitHook()
		end
	end
end

export type IntersectionObserverOptions = Object

export type ObserveVisibleRectsCallback = (
	intersections: Array<{ ratio: number, rect: BoundingRect }>
) -> ()

-- exports.observeVisibleRects(
--   hostRoot: Instance,
--   selectors: Array<Selector>,
--   callback: (intersections: Array<{ratio: number, rect: BoundingRect}>) => void,
--   options?: IntersectionObserverOptions,
-- ): {|disconnect: () => void|} {
--   if !supportsTestSelectors)
--     invariant(false, 'Test selector API is not supported by this renderer.')
--   }

--   local instanceRoots = findAllNodes(hostRoot, selectors)

--   local {disconnect, observe, unobserve} = setupIntersectionObserver(
--     instanceRoots,
--     callback,
--     options,
--   )

--   -- When React mutates the host environment, we may need to change what we're listening to.
--   local commitHook = () => {
--     local nextInstanceRoots = findAllNodes(hostRoot, selectors)

--     instanceRoots.forEach(target => {
--       if nextInstanceRoots.indexOf(target) < 0)
--         unobserve(target)
--       }
--     })

--     nextInstanceRoots.forEach(target => {
--       if instanceRoots.indexOf(target) < 0)
--         observe(target)
--       }
--     })
--   }

--   commitHooks.push(commitHook)

--   return {
--     disconnect: () => {
--       -- Stop listening for React mutations:
--       local index = commitHooks.indexOf(commitHook)
--       if index >= 0)
--         commitHooks.splice(index, 1)
--       }

--       -- Disconnect the host observer:
--       disconnect()
--     },
--   }
-- end

return exports
