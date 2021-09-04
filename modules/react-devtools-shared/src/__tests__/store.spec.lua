-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/__tests__/store-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]

local fill = function(count, value)
	local output = {}
	for i = 1, count do
		output[i] = value
	end
	return output
end

return function()
	local Packages = script.Parent.Parent.Parent
	local jestModule = require(Packages.Dev.JestRoblox)
	local jestExpect = jestModule.Globals.expect

	local Promise = require(Packages.Dev.Promise)
	local LuauPolyfill = require(Packages.LuauPolyfill)
	local Array = LuauPolyfill.Array
	local Object = LuauPolyfill.Object

	local global = _G
	type Array<T> = { [number]: T }

	local RobloxJest = require(Packages.Dev.RobloxJest)
	local ReactRoblox
	local React
	-- ROBLOX deviation: bring in the Agent type
	local Agent = require(script.Parent.Parent.backend.agent)
	type Agent = Agent.Agent

	describe("Store", function()
		local agent: Agent
		local act
		local getRendererID
		local store
		local devtoolsUtils
		local constants

		beforeEach(function(context)
			agent = global.agent
			store = global.store

			React = require(Packages.React)
			RobloxJest.resetModules()
			ReactRoblox = require(Packages.ReactRoblox)
			devtoolsUtils = require(script.Parent.Parent.devtools.utils)
			constants = require(script.Parent.Parent.constants)

			local utils = require(script.Parent.utils)
			act = utils.act
			getRendererID = utils.getRendererID
		end)

		it("should not allow a root node to be collapsed", function()
			local function Component()
				return React.createElement("div", nil, "Hi")
			end

			-- ROBLOX deviation: use root:render to render instead of ReactDOM.render
			act(function()
				local root = ReactRoblox.createRoot(Instance.new("Frame"))
				root:render(React.createElement(Component, {
					count = 4,
				}))
			end)

			jestExpect(devtoolsUtils.printStore(store)).toBe([[
[root]
    <Component>]])
			jestExpect(store:getRoots()).toHaveLength(1)

			local rootID = store:getRoots()[1]

			jestExpect(function()
				return store:toggleIsCollapsed(rootID, true)
			end).toThrow("Root nodes cannot be collapsed")
		end)
		it("should properly handle a root with no visible nodes", function()
			local function Root(props)
				return props.children
			end
			-- ROBLOX deviation: use root:render instead of ReactDOM.render
			local root = ReactRoblox.createRoot(Instance.new("Frame"))
			act(function()
				root:render(React.createElement(Root, {}, {}))
			end)

			jestExpect(devtoolsUtils.printStore(store)).toBe([[
[root]
    <Root>]])
			act(function()
				root:render(React.createElement("div"))
			end)
			jestExpect(devtoolsUtils.printStore(store)).toBe("[root]")
		end)
		describe("collapseNodesByDefault:false", function()
			beforeEach(function()
				store:setCollapseNodesByDefault(false)
			end)
			it("should support mount and update operations", function()
				constants.__DEBUG__ = true
				local function Child()
					return React.createElement("div", nil, "Hi!")
				end
				local function Parent(props)
					local count = props.count
					return Array.map(fill(count, true), function(_, index)
						return React.createElement(Child, { key = index })
					end)
				end
				-- ROBLOX deviation: switched ordering for variable definition order
				local function Grandparent(props)
					local count = props.count
					return React.createElement(React.Fragment, nil, {
						React.createElement(Parent, { count = count }),
						React.createElement(Parent, { count = count }),
					})
				end

				-- ROBLOX deviation: Use Frame instance rather than DOM element
				local root = ReactRoblox.createRoot(Instance.new("Frame"))
				act(function()
					return root:render(React.createElement(Grandparent, { count = 4 }))
				end)
				-- ROBLOX deviation: we must key children implicitly due to the Roblox DOM being unordered
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Grandparent>
    ▾ <Parent key="1">
        <Child key="1">
        <Child key="2">
        <Child key="3">
        <Child key="4">
    ▾ <Parent key="2">
        <Child key="1">
        <Child key="2">
        <Child key="3">
        <Child key="4">]])
				act(function()
					return root:render(React.createElement(Grandparent, { count = 2 }))
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Grandparent>
    ▾ <Parent key="1">
        <Child key="1">
        <Child key="2">
    ▾ <Parent key="2">
        <Child key="1">
        <Child key="2">]])
				-- ROBLOX FIXME: unmountComponentAtNode not implemented in react-roblox renderer
				-- act(function()
				-- 	return root:unmountComponentAtNode()
				-- end)
				-- jestExpect(devtoolsUtils.printStore(store)).toBe("")
			end)
			-- ROBLOX FIXME: currently doesn't print the rootA contents, only rootB contents
			xit(
				"should support mount and update operations for multiple roots",
				function()
					local function Child()
						return React.createElement("div", nil, "Hi!")
					end
					local function Parent(props)
						local count = props.count
						return Array.map(fill(count, true), function(_, index)
							return React.createElement(Child, { key = index })
						end)
					end

					local rootA = ReactRoblox.createBlockingRoot(Instance.new("Frame"))
					local rootB = ReactRoblox.createBlockingRoot(Instance.new("Frame"))

					act(function()
						rootA:render(React.createElement(Parent, {
							key = "A",
							count = 3,
						}))
						rootB:render(React.createElement(Parent, {
							key = "B",
							count = 2,
						}))
					end)
					jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Parent key="A">
      <Child key="1">
      <Child key="2">
      <Child key="3">
[root]
  ▾ <Parent key="B">
      <Child key="1">
      <Child key="2">]])
					act(function()
						rootA:render(React.createElement(Parent, {
							key = "A",
							count = 4,
						}))
						rootB:render(React.createElement(Parent, {
							key = "B",
							count = 1,
						}))
					end)
					jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Parent key="A">
      <Child key="1">
      <Child key="2">
      <Child key="3">
      <Child key="4">
[root]
  ▾ <Parent key="B">
      <Child key="1">]])
					-- ROBLOX deviation: unmountComponentAtNode not implemented
					-- act(function()
					-- 	return ReactRoblox.unmountComponentAtNode(containerB)
					-- end)
					--[==[jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Parent key="A">
      <Child key="1">
      <Child key="2">
      <Child key="3">
      <Child key="4">]])
]==]
					-- act(function()
					-- 	return ReactRoblox.unmountComponentAtNode(containerA)
					-- end)
					-- jestExpect(devtoolsUtils.printStore(store)).toBe("")
				end
			)
			it("should filter DOM nodes from the store tree", function()
				local function Child()
					return React.createElement("div", nil, "Hi!")
				end
				local function Parent()
					return React.createElement("div", nil, React.createElement(Child))
				end
				local function Grandparent()
					return React.createElement(
						"div",
						nil,
						React.createElement("div", nil, React.createElement(Parent)),
						React.createElement(Parent)
					)
				end

				local root = ReactRoblox.createRoot(Instance.new("Frame"))

				act(function()
					return root:render(
						React.createElement(Grandparent, { count = 4 }),
						Instance.new("Frame")
					)
				end)
				-- ROBLOX deviation: we must key children implicitly due to the Roblox DOM being unordered
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Grandparent>
    ▾ <Parent>
        <Child>
    ▾ <Parent key="2">
        <Child>]])
			end)
			-- ROBLOX FIXME: Unskip when unhideInstance is implemented in react-roblox renderer
			xit("should display Suspense nodes properly in various states", function()
				local function Loading()
					return React.createElement("div", nil, "Loading...")
				end
				local function SuspendingComponent()
					error(Promise.new(function() end))
				end
				local function Component()
					return React.createElement("div", nil, "Hello")
				end
				local function Wrapper(props)
					local shouldSuspense = props.shouldSuspense

					return React.createElement(
						React.Fragment,
						nil,
						React.createElement(Component, {
							key = "Outside",
						}),
						React.createElement(
							React.Suspense,
							{
								fallback = React.createElement(Loading),
							},
							(function()
								if shouldSuspense then
									return React.createElement(SuspendingComponent)
								end

								return React.createElement(Component, {
									key = "Inside",
								})
							end)()
						)
					)
				end
				-- ROBLOX deviation: Use Frame instance rather than DOM element
				local root = ReactRoblox.createRoot(Instance.new("Frame"))
				act(function()
					return root:render(
						React.createElement(Wrapper, { shouldSuspense = true })
					)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Wrapper>
      <Component key="Outside">
    ▾ <Suspense>
        <Loading>]])
				act(function()
					-- ROBLOX FIXME: unsupported unhideInstance is triggered by this line
					root:render(React.createElement(Wrapper, { shouldSuspense = false }))
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Wrapper>
      <Component key="Outside">
    ▾ <Suspense>
        <Component key="Inside">]])
			end)
			-- ROBLOX FIXME: store:886: Cannot remove node nil because no matching node was found in the Store.
			xit("should support nested Suspense nodes", function()
				local function Component()
					return nil
				end
				local function Loading()
					return React.createElement("div", nil, "Loading...")
				end
				local Never = function()
					error(Promise.new(function() end))
				end
				local function Wrapper(props)
					local suspendFirst = props.suspendFirst or false
					local suspendSecond = props.suspendSecond or false
					local suspendParent = props.suspendParent or false

					return React.createElement(
						React.Fragment,
						nil,
						React.createElement(Component, {
							key = "Outside",
						}),
						React.createElement(
							React.Suspense,
							{
								fallback = React.createElement(Loading, {
									key = "Parent Fallback",
								}),
							},
							React.createElement(Component, {
								key = "Unrelated at Start",
							}),
							React.createElement(
								React.Suspense,
								{
									fallback = React.createElement(Loading, {
										key = "Suspense 1 Fallback",
									}),
								},
								(function()
									if suspendFirst then
										return React.createElement(Never)
									end

									return React.createElement(Component, {
										key = "Suspense 1 Content",
									})
								end)()
							),
							React.createElement(
								React.Suspense,
								{
									fallback = React.createElement(Loading, {
										key = "Suspense 2 Fallback",
									}),
								},
								(function()
									if suspendSecond then
										return React.createElement(Never)
									end

									return React.createElement(Component, {
										key = "Suspense 2 Content",
									})
								end)()
							),
							React.createElement(React.Suspense, {
								fallback = React.createElement(Loading, {
									key = "Suspense 3 Fallback",
								}),
							}, React.createElement(
								Never
							)),
							(function()
								if suspendParent then
									return React.createElement(Never)
								end
								return nil
							end)(),
							React.createElement(Component, {
								key = "Unrelated at End",
							})
						)
					)
				end
				-- ROBLOX deviation: Use createRoot instead of DOM
				local root = ReactRoblox.createRoot(Instance.new("Frame"))

				act(function()
					return root:render(React.createElement(Wrapper, {
						suspendParent = false,
						suspendFirst = false,
						suspendSecond = false,
					}))
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Wrapper>
      <Component key="Outside">
    ▾ <Suspense>
        <Component key="Unrelated at Start">
      ▾ <Suspense>
          <Component key="Suspense 1 Content">
      ▾ <Suspense>
          <Component key="Suspense 2 Content">
      ▾ <Suspense>
          <Loading key="Suspense 3 Fallback">
        <Component key="Unrelated at End">]])
				-- ROBLOX FIXME: error triggered in this act: store:886: Cannot remove node nil because no matching node was found in the Store.
				act(function()
					return root:render(React.createElement(Wrapper, {
						suspendParent = false,
						suspendFirst = true,
						suspendSecond = false,
					}))
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Wrapper>
      <Component key="Outside">
    ▾ <Suspense>
        <Component key="Unrelated at Start">
      ▾ <Suspense>
          <Loading key="Suspense 1 Fallback">
      ▾ <Suspense>
          <Component key="Suspense 2 Content">
      ▾ <Suspense>
          <Loading key="Suspense 3 Fallback">
        <Component key="Unrelated at End">]])
				act(function()
					return root:render(React.createElement(Wrapper, {
						suspendParent = false,
						suspendFirst = false,
						suspendSecond = true,
					}))
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Wrapper>
      <Component key="Outside">
    ▾ <Suspense>
        <Component key="Unrelated at Start">
      ▾ <Suspense>
          <Component key="Suspense 1 Content">
      ▾ <Suspense>
          <Loading key="Suspense 2 Fallback">
      ▾ <Suspense>
          <Loading key="Suspense 3 Fallback">
        <Component key="Unrelated at End">]])
				act(function()
					return root:render(React.createElement(Wrapper, {
						suspendParent = false,
						suspendFirst = true,
						suspendSecond = false,
					}))
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Wrapper>
      <Component key="Outside">
    ▾ <Suspense>
        <Component key="Unrelated at Start">
      ▾ <Suspense>
          <Loading key="Suspense 1 Fallback">
      ▾ <Suspense>
          <Component key="Suspense 2 Content">
      ▾ <Suspense>
          <Loading key="Suspense 3 Fallback">
        <Component key="Unrelated at End">]])
				act(function()
					return root:render(React.createElement(Wrapper, {
						suspendParent = true,
						suspendFirst = true,
						suspendSecond = false,
					}))
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Wrapper>
      <Component key="Outside">
    ▾ <Suspense>
        <Loading key="Parent Fallback">]])
				act(function()
					return root:render(React.createElement(Wrapper, {
						suspendParent = false,
						suspendFirst = true,
						suspendSecond = true,
					}))
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Wrapper>
      <Component key="Outside">
    ▾ <Suspense>
        <Component key="Unrelated at Start">
      ▾ <Suspense>
          <Loading key="Suspense 1 Fallback">
      ▾ <Suspense>
          <Loading key="Suspense 2 Fallback">
      ▾ <Suspense>
          <Loading key="Suspense 3 Fallback">
        <Component key="Unrelated at End">]])
				act(function()
					return root:render(React.createElement(Wrapper, {
						suspendParent = false,
						suspendFirst = false,
						suspendSecond = false,
					}))
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Wrapper>
      <Component key="Outside">
    ▾ <Suspense>
        <Component key="Unrelated at Start">
      ▾ <Suspense>
          <Component key="Suspense 1 Content">
      ▾ <Suspense>
          <Component key="Suspense 2 Content">
      ▾ <Suspense>
          <Loading key="Suspense 3 Fallback">
        <Component key="Unrelated at End">]])

				local rendererID = getRendererID()

				act(function()
					return agent:overrideSuspense({
						id = store:getElementIDAtIndex(4),
						rendererID = rendererID,
						forceFallback = true,
					})
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Wrapper>
      <Component key="Outside">
    ▾ <Suspense>
        <Component key="Unrelated at Start">
      ▾ <Suspense>
          <Loading key="Suspense 1 Fallback">
      ▾ <Suspense>
          <Component key="Suspense 2 Content">
      ▾ <Suspense>
          <Loading key="Suspense 3 Fallback">
        <Component key="Unrelated at End">]])
				act(function()
					return agent:overrideSuspense({
						id = store:getElementIDAtIndex(2),
						rendererID = rendererID,
						forceFallback = true,
					})
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Wrapper>
      <Component key="Outside">
    ▾ <Suspense>
        <Loading key="Parent Fallback">]])
				act(function()
					return root:render(React.createElement(Wrapper, {
						suspendParent = false,
						suspendFirst = true,
						suspendSecond = true,
					}))
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Wrapper>
      <Component key="Outside">
    ▾ <Suspense>
        <Loading key="Parent Fallback">]])
				act(function()
					return agent:overrideSuspense({
						id = store:getElementIDAtIndex(2),
						rendererID = rendererID,
						forceFallback = false,
					})
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Wrapper>
      <Component key="Outside">
    ▾ <Suspense>
        <Component key="Unrelated at Start">
      ▾ <Suspense>
          <Loading key="Suspense 1 Fallback">
      ▾ <Suspense>
          <Loading key="Suspense 2 Fallback">
      ▾ <Suspense>
          <Loading key="Suspense 3 Fallback">
        <Component key="Unrelated at End">]])
				act(function()
					return agent:overrideSuspense({
						id = store:getElementIDAtIndex(4),
						rendererID = rendererID,
						forceFallback = false,
					})
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Wrapper>
      <Component key="Outside">
    ▾ <Suspense>
        <Component key="Unrelated at Start">
      ▾ <Suspense>
          <Loading key="Suspense 1 Fallback">
      ▾ <Suspense>
          <Loading key="Suspense 2 Fallback">
      ▾ <Suspense>
          <Loading key="Suspense 3 Fallback">
        <Component key="Unrelated at End">]])
				act(function()
					return root:render(React.createElement(Wrapper, {
						suspendParent = false,
						suspendFirst = false,
						suspendSecond = false,
					}))
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Wrapper>
      <Component key="Outside">
    ▾ <Suspense>
        <Component key="Unrelated at Start">
      ▾ <Suspense>
          <Component key="Suspense 1 Content">
      ▾ <Suspense>
          <Component key="Suspense 2 Content">
      ▾ <Suspense>
          <Loading key="Suspense 3 Fallback">
        <Component key="Unrelated at End">]])
			end)
			-- ROBLOX TODO: re-enable when unstable_SuspenseList is implemented
			xit("should display a partially rendered SuspenseList", function()
				local function Loading()
					return React.createElement("div", nil, "Loading...")
				end
				local function SuspendingComponent()
					error(Promise.new(function() end))
				end
				local function Component()
					return React.createElement("div", nil, "Hello")
				end
				local function Wrapper(_ref7)
					local shouldSuspense = _ref7.shouldSuspense

					return React.createElement(
						React.Fragment,
						nil,
						React.createElement(
							React.unstable_SuspenseList,
							{
								revealOrder = "forwards",
								tail = "collapsed",
							},
							React.createElement(Component, {
								key = "A",
							}),
							React.createElement(
								React.Suspense,
								{
									fallback = React.createElement(Loading),
								},
								(function()
									if shouldSuspense then
										return React.createElement(SuspendingComponent)
									end

									return React.createElement(Component, {
										key = "B",
									})
								end)()
							),
							React.createElement(Component, {
								key = "C",
							})
						)
					)
				end
				-- ROBLOX deviation: Use Frame instance rather than DOM element
				local container = Instance.new("Frame")
				local root = ReactRoblox.unstable_createRoot(container)

				act(function()
					root:render(React.createElement(Wrapper, { shouldSuspense = true }))
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe("1: loading")
				act(function()
					root:render(React.createElement(Wrapper, { shouldSuspense = false }))
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe("2: resolved")
			end)
			it("should support collapsing parts of the tree", function()
				-- ROBLOX deviation: switched ordering for variable definition order
				local function Child()
					return React.createElement("div", nil, "Hi!")
				end
				local function Parent(props)
					local count = props.count
					return Array.map(fill(count, true), function(_, index)
						return React.createElement(Child, { key = index })
					end)
				end
				local function Grandparent(props)
					local count = props.count

					return React.createElement(
						React.Fragment,
						nil,
						React.createElement(Parent, { count = count }),
						React.createElement(Parent, { count = count })
					)
				end

				local root = ReactRoblox.createRoot(Instance.new("Frame"))

				act(function()
					return root:render(
						React.createElement(Grandparent, { count = 2 }),
						Instance.new("Frame")
					)
				end)
				-- ROBLOX deviation: we must key children implicitly due to the Roblox DOM being unordered
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Grandparent>
    ▾ <Parent key="1">
        <Child key="1">
        <Child key="2">
    ▾ <Parent key="2">
        <Child key="1">
        <Child key="2">]])

				local grandparentID = store:getElementIDAtIndex(0)
				local parentOneID = store:getElementIDAtIndex(1)
				local parentTwoID = store:getElementIDAtIndex(4)

				act(function()
					return store:toggleIsCollapsed(parentOneID, true)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Grandparent>
    ▸ <Parent key="1">
    ▾ <Parent key="2">
        <Child key="1">
        <Child key="2">]])
				act(function()
					return store:toggleIsCollapsed(parentTwoID, true)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Grandparent>
    ▸ <Parent key="1">
    ▸ <Parent key="2">]])
				act(function()
					return store:toggleIsCollapsed(parentOneID, false)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Grandparent>
    ▾ <Parent key="1">
        <Child key="1">
        <Child key="2">
    ▸ <Parent key="2">]])
				act(function()
					return store:toggleIsCollapsed(grandparentID, true)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▸ <Grandparent>]])
				act(function()
					return store:toggleIsCollapsed(grandparentID, false)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Grandparent>
    ▾ <Parent key="1">
        <Child key="1">
        <Child key="2">
    ▸ <Parent key="2">]])
			end)
			it("should support reordering of children", function()
				local function Root(props)
					return props.children
				end
				local function Component()
					return nil
				end
				local function Foo()
					return {
						React.createElement(Component, {
							key = "0",
						}),
					}
				end
				local function Bar()
					return {
						React.createElement(Component, {
							key = "0",
						}),
						React.createElement(Component, {
							key = "1",
						}),
					}
				end
				local foo = React.createElement(Foo, {
					key = "foo",
				})
				local bar = React.createElement(Bar, {
					key = "bar",
				})
				-- ROBLOX deviation: Use createRoot instead of DOM
				local root = ReactRoblox.createRoot(Instance.new("Frame"))

				act(function()
					return root:render(React.createElement(Root, nil, { foo, bar }))
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Root>
    ▾ <Foo key="foo">
        <Component key="0">
    ▾ <Bar key="bar">
        <Component key="0">
        <Component key="1">]])
				act(function()
					return root:render(React.createElement(Root, nil, { bar, foo }))
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Root>
    ▾ <Bar key="bar">
        <Component key="0">
        <Component key="1">
    ▾ <Foo key="foo">
        <Component key="0">]])
				act(function()
					return store:toggleIsCollapsed(store:getElementIDAtIndex(0), true)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▸ <Root>]])
				act(function()
					return store:toggleIsCollapsed(store:getElementIDAtIndex(0), false)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Root>
    ▾ <Bar key="bar">
        <Component key="0">
        <Component key="1">
    ▾ <Foo key="foo">
        <Component key="0">]])
			end)
		end)
		describe("collapseNodesByDefault:true", function()
			beforeEach(function()
				store:setCollapseNodesByDefault(true)
			end)
			it("should support mount and update operations", function()
				local function Child()
					return React.createElement("div", nil, "Hi!")
				end
				local function Parent(props)
					local count = props.count
					return Array.map(fill(count, true), function(_, index)
						return React.createElement(Child, { key = index })
					end)
				end
				-- ROBLOX deviation: Use Frame instance rather than DOM element
				local root = ReactRoblox.createRoot(Instance.new("Frame"))

				act(function()
					return root:render(
						React.createElement(
							React.Fragment,
							nil,
							React.createElement(Parent, { count = 1 }),
							React.createElement(Parent, { count = 3 })
						)
					)
				end)
				-- ROBLOX deviation: we must key children implicitly due to the Roblox DOM being unordered
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▸ <Parent key="1">
  ▸ <Parent key="2">]])
				act(function()
					return root:render(
						React.createElement(
							React.Fragment,
							nil,
							React.createElement(Parent, { count = 2 }),
							React.createElement(Parent, { count = 1 })
						)
					)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▸ <Parent key="1">
  ▸ <Parent key="2">]])
				-- ROBLOX deviation: unmountComponentAtNode not implemented
				-- act(function()
				-- return ReactRoblox.unmountComponentAtNode(container)
				-- end)
				-- jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
				--   ▸ <Root>]])
			end)
			-- ROBLOX TODO: Tests using multiple roots don't currently work, because rootA and rootB
			-- do not use the SyncLane which is checked in ReactFiberWorkLoop:680 upstream which proceeds
			-- to call handleCommitFiberRoot in devtools renderer.lua for the two separate roots.
			--  The upstream tests use a blocking root, which has a different path through the React
			-- codebase. Using concurrent roots, rootB is placed in lane 512 (rather than 1)
			-- Using blocking roots, rootB is placed in lane 2 (rather than 1) so is not registered.
			xit(
				"should support mount and update operations for multiple roots",
				function()
					-- ROBLOX deviation: switched ordering for variable definition order
					local function Child()
						return React.createElement("div", nil, "Hi!")
					end
					local function Parent(props)
						local count = props.count
						return Array.map(fill(count, true), function(_, index)
							return React.createElement(Child, { key = index })
						end)
					end
					local rootA = ReactRoblox.createRoot(Instance.new("Frame"))
					local rootB = ReactRoblox.createRoot(Instance.new("Frame"))

					act(function()
						rootA:render(
							React.createElement(Parent, {
								key = "A",
								count = 3,
							}),
							rootA
						)
						rootB:render(
							React.createElement(Parent, {
								key = "B",
								count = 2,
							}),
							rootB
						)
					end)
					jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▸ <Parent key="A">
[root]
  ▸ <Parent key="B">]])
					act(function()
						rootA:render(
							React.createElement(Parent, {
								key = "A",
								count = 4,
							}),
							rootA
						)
						rootB:render(
							React.createElement(Parent, {
								key = "B",
								count = 1,
							}),
							rootB
						)
					end)
					jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▸ <Parent key="A">
[root]
  ▸ <Parent key="B">]])
					act(function()
						return ReactRoblox.unmountComponentAtNode(rootB)
					end)
					jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▸ <Parent key="A">]])
					act(function()
						return ReactRoblox.unmountComponentAtNode(rootA)
					end)
					jestExpect(devtoolsUtils.printStore(store)).toBe("")
				end
			)
			it("should filter DOM nodes from the store tree", function()
				local function Child()
					return React.createElement("div", nil, "Hi!")
				end
				local function Parent()
					return React.createElement("div", nil, React.createElement(Child))
				end
				local function Grandparent()
					return React.createElement(
						"div",
						nil,
						React.createElement("div", nil, React.createElement(Parent)),
						React.createElement(Parent)
					)
				end

				local root = ReactRoblox.createRoot(Instance.new("Frame"))

				act(function()
					return root:render(
						React.createElement(Grandparent, { count = 4 }),
						Instance.new("Frame")
					)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▸ <Grandparent>]])
				act(function()
					return store:toggleIsCollapsed(store:getElementIDAtIndex(0), false)
				end)
				-- ROBLOX deviation: we must key children implicitly due to the Roblox DOM being unordered
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Grandparent>
    ▸ <Parent>
    ▸ <Parent key="2">]])
				act(function()
					return store:toggleIsCollapsed(store:getElementIDAtIndex(1), false)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Grandparent>
    ▾ <Parent>
        <Child>
    ▸ <Parent key="2">]])
			end)
			-- ROBLOX FIXME: incorrect value in the store
			xit("should display Suspense nodes properly in various states", function()
				local function Loading()
					return React.createElement("div", nil, "Loading...")
				end
				local function SuspendingComponent()
					error(Promise.new(function() end))
				end
				local function Component()
					return React.createElement("div", nil, "Hello")
				end
				local function Wrapper(props)
					local shouldSuspense = props.shouldSuspense

					return React.createElement(
						React.Fragment,
						nil,
						React.createElement(Component, {
							key = "Outside",
						}),
						React.createElement(
							React.Suspense,
							{
								fallback = React.createElement(Loading),
							},
							(function()
								if shouldSuspense then
									return React.createElement(SuspendingComponent)
								end

								return React.createElement(Component, {
									key = "Inside",
								})
							end)()
						)
					)
				end
				local root = ReactRoblox.createRoot(Instance.new("Frame"))

				act(function()
					return root:render(
						React.createElement(Wrapper, { shouldSuspense = true })
					)
				end)
				-- ROBLOX FIXME: this results in incorrect string "[root]"
				jestExpect(devtoolsUtils.printStore(store)).toBe("1: loading")
				act(function()
					return store:toggleIsCollapsed(store:getElementIDAtIndex(0), false)
				end)
				act(function()
					return store:toggleIsCollapsed(store:getElementIDAtIndex(2), false)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe(
					"2: expand Wrapper and Suspense"
				)
				act(function()
					root:render(React.createElement(Wrapper, { shouldSuspense = false }))
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe("2: resolved")
			end)
			it("should support expanding parts of the tree", function()
				local function Child()
					return React.createElement("div", nil, "Hi!")
				end
				local function Parent(props)
					local count = props.count
					return Array.map(fill(count, true), function(_, index)
						return React.createElement(Child, { key = index })
					end)
				end
				local function Grandparent(props)
					local count = props.count
					return React.createElement(
						React.Fragment,
						nil,
						React.createElement(Parent, { count = count }),
						React.createElement(Parent, { count = count })
					)
				end

				local root = ReactRoblox.createRoot(Instance.new("Frame"))

				act(function()
					return root:render(
						React.createElement(Grandparent, { count = 2 }),
						Instance.new("Frame")
					)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▸ <Grandparent>]])

				local grandparentID = store:getElementIDAtIndex(0)

				act(function()
					return store:toggleIsCollapsed(grandparentID, false)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Grandparent>
    ▸ <Parent key="1">
    ▸ <Parent key="2">]])

				local parentOneID = store:getElementIDAtIndex(1)
				local parentTwoID = store:getElementIDAtIndex(2)

				act(function()
					return store:toggleIsCollapsed(parentOneID, false)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Grandparent>
    ▾ <Parent key="1">
        <Child key="1">
        <Child key="2">
    ▸ <Parent key="2">]])
				act(function()
					return store:toggleIsCollapsed(parentTwoID, false)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Grandparent>
    ▾ <Parent key="1">
        <Child key="1">
        <Child key="2">
    ▾ <Parent key="2">
        <Child key="1">
        <Child key="2">]])
				act(function()
					return store:toggleIsCollapsed(parentOneID, true)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Grandparent>
    ▸ <Parent key="1">
    ▾ <Parent key="2">
        <Child key="1">
        <Child key="2">]])
				act(function()
					return store:toggleIsCollapsed(parentTwoID, true)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Grandparent>
    ▸ <Parent key="1">
    ▸ <Parent key="2">]])
				act(function()
					return store:toggleIsCollapsed(grandparentID, true)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▸ <Grandparent>]])
			end)
			-- ROBLOX TODO: Support both ReactTestRenderer and ReactRoblox renderer as both renderers are needed
			-- in this test to getIDForNode to return correctly, as findFiberByHostInstance is only implemented
			-- in the ReactRoblox renderer. The next step to do this is implement ReactRoblox.act and uncomment
			-- actDOM in __tests__/utils.lua
			xit("should support expanding deep parts of the tree", function()
				local function Nested(props)
					local depth, forwardedRef = props.depth, props.forwardedRef

					return (function()
						if depth > 0 then
							return React.createElement(Nested, {
								depth = depth - 1,
								forwardedRef = forwardedRef,
							})
						end

						return React.createElement("div", { ref = forwardedRef })
					end)()
				end
				local function Wrapper(props)
					local forwardedRef = props.forwardedRef

					return React.createElement(Nested, {
						depth = 3,
						forwardedRef = forwardedRef,
					})
				end
				local ref = React.createRef()
				local root = ReactRoblox.createRoot(Instance.new("Frame"))

				act(function()
					return root:render(
						React.createElement(Wrapper, { forwardedRef = ref }),
						Instance.new("Frame")
					)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▸ <Wrapper>]])

				local deepestedNodeID = agent:getIDForNode(ref.current)

				-- ROBLOX FIXME: next line fails with: store:432: invalid argument #2 to 'format' (string expected, got nil)
				act(function()
					return store:toggleIsCollapsed(deepestedNodeID, false)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Wrapper>
    ▾ <Nested>
      ▾ <Nested>
        ▾ <Nested>
            <Nested>]])

				local rootID = store:getElementIDAtIndex(0)

				act(function()
					return store:toggleIsCollapsed(rootID, true)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▸ <Wrapper>]])
				act(function()
					return store:toggleIsCollapsed(rootID, false)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Wrapper>
    ▾ <Nested>
      ▾ <Nested>
        ▾ <Nested>
            <Nested>]])

				local id = store:getElementIDAtIndex(1)

				act(function()
					return store:toggleIsCollapsed(id, true)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Wrapper>
    ▸ <Nested>]])
				act(function()
					return store:toggleIsCollapsed(id, false)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Wrapper>
    ▾ <Nested>
      ▾ <Nested>
        ▾ <Nested>
            <Nested>]])
			end)
			it("should support reordering of children", function()
				local function Root(props)
					return props.children
				end
				local function Component()
					return nil
				end
				local function Foo()
					return {
						React.createElement(Component, {
							key = "0",
						}),
					}
				end
				local function Bar()
					return {
						React.createElement(Component, {
							key = "0",
						}),
						React.createElement(Component, {
							key = "1",
						}),
					}
				end
				local foo = React.createElement(Foo, {
					key = "foo",
				})
				local bar = React.createElement(Bar, {
					key = "bar",
				})
				local root = ReactRoblox.createRoot(Instance.new("Frame"))

				act(function()
					return root:render(React.createElement(Root, nil, { foo, bar }))
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▸ <Root>]])
				act(function()
					return root:render(React.createElement(Root, nil, { bar, foo }))
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▸ <Root>]])
				act(function()
					return store:toggleIsCollapsed(store:getElementIDAtIndex(0), false)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Root>
    ▸ <Bar key="bar">
    ▸ <Foo key="foo">]])
				act(function()
					store:toggleIsCollapsed(store:getElementIDAtIndex(2), false)
					store:toggleIsCollapsed(store:getElementIDAtIndex(1), false)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <Root>
    ▾ <Bar key="bar">
        <Component key="0">
        <Component key="1">
    ▾ <Foo key="foo">
        <Component key="0">]])
				act(function()
					return store:toggleIsCollapsed(store:getElementIDAtIndex(0), true)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▸ <Root>]])
			end)
			-- ROBLOX FIXME: fails with Parent instead of Fallback, possibly bug in agent:overrideSuspense
			xit("should not add new nodes when suspense is toggled", function()
				-- ROBLOX deviation: switched ordering for variable definition order
				local function Fallback()
					return nil
				end
				local function Child()
					return nil
				end
				local function Parent()
					return React.createElement(Child)
				end
				local function SuspenseTree()
					return React.createElement(React.Suspense, {
						fallback = React.createElement(Fallback, nil, "Loading outer"),
					}, React.createElement(
						Parent
					))
				end

				local root = ReactRoblox.createRoot(Instance.new("Frame"))

				act(function()
					return root:render(
						React.createElement(SuspenseTree),
						Instance.new("Frame")
					)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▸ <SuspenseTree>]])
				act(function()
					return store:toggleIsCollapsed(store:getElementIDAtIndex(0), false)
				end)
				act(function()
					return store:toggleIsCollapsed(store:getElementIDAtIndex(1), false)
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <SuspenseTree>
    ▾ <Suspense>
      ▸ <Parent>]])

				local rendererID = getRendererID()
				local suspenseID = store:getElementIDAtIndex(1)

				act(function()
					return agent:overrideSuspense({
						id = suspenseID,
						rendererID = rendererID,
						forceFallback = true,
					})
				end)
				-- ROBLOX FIXME: fails on the next line, gets Parent instead of Fallback
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <SuspenseTree>
    ▾ <Suspense>
        <Fallback>]])
				act(function()
					return agent:overrideSuspense({
						id = suspenseID,
						rendererID = rendererID,
						forceFallback = false,
					})
				end)
				jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
  ▾ <SuspenseTree>
    ▾ <Suspense>
      ▸ <Parent>]])
			end)
		end)
		describe("getIndexOfElementID", function()
			beforeEach(function()
				store.collapseNodesByDefault = false
			end)
			it("should support a single root with a single child", function()
				-- ROBLOX deviation: switched ordering for variable definition order
				local function Child()
					return nil
				end
				local function Parent()
					return React.createElement(Child)
				end
				local function Grandparent()
					return React.createElement(
						React.Fragment,
						nil,
						React.createElement(Parent),
						React.createElement(Parent)
					)
				end

				local root = ReactRoblox.createRoot(Instance.new("Frame"))

				act(function()
					return root:render(
						React.createElement(Grandparent),
						Instance.new("Frame")
					)
				end)

				for i = 0, store:getNumElements() - 1 do
					jestExpect(store:getIndexOfElementID(store:getElementIDAtIndex(i))).toBe(
						i
					)
				end
			end)
			it("should support multiple roots with one children each", function()
				-- ROBLOX deviation: switched ordering for variable definition order
				local function Child()
					return nil
				end
				local function Parent()
					return React.createElement(Child)
				end
				local function Grandparent()
					return React.createElement(Parent)
				end

				local root = ReactRoblox.createRoot(Instance.new("Frame"))

				act(function()
					root:render(React.createElement(Grandparent), Instance.new("Frame"))
				end)

				for i = 0, store:getNumElements() - 1 do
					jestExpect(store:getIndexOfElementID(store:getElementIDAtIndex(i))).toBe(
						i
					)
				end
			end)
			it("should support a single root with multiple top level children", function()
				-- ROBLOX deviation: switched ordering for variable definition order
				local function Child()
					return nil
				end
				local function Parent()
					return React.createElement(Child)
				end
				local function Grandparent()
					return React.createElement(Parent)
				end

				local root = ReactRoblox.createRoot(Instance.new("Frame"))

				act(function()
					return root:render(
						React.createElement(
							React.Fragment,
							nil,
							React.createElement(Grandparent),
							React.createElement(Grandparent)
						),
						Instance.new("Frame")
					)
				end)

				for i = 0, store:getNumElements() - 1 do
					jestExpect(store:getIndexOfElementID(store:getElementIDAtIndex(i))).toBe(
						i
					)
				end
			end)
			it(
				"should support multiple roots with multiple top level children",
				function()
					-- ROBLOX deviation: switched ordering for variable definition order
					local function Child()
						return nil
					end
					local function Parent()
						return React.createElement(Child)
					end
					local function Grandparent()
						return React.createElement(Parent)
					end

					local root = ReactRoblox.createRoot(Instance.new("Frame"))

					act(function()
						root:render(
							React.createElement(
								React.Fragment,
								nil,
								React.createElement(Grandparent),
								React.createElement(Grandparent)
							),
							Instance.new("Frame")
						)
					end)

					for i = 0, store:getNumElements() - 1 do
						jestExpect(
							store:getIndexOfElementID(store:getElementIDAtIndex(i))
						).toBe(i)
					end
				end
			)
		end)
		-- ROBLOX deviation: Not necessary as we will always support profiling
		-- it('detects and updates profiling support based on the attached roots', function()
		-- 	local function Component()
		-- 		return nil
		-- 	end

		-- 	local rootB = Instance.new("Frame")

		-- 	jestExpect(store:getSupportsProfiling()).toBe(false)
		-- 	act(function()
		-- 		return root:render(React.createElement(Component), containerA)
		-- 	end)
		-- 	jestExpect(store:getSupportsProfiling()).toBe(true)
		-- 	act(function()
		-- 		return root:render(React.createElement(Component), containerB)
		-- 	end)
		-- 	act(function()
		-- 		return ReactRoblox.unmountComponentAtNode(containerA)
		-- 	end)
		-- 	jestExpect(store:getSupportsProfiling()).toBe(true)
		-- 	act(function()
		-- 		return ReactRoblox.unmountComponentAtNode(containerB)
		-- 	end)
		-- 	jestExpect(store:getSupportsProfiling()).toBe(false)
		-- end)
		it("should properly serialize non-string key values", function()
			local function Child()
				return nil
			end
			local fauxElement = Object.assign(
				{},
				React.createElement(Child),
				{ key = 123 }
			)

			local root = ReactRoblox.createRoot(Instance.new("Frame"))
			act(function()
				return root:render({ fauxElement }, Instance.new("Frame"))
			end)
			jestExpect(devtoolsUtils.printStore(store)).toBe([[[root]
    <Child key="123">]])
		end)
		-- ROBLOX FIXME: this test only passes when focused
		xit("should show the right display names for special component types", function()
			local fakeImport = function(result)
				return Promise.resolve({ default = result })
			end
			local function MyComponent(props, ref)
				return nil
			end
			local ForwardRefComponent = React.forwardRef(MyComponent)
			local function MyComponent2(props, ref)
				return nil
			end
			local ForwardRefComponentWithAnonymousFunction = React.forwardRef(function()
				return React.createElement(MyComponent2)
			end)
			local function MyComponent3(props, ref)
				return nil
			end
			local ForwardRefComponentWithCustomDisplayName = React.forwardRef(
				MyComponent3
			)

			ForwardRefComponentWithCustomDisplayName.displayName = "Custom"

			local function MyComponent4(props, ref)
				return nil
			end
			local MemoComponent = React.memo(MyComponent4)
			local MemoForwardRefComponent = React.memo(ForwardRefComponent)
			local function MyComponent5(props, ref)
				return nil
			end
			local LazyComponent = React.lazy(function()
				return fakeImport(MyComponent5)
			end)
			local function FakeHigherOrderComponent()
				return nil
			end

			-- ROBLOX deviation: Lua can't set fields on functions, and this component *must* be a function component to be memoized
			-- FakeHigherOrderComponent.displayName = 'withFoo(withBar(Baz))'

			local MemoizedFakeHigherOrderComponent = React.memo(FakeHigherOrderComponent)
			local ForwardRefFakeHigherOrderComponent = React.forwardRef(
				FakeHigherOrderComponent
			)
			local function App()
				return React.createElement(
					React.Fragment,
					nil,
					React.createElement(MyComponent),
					React.createElement(ForwardRefComponent),
					React.createElement(ForwardRefComponentWithAnonymousFunction),
					React.createElement(ForwardRefComponentWithCustomDisplayName),
					React.createElement(MemoComponent),
					React.createElement(MemoForwardRefComponent),
					React.createElement(React.Suspense, {
						fallback = "Loading...",
					}, React.createElement(
						LazyComponent
					)),
					React.createElement(FakeHigherOrderComponent),
					React.createElement(MemoizedFakeHigherOrderComponent),
					React.createElement(ForwardRefFakeHigherOrderComponent)
				)
			end
			local root = ReactRoblox.createRoot(Instance.new("Frame"))

			-- Render once to start fetching the lazy component
			act(function()
				return root:render(React.createElement(App))
			end)

			-- ROBLOX deviation: equivalent of await Promise.resolve()
			Promise.delay(0):await()

			-- Render again after it resolves
			act(function()
				return root:render(React.createElement(App))
			end)
			-- ROBLOX TODO: Work out how to customize component display names to correctly parse hook names e.g. withFoo(withBar(Baz))
			-- ROBLOX TODO: Work out why MyComponent is anonymous when wrapped by forwardRef & Memo
			jestExpect(devtoolsUtils.printStore(store)).toBe([==[[root]
  ▾ <App>
      <MyComponent>
      <Anonymous> [ForwardRef]
    ▾ <Anonymous> [ForwardRef]
        <MyComponent2>
      <Custom> [ForwardRef]
      <MyComponent4> [Memo]
    ▾ <Anonymous> [Memo]
        <Anonymous> [ForwardRef]
    ▾ <Suspense>
        <MyComponent5>
      <FakeHigherOrderComponent>
      <FakeHigherOrderComponent> [Memo]
      <Anonymous> [ForwardRef]]==])
		end)
	end)
end
