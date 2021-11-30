-- upstream: https://github.com/facebook/react/blob/d13f5b9538e48f74f7c571ef3cde652ca887cca0/packages/react-reconciler/src/__tests__/ReactIncremental-test.js
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @emails react-core
--  * @jest-environment node
--  */

local Packages = script.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Error = LuauPolyfill.Error

local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
local React
local ReactNoop
local Scheduler
local PropTypes = nil
local HttpService = game:GetService("HttpService")
return function()
	local jestExpect = require(Packages.Dev.JestGlobals).expect

	describe("ReactIncremental", function()
		local RobloxJest = require(Packages.Dev.RobloxJest)

		beforeEach(function()
			RobloxJest.resetModules()

			React = require(Packages.React)
			ReactNoop = require(Packages.Dev.ReactNoopRenderer)
			Scheduler = require(Packages.Scheduler)
		end)

		-- Note: This is based on a similar component we use in www. We can delete
		-- once the extra div wrapper is no longer necessary.
		local function LegacyHiddenDiv(props)
			local children, mode = props.children, props.mode

			return React.createElement(
				"div",
				{
					hidden = mode == "hidden",
				},
				React.createElement(React.unstable_LegacyHidden, {
					mode = (function()
						if mode == "hidden" then
							return "unstable-defer-without-hiding"
						end

						return mode
					end)(),
				}, children)
			)
		end

		-- deviation: upstream JSON.stringify returns {} given an empty input, but
		-- Lua's JSONEncode returns [].
		local function JSONStringify(value)
			local res = HttpService:JSONEncode(value)
			if res == "[]" then
				res = "{}"
			end
			return res
		end

		it("should render a simple component", function()
			local function Bar()
				return React.createElement("div", nil, "Hello World")
			end
			local function Foo()
				return React.createElement(Bar, { isBar = true })
			end

			ReactNoop.render(React.createElement(Foo, nil))
			jestExpect(Scheduler).toFlushWithoutYielding()
		end)
		it("should render a simple component, in steps if needed", function()
			local function Bar()
				Scheduler.unstable_yieldValue("Bar")

				return React.createElement("span", nil, React.createElement("div", nil, "Hello World"))
			end
			local function Foo()
				Scheduler.unstable_yieldValue("Foo")

				return {
					React.createElement(Bar, {
						key = "a",
						isBar = true,
					}),
					React.createElement(Bar, {
						key = "b",
						isBar = true,
					}),
				}
			end

			ReactNoop.render(React.createElement(Foo, nil), function()
				return Scheduler.unstable_yieldValue("callback")
			end)

			-- Do one step of work.
			jestExpect(ReactNoop.flushNextYield()).toEqual({
				"Foo",
			})

			-- Do the rest of the work.
			jestExpect(Scheduler).toFlushAndYield({
				"Bar",
				"Bar",
				"callback",
			})
		end)
		it("updates a previous render", function()
			local function Header()
				Scheduler.unstable_yieldValue("Header")

				return React.createElement("h1", nil, "Hi")
			end
			local function Content(props)
				Scheduler.unstable_yieldValue("Content")

				return React.createElement("div", nil, props.children)
			end
			local function Footer()
				Scheduler.unstable_yieldValue("Footer")

				return React.createElement("footer", nil, "Bye")
			end

			local header = React.createElement(Header, nil)
			local footer = React.createElement(Footer, nil)

			local function Foo(props)
				Scheduler.unstable_yieldValue("Foo")

				return React.createElement("div", nil, header, React.createElement(Content, nil, props.text), footer)
			end

			ReactNoop.render(React.createElement(Foo, {
				text = "foo",
			}), function()
				return Scheduler.unstable_yieldValue("renderCallbackCalled")
			end)
			jestExpect(Scheduler).toFlushAndYield({
				"Foo",
				"Header",
				"Content",
				"Footer",
				"renderCallbackCalled",
			})
			ReactNoop.render(React.createElement(Foo, {
				text = "bar",
			}), function()
				return Scheduler.unstable_yieldValue("firstRenderCallbackCalled")
			end)
			ReactNoop.render(React.createElement(Foo, {
				text = "bar",
			}), function()
				return Scheduler.unstable_yieldValue("secondRenderCallbackCalled")
			end)

			-- TODO: Test bail out of host components. This is currently unobservable.

			-- Since this is an update, it should bail out and reuse the work from
			-- Header and Content.
			jestExpect(Scheduler).toFlushAndYield({
				"Foo",
				"Content",
				"firstRenderCallbackCalled",
				"secondRenderCallbackCalled",
			})
		end)
		it("can cancel partially rendered work and restart", function()
			local function Bar(props)
				Scheduler.unstable_yieldValue("Bar")

				return React.createElement("div", nil, props.children)
			end
			local function Foo(props)
				Scheduler.unstable_yieldValue("Foo")

				return React.createElement(
					"div",
					nil,
					React.createElement(Bar, nil, props.text),
					React.createElement(Bar, nil, props.text)
				)
			end

			-- Init
			ReactNoop.render(React.createElement(Foo, {
				text = "foo",
			}))
			jestExpect(Scheduler).toFlushAndYield({
				"Foo",
				"Bar",
				"Bar",
			})
			ReactNoop.render(React.createElement(Foo, {
				text = "bar",
			}))
			-- Flush part of the work
			jestExpect(Scheduler).toFlushAndYieldThrough({
				"Foo",
				"Bar",
			})

			-- This will abort the previous work and restart
			ReactNoop.flushSync(function()
				return ReactNoop.render(nil)
			end)
			ReactNoop.render(React.createElement(Foo, {
				text = "baz",
			}))
			jestExpect(Scheduler).toFlushAndYieldThrough({
				"Foo",
				"Bar",
			})
			jestExpect(Scheduler).toFlushAndYield({
				"Bar",
			})
		end)
		it("should call callbacks even if updates are aborted", function()
			local inst
			local Foo = React.Component:extend("Foo")

			function Foo:init()
				self.state = {
					text = "foo",
					text2 = "foo",
				}
				inst = self
			end
			function Foo:render()
				return React.createElement(
					"div",
					nil,
					React.createElement("div", nil, self.state.text),
					React.createElement("div", nil, self.state.text2)
				)
			end

			ReactNoop.render(React.createElement(Foo, nil))
			jestExpect(Scheduler).toFlushWithoutYielding()

			-- Flush part of the work
			inst:setState(function()
				Scheduler.unstable_yieldValue("setState1")

				return {
					text = "bar",
				}
			end, function()
				return Scheduler.unstable_yieldValue("callback1")
			end)
			jestExpect(Scheduler).toFlushAndYieldThrough({
				"setState1",
			})

			-- This will abort the previous work and restart
			ReactNoop.flushSync(function()
				return ReactNoop.render(React.createElement(Foo, nil))
			end)
			inst:setState(function()
				Scheduler.unstable_yieldValue("setState2")

				return {
					text2 = "baz",
				}
			end, function()
				return Scheduler.unstable_yieldValue("callback2")
			end)

			-- Flush the rest of the work which now includes the low priority
			jestExpect(Scheduler).toFlushAndYield({
				"setState1",
				"setState2",
				"callback1",
				"callback2",
			})
			jestExpect(inst.state).toEqual({
				text = "bar",
				text2 = "baz",
			})
		end)
		-- @gate experimental
		it("can deprioritize unfinished work and resume it later", function()
			local function Bar(props)
				Scheduler.unstable_yieldValue("Bar")
				return React.createElement("div", nil, props.children)
			end

			local function Middle(props)
				Scheduler.unstable_yieldValue("Middle")
				return React.createElement("span", nil, props.children)
			end

			local function Foo(props)
				Scheduler.unstable_yieldValue("Foo")
				return React.createElement(
					"div",
					nil,
					React.createElement(Bar, nil, props.text),
					React.createElement(
						LegacyHiddenDiv,
						{ mode = "hidden" },
						React.createElement(Middle, nil, props.text)
					),
					React.createElement(Bar, nil, props.text),
					React.createElement(LegacyHiddenDiv, { mode = "hidden" }, React.createElement(Middle, nil, "Footer"))
				)
			end

			-- Init
			ReactNoop.render(React.createElement(Foo, {
				text = "foo",
			}))
			jestExpect(Scheduler).toFlushAndYield({
				"Foo",
				"Bar",
				"Bar",
				"Middle",
				"Middle",
			})

			-- Render part of the work. This should be enough to flush everything except
			-- the middle which has lower priority.
			ReactNoop.render(React.createElement(Foo, {
				text = "bar",
			}))
			jestExpect(Scheduler).toFlushAndYieldThrough({
				"Foo",
				"Bar",
				"Bar",
			})
			jestExpect(Scheduler).toFlushAndYield({
				"Middle",
				"Middle",
			})
		end)

		-- @gate experimental
		it("can deprioritize a tree from without dropping work", function()
			local function Bar(props)
				Scheduler.unstable_yieldValue("Bar")

				return React.createElement("div", nil, props.children)
			end
			local function Middle(props)
				Scheduler.unstable_yieldValue("Middle")

				return React.createElement("span", nil, props.children)
			end
			local function Foo(props)
				Scheduler.unstable_yieldValue("Foo")

				return React.createElement(
					"div",
					nil,
					React.createElement(Bar, nil, props.text),
					React.createElement(LegacyHiddenDiv, {
						mode = "hidden",
					}, React.createElement(
						Middle,
						nil,
						props.text
					)),
					React.createElement(Bar, nil, props.text),
					React.createElement(LegacyHiddenDiv, {
						mode = "hidden",
					}, React.createElement(
						Middle,
						nil,
						"Footer"
					))
				)
			end

			-- Init
			ReactNoop.flushSync(function()
				ReactNoop.render(React.createElement(Foo, {
					text = "foo",
				}))
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Foo",
				"Bar",
				"Bar",
			})
			jestExpect(Scheduler).toFlushAndYield({
				"Middle",
				"Middle",
			})

			-- Render the high priority work (everything except the hidden trees).
			ReactNoop.flushSync(function()
				ReactNoop.render(React.createElement(Foo, {
					text = "foo",
				}))
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Foo",
				"Bar",
				"Bar",
			})

			-- The hidden content was deprioritized from high to low priority. A low
			-- priority callback should have been scheduled. Flush it now.
			jestExpect(Scheduler).toFlushAndYield({
				"Middle",
				"Middle",
			})
		end)

		-- ROBLOX: xited upstream
		-- xit('can resume work in a subtree even when a parent bails out', function()
		--     local function Bar(props)
		--         Scheduler.unstable_yieldValue('Bar')

		--         return React.createElement('div', nil, props.children)
		--     end
		--     local function Tester()
		--         Scheduler.unstable_yieldValue('Tester')

		--         return React.createElement('div', nil)
		--     end
		--     local function Middle(props)
		--         Scheduler.unstable_yieldValue('Middle')

		--         return React.createElement('span', nil, props.children)
		--     end

		--     local middleContent = React.createElement('aaa', nil, React.createElement(Tester, nil), React.createElement('bbb', {hidden = true}, React.createElement('ccc', nil, React.createElement(Middle, nil, 'Hi'))))

		--     local function Foo(props)
		--         Scheduler.unstable_yieldValue('Foo')

		--         return React.createElement('div', nil, React.createElement(Bar, nil, props.text), middleContent, React.createElement(Bar, nil, props.text))
		--     end

		--     ReactNoop.render(React.createElement(Foo, {
		--         text = 'foo',
		--     }))
		--     ReactNoop.flushDeferredPri(52)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Foo',
		--         'Bar',
		--         'Tester',
		--         'Bar',
		--     })
		--     ReactNoop.render(React.createElement(Foo, {
		--         text = 'bar',
		--     }))
		--     ReactNoop.flushDeferredPri(45 + 5)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Foo',
		--         'Bar',
		--         'Bar',
		--     })
		--     jestExpect(Scheduler).toFlushAndYield({
		--         'Middle',
		--     })
		-- end)
		-- xit('can resume work in a bailed subtree within one pass', function()
		--     local function Bar(props)
		--         Scheduler.unstable_yieldValue('Bar')

		--         return React.createElement('div', nil, props.children)
		--     end

		--     local Tester = {}
		--     local TesterMetatable = {__index = Tester}

		--     function Tester:shouldComponentUpdate()
		--         return false
		--     end
		--     function Tester:render()
		--         Scheduler.unstable_yieldValue('Tester')

		--         return React.createElement('div', nil)
		--     end

		--     local function Middle(props)
		--         Scheduler.unstable_yieldValue('Middle')

		--         return React.createElement('span', nil, props.children)
		--     end

		--     local Content = {}
		--     local ContentMetatable = {__index = Content}

		--     function Content:shouldComponentUpdate()
		--         return false
		--     end
		--     function Content:render()
		--         return{
		--             React.createElement(Tester, {
		--                 key = 'a',
		--                 unused = self.props.unused,
		--             }),
		--             React.createElement('bbb', {
		--                 key = 'b',
		--                 hidden = true,
		--             }, React.createElement('ccc', nil, React.createElement(Middle, nil, 'Hi'))),
		--         }
		--     end

		--     local function Foo(props)
		--         Scheduler.unstable_yieldValue('Foo')

		--         return React.createElement('div', {
		--             hidden = props.text == 'bar',
		--         }, React.createElement(Bar, nil, props.text), React.createElement(Content, {
		--             unused = props.text,
		--         }), React.createElement(Bar, nil, props.text))
		--     end

		--     ReactNoop.render(React.createElement(Foo, {
		--         text = 'foo',
		--     }))
		--     ReactNoop.flushDeferredPri(52 + 5)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Foo',
		--         'Bar',
		--         'Tester',
		--         'Bar',
		--     })
		--     ReactNoop.render(React.createElement(Foo, {
		--         text = 'bar',
		--     }))
		--     ReactNoop.flushDeferredPri(15)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Foo',
		--     })
		--     jestExpect(Scheduler).toFlushAndYield({
		--         'Bar',
		--         'Middle',
		--         'Bar',
		--     })
		--     ReactNoop.render(React.createElement(Foo, {
		--         text = 'foo',
		--     }))
		--     ReactNoop.flushDeferredPri(40)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Foo',
		--         'Bar',
		--     })
		--     ReactNoop.render(React.createElement(Foo, {
		--         text = 'bar',
		--     }))
		--     jestExpect(Scheduler).toFlushAndYield({
		--         'Foo',
		--         'Bar',
		--         'Bar',
		--     })
		-- end)
		-- xit('can resume mounting a class component', function()
		--     local foo
		--     local Parent = {}
		--     local ParentMetatable = {__index = Parent}

		--     function Parent:shouldComponentUpdate()
		--         return false
		--     end
		--     function Parent:render()
		--         return React.createElement(Foo, {
		--             prop = self.props.prop,
		--         })
		--     end

		--     local Foo = {}
		--     local FooMetatable = {__index = Foo}

		--     function Foo:init(props)
		--         local self = setmetatable({}, FooMetatable)

		--         Scheduler.unstable_yieldValue('Foo constructor: ' .. props.prop)
		--     end
		--     function Foo:render()
		--         foo = self

		--         Scheduler.unstable_yieldValue('Foo')

		--         return React.createElement(Bar, nil)
		--     end

		--     local function Bar()
		--         Scheduler.unstable_yieldValue('Bar')

		--         return React.createElement('div', nil)
		--     end

		--     ReactNoop.render(React.createElement(Parent, {
		--         prop = 'foo',
		--     }))
		--     ReactNoop.flushDeferredPri(20)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Foo constructor: foo',
		--         'Foo',
		--     })
		--     foo:setState({
		--         value = 'bar',
		--     })
		--     jestExpect(Scheduler).toFlushAndYield({
		--         'Foo',
		--         'Bar',
		--     })
		-- end)
		-- xit('reuses the same instance when resuming a class instance', function()
		--     local foo
		--     local Parent = {}
		--     local ParentMetatable = {__index = Parent}

		--     function Parent:shouldComponentUpdate()
		--         return false
		--     end
		--     function Parent:render()
		--         return React.createElement(Foo, {
		--             prop = self.props.prop,
		--         })
		--     end

		--     local constructorCount = 0
		--     local Foo = {}
		--     local FooMetatable = {__index = Foo}

		--     function Foo:init(props)
		--         local self = setmetatable({}, FooMetatable)

		--         Scheduler.unstable_yieldValue('constructor: ' .. props.prop)

		--         constructorCount = constructorCount + 1
		--     end
		--     function Foo:UNSAFE_componentWillMount()
		--         Scheduler.unstable_yieldValue('componentWillMount: ' .. self.props.prop)
		--     end
		--     function Foo:UNSAFE_componentWillReceiveProps()
		--         Scheduler.unstable_yieldValue('componentWillReceiveProps: ' .. self.props.prop)
		--     end
		--     function Foo:componentDidMount()
		--         Scheduler.unstable_yieldValue('componentDidMount: ' .. self.props.prop)
		--     end
		--     function Foo:UNSAFE_componentWillUpdate()
		--         Scheduler.unstable_yieldValue('componentWillUpdate: ' .. self.props.prop)
		--     end
		--     function Foo:componentDidUpdate()
		--         Scheduler.unstable_yieldValue('componentDidUpdate: ' .. self.props.prop)
		--     end
		--     function Foo:render()
		--         foo = self

		--         Scheduler.unstable_yieldValue('render: ' .. self.props.prop)

		--         return React.createElement(Bar, nil)
		--     end

		--     local function Bar()
		--         Scheduler.unstable_yieldValue('Foo did complete')

		--         return React.createElement('div', nil)
		--     end

		--     ReactNoop.render(React.createElement(Parent, {
		--         prop = 'foo',
		--     }))
		--     ReactNoop.flushDeferredPri(25)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'constructor: foo',
		--         'componentWillMount: foo',
		--         'render: foo',
		--         'Foo did complete',
		--     })
		--     foo:setState({
		--         value = 'bar',
		--     })
		--     jestExpect(Scheduler).toFlushWithoutYielding()
		--     jestExpect(constructorCount).toEqual(1)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'componentWillMount: foo',
		--         'render: foo',
		--         'Foo did complete',
		--         'componentDidMount: foo',
		--     })
		-- end)
		-- xit('can reuse work done after being preempted', function()
		--     local function Bar(props)
		--         Scheduler.unstable_yieldValue('Bar')

		--         return React.createElement('div', nil, props.children)
		--     end
		--     local function Middle(props)
		--         Scheduler.unstable_yieldValue('Middle')

		--         return React.createElement('span', nil, props.children)
		--     end

		--     local middleContent = React.createElement('div', nil, React.createElement(Middle, nil, 'Hello'), React.createElement(Bar, nil, '-'), React.createElement(Middle, nil, 'World'))
		--     local step0 = React.createElement('div', nil, React.createElement(Middle, nil, 'Hi'), React.createElement(Bar, nil, 'Foo'), React.createElement(Middle, nil, 'There'))

		--     local function Foo(props)
		--         Scheduler.unstable_yieldValue('Foo')

		--         return React.createElement('div', nil, React.createElement(Bar, nil, props.text2), React.createElement('div', {hidden = true}, (function(
		--         )
		--             if props.step == 0 then
		--                 return step0
		--             end

		--             return middleContent
		--         end)()))
		--     end

		--     ReactNoop.render(React.createElement(Foo, {
		--         text = 'foo',
		--         text2 = 'foo',
		--         step = 0,
		--     }))
		--     ReactNoop.flushDeferredPri(55 + 25 + 5 + 5)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Foo',
		--         'Bar',
		--         'Middle',
		--         'Bar',
		--     })
		--     ReactNoop.render(React.createElement(Foo, {
		--         text = 'foo',
		--         text2 = 'bar',
		--         step = 0,
		--     }))
		--     jestExpect(Scheduler).toFlushWithoutYielding()
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Foo',
		--         'Bar',
		--         'Middle',
		--     })
		--     ReactNoop.render(React.createElement(Foo, {
		--         text = 'bar',
		--         text2 = 'bar',
		--         step = 1,
		--     }))
		--     ReactNoop.flushDeferredPri(30 + 25 + 5)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Foo',
		--         'Bar',
		--     })
		--     ReactNoop.flushDeferredPri(30 + 5)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Middle',
		--         'Bar',
		--     })
		--     ReactNoop.render(React.createElement(Foo, {
		--         text = 'foo',
		--         text2 = 'bar',
		--         step = 1,
		--     }))
		--     ReactNoop.flushDeferredPri(30)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Foo',
		--         'Bar',
		--     })
		--     jestExpect(Scheduler).toFlushAndYield({
		--         'Middle',
		--     })
		-- end)
		-- xit('can reuse work that began but did not complete, after being preempted', function()
		--     local child
		--     local sibling

		--     local function GreatGrandchild()
		--         Scheduler.unstable_yieldValue('GreatGrandchild')

		--         return React.createElement('div', nil)
		--     end
		--     local function Grandchild()
		--         Scheduler.unstable_yieldValue('Grandchild')

		--         return React.createElement(GreatGrandchild, nil)
		--     end

		--     local Child = {}
		--     local ChildMetatable = {__index = Child}

		--     function Child:init()
		--         local self = setmetatable({}, ChildMetatable)
		--         local _temp

		--         return
		--     end
		--     function Child:render()
		--         child = self

		--         Scheduler.unstable_yieldValue('Child')

		--         return React.createElement(Grandchild, nil)
		--     end

		--     local Sibling = {}
		--     local SiblingMetatable = {__index = Sibling}

		--     function Sibling:render()
		--         Scheduler.unstable_yieldValue('Sibling')

		--         sibling = self

		--         return React.createElement('div', nil)
		--     end

		--     local function Parent()
		--         Scheduler.unstable_yieldValue('Parent')

		--         return{
		--             React.createElement('div', {
		--                 key = 'a',
		--             }, React.createElement(Child, nil)),
		--             React.createElement(Sibling, {
		--                 key = 'b',
		--             }),
		--         }
		--     end

		--     ReactNoop.render(React.createElement(Parent, nil))
		--     jestExpect(Scheduler).toFlushWithoutYielding()
		--     child:setState({step = 1})
		--     ReactNoop.flushDeferredPri(30)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Child',
		--         'Grandchild',
		--     })
		--     ReactNoop.flushSync(function()
		--         sibling:setState({})
		--     end)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Sibling',
		--     })
		--     jestExpect(Scheduler).toFlushAndYield({
		--         'GreatGrandchild',
		--     })
		-- end)
		-- xit('can reuse work if shouldComponentUpdate is false, after being preempted', function()
		--     local function Bar(props)
		--         Scheduler.unstable_yieldValue('Bar')

		--         return React.createElement('div', nil, props.children)
		--     end

		--     local Middle = {}
		--     local MiddleMetatable = {__index = Middle}

		--     function Middle:shouldComponentUpdate(nextProps)
		--         return self.props.children ~= nextProps.children
		--     end
		--     function Middle:render()
		--         Scheduler.unstable_yieldValue('Middle')

		--         return React.createElement('span', nil, self.props.children)
		--     end

		--     local Content = {}
		--     local ContentMetatable = {__index = Content}

		--     function Content:shouldComponentUpdate(nextProps)
		--         return self.props.step ~= nextProps.step
		--     end
		--     function Content:render()
		--         Scheduler.unstable_yieldValue('Content')

		--         return React.createElement('div', nil, React.createElement(Middle, nil, (function()
		--             if self.props.step == 0 then
		--                 return'Hi'
		--             end

		--             return'Hello'
		--         end)()), React.createElement(Bar, nil, (function()
		--             if self.props.step == 0 then
		--                 return self.props.text
		--             end

		--             return'-'
		--         end)()), React.createElement(Middle, nil, (function()
		--             if self.props.step == 0 then
		--                 return'There'
		--             end

		--             return'World'
		--         end)()))
		--     end

		--     local function Foo(props)
		--         Scheduler.unstable_yieldValue('Foo')

		--         return React.createElement('div', nil, React.createElement(Bar, nil, props.text), React.createElement('div', {hidden = true}, React.createElement(Content, {
		--             step = props.step,
		--             text = props.text,
		--         })))
		--     end

		--     ReactNoop.render(React.createElement(Foo, {
		--         text = 'foo',
		--         step = 0,
		--     }))
		--     jestExpect(Scheduler).toFlushAndYield({
		--         'Foo',
		--         'Bar',
		--         'Content',
		--         'Middle',
		--         'Bar',
		--         'Middle',
		--     })
		--     ReactNoop.render(React.createElement(Foo, {
		--         text = 'bar',
		--         step = 1,
		--     }))
		--     ReactNoop.flushDeferredPri(30 + 5)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Foo',
		--         'Bar',
		--     })
		--     ReactNoop.flushDeferredPri(30 + 25 + 5)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Content',
		--         'Middle',
		--         'Bar',
		--     })
		--     ReactNoop.render(React.createElement(Foo, {
		--         text = 'foo',
		--         step = 1,
		--     }))
		--     ReactNoop.flushDeferredPri(30)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Foo',
		--         'Bar',
		--     })
		--     jestExpect(Scheduler).toFlushAndYield({
		--         'Middle',
		--     })
		-- end)
		it("memoizes work even if shouldComponentUpdate returns false", function()
			local Foo = React.Component:extend("Foo")

			function Foo:shouldComponentUpdate(nextProps)
				-- this.props is the memoized props. So this should return true for
				-- every update except the first one.
				local shouldUpdate = self.props.step ~= 1

				Scheduler.unstable_yieldValue("shouldComponentUpdate: " .. tostring(shouldUpdate))

				return shouldUpdate
			end
			function Foo:render()
				Scheduler.unstable_yieldValue("render")

				return React.createElement("div", nil)
			end

			ReactNoop.render(React.createElement(Foo, { step = 1 }))
			jestExpect(Scheduler).toFlushAndYield({
				"render",
			})
			ReactNoop.render(React.createElement(Foo, { step = 2 }))
			jestExpect(Scheduler).toFlushAndYield({
				"shouldComponentUpdate: false",
			})
			ReactNoop.render(React.createElement(Foo, { step = 3 }))
			jestExpect(Scheduler).toFlushAndYield({
				-- If the memoized props were not updated during last bail out, sCU will
				-- keep returning false.
				"shouldComponentUpdate: true",
				"render",
			})
		end)
		it("can update in the middle of a tree using setState", function()
			local instance
			local Bar = React.Component:extend("Bar")

			function Bar:init()
				self.state = {
					a = "a",
				}
				instance = self
			end
			function Bar:render()
				return React.createElement("div", nil, self.props.children)
			end

			local function Foo()
				return React.createElement("div", nil, React.createElement(Bar, nil))
			end

			ReactNoop.render(React.createElement(Foo, nil))
			jestExpect(Scheduler).toFlushWithoutYielding()
			jestExpect(instance.state).toEqual({
				a = "a",
			})
			instance:setState({
				b = "b",
			})
			jestExpect(Scheduler).toFlushWithoutYielding()
			jestExpect(instance.state).toEqual({
				a = "a",
				b = "b",
			})
		end)
		it("can queue multiple state updates", function()
			local instance
			local Bar = React.Component:extend("Bar")

			function Bar:init()
				self.state = {
					a = "a",
				}
				instance = self
			end
			function Bar:render()
				return React.createElement("div", nil, self.props.children)
			end

			local function Foo()
				return React.createElement("div", nil, React.createElement(Bar, nil))
			end

			ReactNoop.render(React.createElement(Foo))
			jestExpect(Scheduler).toFlushWithoutYielding()
			-- Call setState multiple times before flushing
			instance:setState({
				b = "b",
			})
			instance:setState({
				c = "c",
			})
			instance:setState({
				d = "d",
			})
			jestExpect(Scheduler).toFlushWithoutYielding()
			jestExpect(instance.state).toEqual({
				a = "a",
				b = "b",
				c = "c",
				d = "d",
			})
		end)
		it("can use updater form of setState", function()
			local instance
			local Bar = React.Component:extend("Bar")

			function Bar:init()
				self.state = { num = 1 }
				instance = self
			end
			function Bar:render()
				return React.createElement("div", nil, self.props.children)
			end

			local function Foo(ref)
				return React.createElement("div", nil, React.createElement(Bar, { multiplier = ref.multiplier }))
			end

			-- deviation: Roact requires first arg of updater to be self
			local function updater(state, props)
				return {
					num = state.num * props.multiplier,
				}
			end

			ReactNoop.render(React.createElement(Foo, { multiplier = 2 }))
			jestExpect(Scheduler).toFlushWithoutYielding()
			jestExpect(instance.state.num).toEqual(1)
			instance:setState(updater)
			jestExpect(Scheduler).toFlushWithoutYielding()
			jestExpect(instance.state.num).toEqual(2)
			instance:setState(updater)
			ReactNoop.render(React.createElement(Foo, { multiplier = 3 }))
			jestExpect(Scheduler).toFlushWithoutYielding()
			jestExpect(instance.state.num).toEqual(6)
		end)
		it("can call setState inside update callback", function()
			local instance
			local Bar = React.Component:extend("Bar")

			function Bar:init()
				self.state = { num = 1 }
				instance = self
			end
			function Bar:render()
				return React.createElement("div", nil, self.props.children)
			end

			local function Foo(_ref3)
				local multiplier = _ref3.multiplier

				return React.createElement("div", nil, React.createElement(Bar, { multiplier = multiplier }))
			end

			-- deviation: Roact requires first arg of updater to be self
			local function updater(state, props)
				return {
					num = state.num * props.multiplier,
				}
			end
			local function callback(self)
				self:setState({ called = true })
			end

			ReactNoop.render(React.createElement(Foo, { multiplier = 2 }))
			jestExpect(Scheduler).toFlushWithoutYielding()
			instance:setState(updater)
			instance:setState(updater, callback)
			jestExpect(Scheduler).toFlushWithoutYielding()
			jestExpect(instance.state.num).toEqual(4)
			jestExpect(instance.state.called).toEqual(true)
		end)
		it("can replaceState", function()
			local instance
			local Bar = React.Component:extend("Bar")

			function Bar:render()
				instance = self

				return React.createElement("div", nil, self.props.children)
			end

			local function Foo()
				return React.createElement("div", nil, React.createElement(Bar, nil))
			end

			ReactNoop.render(React.createElement(Foo, nil))
			jestExpect(Scheduler).toFlushWithoutYielding()
			instance:setState({
				b = "b",
			})
			instance:setState({
				c = "c",
			})
			instance.__updater.enqueueReplaceState(instance, {
				d = "d",
			})
			jestExpect(Scheduler).toFlushWithoutYielding()
			jestExpect(instance.state).toEqual({
				d = "d",
			})
		end)
		it("can forceUpdate", function()
			local function Baz()
				Scheduler.unstable_yieldValue("Baz")

				return React.createElement("div", nil)
			end

			local instance
			local Bar = React.Component:extend("Bar")

			function Bar:init()
				instance = self
			end
			function Bar:shouldComponentUpdate()
				return false
			end
			function Bar:render()
				Scheduler.unstable_yieldValue("Bar")

				return React.createElement(Baz, nil)
			end

			local function Foo()
				Scheduler.unstable_yieldValue("Foo")

				return React.createElement("div", nil, React.createElement(Bar, nil))
			end

			ReactNoop.render(React.createElement(Foo, nil))
			jestExpect(Scheduler).toFlushAndYield({
				"Foo",
				"Bar",
				"Baz",
			})
			instance:forceUpdate()
			jestExpect(Scheduler).toFlushAndYield({
				"Bar",
				"Baz",
			})
		end)

		it("should clear forceUpdate after update is flushed", function()
			local a = 0
			local Foo = React.PureComponent:extend("Foo")

			function Foo:render()
				local msg = ("A: %s, B: %s"):format(a, self.props.b)

				Scheduler.unstable_yieldValue(msg)
				return msg
			end

			local foo = React.createRef(nil)

			ReactNoop.render(React.createElement(Foo, {
				ref = foo,
				b = 0,
			}))
			jestExpect(Scheduler).toFlushAndYield({
				"A: 0, B: 0",
			})

			a = 1

			foo.current:forceUpdate()
			jestExpect(Scheduler).toFlushAndYield({
				"A: 1, B: 0",
			})
			ReactNoop.render(React.createElement(Foo, {
				ref = foo,
				b = 0,
			}))
			jestExpect(Scheduler).toFlushAndYield({})
		end)

		-- ROBLOX: xited upstream
		-- xit('can call sCU while resuming a partly mounted component', function()
		--     local instances = Set()
		--     local Bar = {}
		--     local BarMetatable = {__index = Bar}

		--     function Bar:init()
		--         local self = setmetatable({}, BarMetatable)

		--         self.state = {
		--             y = 'A',
		--         }

		--         instances.add(self)
		--     end
		--     function Bar:shouldComponentUpdate(newProps, newState)
		--         return self.props.x ~= newProps.x or self.state.y ~= newState.y
		--     end
		--     function Bar:render()
		--         Scheduler.unstable_yieldValue('Bar:' .. self.props.x)

		--         return React.createElement('span', {
		--             prop = '' .. (self.props.x == self.state.y),
		--         })
		--     end

		--     local function Foo(props)
		--         Scheduler.unstable_yieldValue('Foo')

		--         return{
		--             React.createElement(Bar, {
		--                 key = 'a',
		--                 x = 'A',
		--             }),
		--             React.createElement(Bar, {
		--                 key = 'b',
		--                 x = (function()
		--                     if props.step == 0 then
		--                         return'B'
		--                     end

		--                     return'B2'
		--                 end)(),
		--             }),
		--             React.createElement(Bar, {
		--                 key = 'c',
		--                 x = 'C',
		--             }),
		--             React.createElement(Bar, {
		--                 key = 'd',
		--                 x = 'D',
		--             }),
		--         }
		--     end

		--     ReactNoop.render(React.createElement(Foo, {step = 0}))
		--     ReactNoop.flushDeferredPri(40)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Foo',
		--         'Bar:A',
		--         'Bar:B',
		--         'Bar:C',
		--     })
		--     jestExpect(instances.size).toBe(3)
		--     ReactNoop.render(React.createElement(Foo, {step = 1}))
		--     ReactNoop.flushDeferredPri(50)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Foo',
		--         'Bar:B2',
		--         'Bar:D',
		--     })
		--     jestExpect(instances.size).toBe(4)
		-- end)
		-- xit('gets new props when setting state on a partly updated component', function()
		--     local instances = {}
		--     local Bar = {}
		--     local BarMetatable = {__index = Bar}

		--     function Bar:init()
		--         local self = setmetatable({}, BarMetatable)

		--         self.state = {
		--             y = 'A',
		--         }

		--         instances.push(self)
		--     end
		--     function Bar:performAction()
		--         self:setState({
		--             y = 'B',
		--         })
		--     end
		--     function Bar:render()
		--         Scheduler.unstable_yieldValue('Bar:' .. self.props.x .. '-' .. self.props.step)

		--         return React.createElement('span', {
		--             prop = '' .. (self.props.x == self.state.y),
		--         })
		--     end

		--     local function Baz()
		--         Scheduler.unstable_yieldValue('Baz')

		--         return React.createElement('div', nil)
		--     end
		--     local function Foo(props)
		--         Scheduler.unstable_yieldValue('Foo')

		--         return{
		--             React.createElement(Bar, {
		--                 key = 'a',
		--                 x = 'A',
		--                 step = props.step,
		--             }),
		--             React.createElement(Bar, {
		--                 key = 'b',
		--                 x = 'B',
		--                 step = props.step,
		--             }),
		--         }
		--     end

		--     ReactNoop.render(React.createElement('div', nil, React.createElement(Foo, {step = 0}), React.createElement(Baz, nil), React.createElement(Baz, nil)))
		--     jestExpect(Scheduler).toFlushWithoutYielding()
		--     ReactNoop.render(React.createElement('div', nil, React.createElement(Foo, {step = 1}), React.createElement(Baz, nil), React.createElement(Baz, nil)))
		--     ReactNoop.flushDeferredPri(45)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Foo',
		--         'Bar:A-1',
		--         'Bar:B-1',
		--         'Baz',
		--     })
		--     instances[0].performAction()
		--     jestExpect(Scheduler).toFlushAndYield({
		--         'Bar:A-1',
		--         'Baz',
		--     })
		-- end)
		-- xit('calls componentWillMount twice if the initial render is aborted', function()
		--     local LifeCycle = {}
		--     local LifeCycleMetatable = {__index = LifeCycle}

		--     function LifeCycle:init()
		--         local self = setmetatable({}, LifeCycleMetatable)
		--         local _temp3

		--         return
		--     end
		--     function LifeCycle:UNSAFE_componentWillReceiveProps(nextProps)
		--         Scheduler.unstable_yieldValue('componentWillReceiveProps:' .. self.state.x .. '-' .. nextProps.x)
		--         self:setState({
		--             x = nextProps.x,
		--         })
		--     end
		--     function LifeCycle:UNSAFE_componentWillMount()
		--         Scheduler.unstable_yieldValue('componentWillMount:' .. self.state.x .. '-' .. self.props.x)
		--     end
		--     function LifeCycle:componentDidMount()
		--         Scheduler.unstable_yieldValue('componentDidMount:' .. self.state.x .. '-' .. self.props.x)
		--     end
		--     function LifeCycle:render()
		--         return React.createElement('span', nil)
		--     end

		--     local function Trail()
		--         Scheduler.unstable_yieldValue('Trail')

		--         return nil
		--     end
		--     local function App(props)
		--         Scheduler.unstable_yieldValue('App')

		--         return React.createElement('div', nil, React.createElement(LifeCycle, {
		--             x = props.x,
		--         }), React.createElement(Trail, nil))
		--     end

		--     ReactNoop.render(React.createElement(App, {x = 0}))
		--     ReactNoop.flushDeferredPri(30)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'App',
		--         'componentWillMount:0-0',
		--     })
		--     ReactNoop.render(React.createElement(App, {x = 1}))
		--     jestExpect(Scheduler).toFlushAndYield({
		--         'App',
		--         'componentWillReceiveProps:0-1',
		--         'componentWillMount:1-1',
		--         'Trail',
		--         'componentDidMount:1-1',
		--     })
		-- end)
		-- xit('uses state set in componentWillMount even if initial render was aborted', function()
		--     local LifeCycle = {}
		--     local LifeCycleMetatable = {__index = LifeCycle}

		--     function LifeCycle:init(props)
		--         local self = setmetatable({}, LifeCycleMetatable)

		--         self.state = {
		--             x = self.props.x .. '(ctor)',
		--         }
		--     end
		--     function LifeCycle:UNSAFE_componentWillMount()
		--         Scheduler.unstable_yieldValue('componentWillMount:' .. self.state.x)
		--         self:setState({
		--             x = self.props.x .. '(willMount)',
		--         })
		--     end
		--     function LifeCycle:componentDidMount()
		--         Scheduler.unstable_yieldValue('componentDidMount:' .. self.state.x)
		--     end
		--     function LifeCycle:render()
		--         Scheduler.unstable_yieldValue('render:' .. self.state.x)

		--         return React.createElement('span', nil)
		--     end

		--     local function App(props)
		--         Scheduler.unstable_yieldValue('App')

		--         return React.createElement(LifeCycle, {
		--             x = props.x,
		--         })
		--     end

		--     ReactNoop.render(React.createElement(App, {x = 0}))
		--     ReactNoop.flushDeferredPri(20)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'App',
		--         'componentWillMount:0(ctor)',
		--         'render:0(willMount)',
		--     })
		--     ReactNoop.render(React.createElement(App, {x = 1}))
		--     jestExpect(Scheduler).toFlushAndYield({
		--         'App',
		--         'componentWillMount:0(willMount)',
		--         'render:1(willMount)',
		--         'componentDidMount:1(willMount)',
		--     })
		-- end)
		-- xit('calls componentWill* twice if an update render is aborted', function()
		--     local LifeCycle = {}
		--     local LifeCycleMetatable = {__index = LifeCycle}

		--     function LifeCycle:UNSAFE_componentWillMount()
		--         Scheduler.unstable_yieldValue('componentWillMount:' .. self.props.x)
		--     end
		--     function LifeCycle:componentDidMount()
		--         Scheduler.unstable_yieldValue('componentDidMount:' .. self.props.x)
		--     end
		--     function LifeCycle:UNSAFE_componentWillReceiveProps(nextProps)
		--         Scheduler.unstable_yieldValue('componentWillReceiveProps:' .. self.props.x .. '-' .. nextProps.x)
		--     end
		--     function LifeCycle:shouldComponentUpdate(nextProps)
		--         Scheduler.unstable_yieldValue('shouldComponentUpdate:' .. self.props.x .. '-' .. nextProps.x)

		--         return true
		--     end
		--     function LifeCycle:UNSAFE_componentWillUpdate(nextProps)
		--         Scheduler.unstable_yieldValue('componentWillUpdate:' .. self.props.x .. '-' .. nextProps.x)
		--     end
		--     function LifeCycle:componentDidUpdate(prevProps)
		--         Scheduler.unstable_yieldValue('componentDidUpdate:' .. self.props.x .. '-' .. prevProps.x)
		--     end
		--     function LifeCycle:render()
		--         Scheduler.unstable_yieldValue('render:' .. self.props.x)

		--         return React.createElement('span', nil)
		--     end

		--     local function Sibling()
		--         Scheduler.unstable_yieldValue('Sibling')

		--         return React.createElement('span', nil)
		--     end
		--     local function App(props)
		--         Scheduler.unstable_yieldValue('App')

		--         return{
		--             React.createElement(LifeCycle, {
		--                 key = 'a',
		--                 x = props.x,
		--             }),
		--             React.createElement(Sibling, {
		--                 key = 'b',
		--             }),
		--         }
		--     end

		--     ReactNoop.render(React.createElement(App, {x = 0}))
		--     jestExpect(Scheduler).toFlushAndYield({
		--         'App',
		--         'componentWillMount:0',
		--         'render:0',
		--         'Sibling',
		--         'componentDidMount:0',
		--     })
		--     ReactNoop.render(React.createElement(App, {x = 1}))
		--     ReactNoop.flushDeferredPri(30)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'App',
		--         'componentWillReceiveProps:0-1',
		--         'shouldComponentUpdate:0-1',
		--         'componentWillUpdate:0-1',
		--         'render:1',
		--         'Sibling',
		--     })
		--     ReactNoop.render(React.createElement(App, {x = 2}))
		--     jestExpect(Scheduler).toFlushAndYield({
		--         'App',
		--         'componentWillReceiveProps:1-2',
		--         'shouldComponentUpdate:1-2',
		--         'componentWillUpdate:1-2',
		--         'render:2',
		--         'Sibling',
		--         'componentDidUpdate:2-0',
		--     })
		-- end)
		it("calls getDerivedStateFromProps even for state-only updates", function()
			local instance
			local LifeCycle = React.Component:extend("LifeCycle")

			function LifeCycle.getDerivedStateFromProps(props, prevState)
				Scheduler.unstable_yieldValue("getDerivedStateFromProps")

				return {
					foo = "foo",
				}
			end
			function LifeCycle:changeState()
				self:setState({
					foo = "bar",
				})
			end
			function LifeCycle:componentDidUpdate()
				Scheduler.unstable_yieldValue("componentDidUpdate")
			end
			function LifeCycle:render()
				Scheduler.unstable_yieldValue("render")

				instance = self

				return nil
			end

			ReactNoop.render(React.createElement(LifeCycle, nil))
			jestExpect(Scheduler).toFlushAndYield({
				"getDerivedStateFromProps",
				"render",
			})
			jestExpect(instance.state).toEqual({
				foo = "foo",
			})
			instance:changeState()
			jestExpect(Scheduler).toFlushAndYield({
				"getDerivedStateFromProps",
				"render",
				"componentDidUpdate",
			})
			jestExpect(instance.state).toEqual({
				foo = "foo",
			})
		end)
		it("does not call getDerivedStateFromProps if neither state nor props have changed", function()
			local Child = React.Component:extend("Child")

			function Child:render()
				Scheduler.unstable_yieldValue("Child")

				return self.props.parentRenders
			end

			local child = React.createRef(nil)

			local Parent = React.Component:extend("Parent")

			function Parent:init()
				self.state = { parentRenders = 0 }
			end

			function Parent.getDerivedStateFromProps(props, prevState)
				Scheduler.unstable_yieldValue("getDerivedStateFromProps")

				return prevState.parentRenders .. 1
			end
			function Parent:render()
				Scheduler.unstable_yieldValue("Parent")

				return React.createElement(Child, {
					parentRenders = self.state.parentRenders,
					ref = child,
				})
			end

			ReactNoop.render(React.createElement(Parent, nil))
			jestExpect(Scheduler).toFlushAndYield({
				"getDerivedStateFromProps",
				"Parent",
				"Child",
			})

			-- Schedule an update on the child. The parent should not re-render.
			child.current:setState({})
			jestExpect(Scheduler).toFlushAndYield({
				"Child",
			})
		end)
		-- ROBLOX deviation: xited upstream, so leave commented out
		-- xit('does not call componentWillReceiveProps for state-only updates', function()
		--     local instances = {}
		--     local LifeCycle = {}
		--     local LifeCycleMetatable = {__index = LifeCycle}

		--     function LifeCycle:init()
		--         local self = setmetatable({}, LifeCycleMetatable)
		--         local _temp6

		--         return
		--     end
		--     function LifeCycle:tick()
		--         self:setState({
		--             x = self.state.x + 1,
		--         })
		--     end
		--     function LifeCycle:UNSAFE_componentWillMount()
		--         instances.push(self)
		--         Scheduler.unstable_yieldValue('componentWillMount:' .. self.state.x)
		--     end
		--     function LifeCycle:componentDidMount()
		--         Scheduler.unstable_yieldValue('componentDidMount:' .. self.state.x)
		--     end
		--     function LifeCycle:UNSAFE_componentWillReceiveProps(nextProps)
		--         Scheduler.unstable_yieldValue('componentWillReceiveProps')
		--     end
		--     function LifeCycle:shouldComponentUpdate(nextProps, nextState)
		--         Scheduler.unstable_yieldValue('shouldComponentUpdate:' .. self.state.x .. '-' .. nextState.x)

		--         return true
		--     end
		--     function LifeCycle:UNSAFE_componentWillUpdate(nextProps, nextState)
		--         Scheduler.unstable_yieldValue('componentWillUpdate:' .. self.state.x .. '-' .. nextState.x)
		--     end
		--     function LifeCycle:componentDidUpdate(prevProps, prevState)
		--         Scheduler.unstable_yieldValue('componentDidUpdate:' .. self.state.x .. '-' .. prevState.x)
		--     end
		--     function LifeCycle:render()
		--         Scheduler.unstable_yieldValue('render:' .. self.state.x)

		--         return React.createElement('span', nil)
		--     end

		--     local Wrap = {}
		--     local WrapMetatable = {__index = Wrap}

		--     function Wrap:init()
		--         local self = setmetatable({}, WrapMetatable)
		--         local _temp7

		--         return
		--     end
		--     function Wrap:UNSAFE_componentWillMount()
		--         instances.push(self)
		--     end
		--     function Wrap:tick()
		--         self:setState({
		--             y = self.state.y + 1,
		--         })
		--     end
		--     function Wrap:render()
		--         Scheduler.unstable_yieldValue('Wrap')

		--         return React.createElement(LifeCycle, {
		--             y = self.state.y,
		--         })
		--     end

		--     local function Sibling()
		--         Scheduler.unstable_yieldValue('Sibling')

		--         return React.createElement('span', nil)
		--     end
		--     local function App(props)
		--         Scheduler.unstable_yieldValue('App')

		--         return{
		--             React.createElement(Wrap, {
		--                 key = 'a',
		--             }),
		--             React.createElement(Sibling, {
		--                 key = 'b',
		--             }),
		--         }
		--     end

		--     ReactNoop.render(React.createElement(App, {y = 0}))
		--     jestExpect(Scheduler).toFlushAndYield({
		--         'App',
		--         'Wrap',
		--         'componentWillMount:0',
		--         'render:0',
		--         'Sibling',
		--         'componentDidMount:0',
		--     })
		--     instances[1].tick()
		--     ReactNoop.flushDeferredPri(25)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'shouldComponentUpdate:0-1',
		--         'componentWillUpdate:0-1',
		--         'render:1',
		--     })
		--     instances[1].tick()
		--     jestExpect(Scheduler).toFlushAndYield({
		--         'shouldComponentUpdate:1-2',
		--         'componentWillUpdate:1-2',
		--         'render:2',
		--         'componentDidUpdate:2-0',
		--     })
		--     instances[0].tick()
		--     ReactNoop.flushDeferredPri(30)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'Wrap',
		--         'componentWillReceiveProps',
		--         'shouldComponentUpdate:2-2',
		--         'componentWillUpdate:2-2',
		--         'render:2',
		--     })
		--     instances[1].tick()
		--     jestExpect(Scheduler).toFlushAndYield({
		--         'shouldComponentUpdate:2-3',
		--         'componentWillUpdate:2-3',
		--         'render:3',
		--         'componentDidUpdate:3-2',
		--     })
		-- end)
		-- xit('skips will/DidUpdate when bailing unless an update was already in progress', function()
		--     local LifeCycle = {}
		--     local LifeCycleMetatable = {__index = LifeCycle}

		--     function LifeCycle:UNSAFE_componentWillMount()
		--         Scheduler.unstable_yieldValue('componentWillMount')
		--     end
		--     function LifeCycle:componentDidMount()
		--         Scheduler.unstable_yieldValue('componentDidMount')
		--     end
		--     function LifeCycle:UNSAFE_componentWillReceiveProps(nextProps)
		--         Scheduler.unstable_yieldValue('componentWillReceiveProps')
		--     end
		--     function LifeCycle:shouldComponentUpdate(nextProps)
		--         Scheduler.unstable_yieldValue('shouldComponentUpdate')

		--         return self.props.x ~= nextProps.x
		--     end
		--     function LifeCycle:UNSAFE_componentWillUpdate(nextProps)
		--         Scheduler.unstable_yieldValue('componentWillUpdate')
		--     end
		--     function LifeCycle:componentDidUpdate(prevProps)
		--         Scheduler.unstable_yieldValue('componentDidUpdate')
		--     end
		--     function LifeCycle:render()
		--         Scheduler.unstable_yieldValue('render')

		--         return React.createElement('span', nil)
		--     end

		--     local function Sibling()
		--         Scheduler.unstable_yieldValue('render sibling')

		--         return React.createElement('span', nil)
		--     end
		--     local function App(props)
		--         return{
		--             React.createElement(LifeCycle, {
		--                 key = 'a',
		--                 x = props.x,
		--             }),
		--             React.createElement(Sibling, {
		--                 key = 'b',
		--             }),
		--         }
		--     end

		--     ReactNoop.render(React.createElement(App, {x = 0}))
		--     jestExpect(Scheduler).toFlushAndYield({
		--         'componentWillMount',
		--         'render',
		--         'render sibling',
		--         'componentDidMount',
		--     })
		--     ReactNoop.render(React.createElement(App, {x = 0}))
		--     jestExpect(Scheduler).toFlushAndYield({
		--         'componentWillReceiveProps',
		--         'shouldComponentUpdate',
		--         'render sibling',
		--     })
		--     ReactNoop.render(React.createElement(App, {x = 1}))
		--     ReactNoop.flushDeferredPri(30)
		--     jestExpect(Scheduler).toHaveYielded({
		--         'componentWillReceiveProps',
		--         'shouldComponentUpdate',
		--         'componentWillUpdate',
		--         'render',
		--         'render sibling',
		--     })
		--     ReactNoop.render(React.createElement(App, {x = 1}))
		--     jestExpect(Scheduler).toFlushWithoutYielding()
		--     jestExpect(Scheduler).toHaveYielded({
		--         'componentWillReceiveProps',
		--         'shouldComponentUpdate',
		--         'render sibling',
		--         'componentDidUpdate',
		--     })
		-- end)
		it("can nest batchedUpdates", function()
			local instance
			local Foo = React.Component:extend("Foo")

			function Foo:render()
				instance = self

				return React.createElement("div", nil)
			end

			ReactNoop.render(React.createElement(Foo, nil))
			jestExpect(Scheduler).toFlushWithoutYielding()
			ReactNoop.flushSync(function()
				ReactNoop.batchedUpdates(function()
					instance:setState({ n = 1 }, function()
						return Scheduler.unstable_yieldValue("setState 1")
					end)
					instance:setState({ n = 2 }, function()
						return Scheduler.unstable_yieldValue("setState 2")
					end)
					ReactNoop.batchedUpdates(function()
						instance:setState({ n = 3 }, function()
							return Scheduler.unstable_yieldValue("setState 3")
						end)
						instance:setState({ n = 4 }, function()
							return Scheduler.unstable_yieldValue("setState 4")
						end)
						Scheduler.unstable_yieldValue("end inner batchedUpdates")
					end)
					Scheduler.unstable_yieldValue("end outer batchedUpdates")
				end)
			end)

			-- ReactNoop.flush() not needed because updates are synchronous

			jestExpect(Scheduler).toHaveYielded({
				"end inner batchedUpdates",
				"end outer batchedUpdates",
				"setState 1",
				"setState 2",
				"setState 3",
				"setState 4",
			})
			jestExpect(instance.state.n).toEqual(4)
		end)

		it("can handle if setState callback throws", function()
			local instance
			local Foo = React.Component:extend("Foo")

			function Foo:init()
				self.state = { n = 0 }
			end

			function Foo:render()
				instance = self
				return React.createElement("div", nil)
			end

			ReactNoop.render(React.createElement(Foo, nil))
			jestExpect(Scheduler).toFlushWithoutYielding()

			local function updater(prevState)
				local n = prevState.n

				return {
					n = n + 1,
				}
			end

			instance:setState(updater, function()
				return Scheduler.unstable_yieldValue("first callback")
			end)
			instance:setState(updater, function()
				Scheduler.unstable_yieldValue("second callback")
				error("callback error")
			end)
			instance:setState(updater, function()
				return Scheduler.unstable_yieldValue("third callback")
			end)
			jestExpect(function()
				jestExpect(Scheduler).toFlushWithoutYielding()
			end).toThrow("callback error")

			-- The third callback isn't called because the second one throws
			jestExpect(Scheduler).toHaveYielded({
				"first callback",
				"second callback",
			})
			jestExpect(instance.state.n).toEqual(3)
		end)

		-- ROBLOX TODO: this test only fails in Studio, debug it once jest TestService is outputting normally again
		itSKIP("merges and masks context", function()
			local Intl = React.Component:extend("Intl")

			function Intl:getChildContext()
				return {
					locale = self.props.locale,
				}
			end
			function Intl:render()
				Scheduler.unstable_yieldValue("Intl " .. JSONStringify(self.context))

				return self.props.children
			end

			-- ROBLOX deviation: PropTypes workaround
			Intl.childContextTypes = {
				locale = "",
			}

			local Router = React.Component:extend("Router")

			function Router:getChildContext()
				return {
					route = self.props.route,
				}
			end
			function Router:render()
				Scheduler.unstable_yieldValue("Router " .. JSONStringify(self.context))

				return self.props.children
			end

			-- ROBLOX deviation: PropTypes workaround
			Router.childContextTypes = {
				route = "",
			}

			local ShowLocale = React.Component:extend("ShowLocale")

			function ShowLocale:render()
				Scheduler.unstable_yieldValue("ShowLocale " .. JSONStringify(self.context))

				return self.context.locale
			end

			-- ROBLOX deviation: PropTypes workaround
			ShowLocale.contextTypes = {
				locale = "",
			}

			local ShowRoute = React.Component:extend("ShowRoute")

			function ShowRoute:render()
				Scheduler.unstable_yieldValue("ShowRoute " .. JSONStringify(self.context))
				return self.context.route
			end

			-- ROBLOX deviation: PropTypes workaround
			ShowRoute.contextTypes = {
				route = "",
			}

			-- ROBLOX TODO: use pure class component so we can attach contextTypes
			local function ShowBoth(props, context)
				Scheduler.unstable_yieldValue("ShowBoth " .. JSONStringify(context))
				-- deviation: cannot set PropTypes for function component in Lua
				context.locale = context.locale or ""
				context.route = context.route or ""

				return ("%s in %s"):format(context.route, context.locale)
			end
			-- ShowBoth.contextTypes = {
			-- 	locale = PropTypes.string,
			-- 	route = PropTypes.string,
			-- }


			local ShowNeither = React.Component:extend("ShowNeither")

			function ShowNeither:render()
				Scheduler.unstable_yieldValue("ShowNeither " .. JSONStringify(self.context))

				return nil
			end

			local Indirection = React.Component:extend("Indirection")

			function Indirection:render()
				Scheduler.unstable_yieldValue("Indirection " .. JSONStringify(self.context))

				return {
					React.createElement(ShowLocale, {
						key = "a",
					}),
					React.createElement(ShowRoute, {
						key = "b",
					}),
					React.createElement(ShowNeither, {
						key = "c",
					}),
					React.createElement(Intl, {
						key = "d",
						locale = "ru",
					}, React.createElement(
						ShowBoth,
						nil
					)),
					React.createElement(ShowBoth, {
						key = "e",
					}),
				}
			end

			ReactNoop.render(React.createElement(
				Intl,
				{
					locale = "fr",
				},
				React.createElement(ShowLocale),
				React.createElement("div", nil, React.createElement(ShowBoth))
			))
			jestExpect(function()
				return jestExpect(Scheduler).toFlushAndYield({
					"Intl {}",
					'ShowLocale {"locale":"fr"}',
					'ShowBoth {"locale":"fr"}',
				})
			end).toErrorDev(
				"Warning: Legacy context API has been detected within a strict-mode tree.\n\n"
					.. "The old API will be supported in all 16.x releases, but applications "
					.. "using it should migrate to the new version.\n\n"
					-- ROBLOX TODO: ShowBoth is missing because we didn't put contextTypes on it, otherwise this is accurate
					-- .. "Please update the following components: Intl, ShowBoth, ShowLocale"
					.. "Please update the following components: Intl, ShowLocale"
			)
			ReactNoop.render(React.createElement(
				Intl,
				{
					locale = "de",
				},
				React.createElement(ShowLocale),
				React.createElement("div", nil, React.createElement(ShowBoth))
			))
			jestExpect(Scheduler).toFlushAndYield({
				"Intl {}",
				'ShowLocale {"locale":"de"}',
				'ShowBoth {"locale":"de"}',
			})
			ReactNoop.render(React.createElement(
				Intl,
				{
					locale = "sv",
				},
				React.createElement(ShowLocale),
				React.createElement("div", nil, React.createElement(ShowBoth))
			))
			jestExpect(Scheduler).toFlushAndYieldThrough({
				"Intl {}",
			})
			ReactNoop.render(React.createElement(
				Intl,
				{
					locale = "en",
				},
				React.createElement(ShowLocale),
				React.createElement(Router, {
					route = "/about",
				}, React.createElement(Indirection)),
				React.createElement(ShowBoth)
			))
			jestExpect(function()
				return jestExpect(Scheduler).toFlushAndYield({
					'ShowLocale {"locale":"sv"}',
					'ShowBoth {"locale":"sv"}',
					"Intl {}",
					'ShowLocale {"locale":"en"}',
					"Router {}",
					"Indirection {}",
					'ShowLocale {"locale":"en"}',
					'ShowRoute {"route":"/about"}',
					"ShowNeither {}",
					"Intl {}",
					-- ROBLOX deviation: JSON results flipped
					'ShowBoth {"route":"/about","locale":"ru"}',
					'ShowBoth {"route":"/about","locale":"en"}',
					'ShowBoth {"locale":"en"}',
				})
			end).toErrorDev(
				"Legacy context API has been detected within a strict-mode tree.\n\n"
					.. "The old API will be supported in all 16.x releases, but applications "
					.. "using it should migrate to the new version.\n\n"
					.. "Please update the following components: Router, ShowRoute"
			)
		end)

		it("does not leak own context into context provider", function()
			local Recurse = React.Component:extend("Recurse")

			function Recurse:getChildContext()
				return {
					n = (self.context.n or 3) - 1,
				}
			end
			function Recurse:render()
				Scheduler.unstable_yieldValue("Recurse " .. JSONStringify(self.context))

				if self.context.n == 0 then
					return nil
				end

				return React.createElement(Recurse)
			end

			-- ROBLOX deviation: placeholder 0 instead of using PropTypes.number
			Recurse.contextTypes = {
				n = 0,
			}
			Recurse.childContextTypes = {
				n = 0,
			}

			ReactNoop.render(React.createElement(Recurse))
			jestExpect(function()
				return jestExpect(Scheduler).toFlushAndYield({
					"Recurse {}",
					'Recurse {"n":2}',
					'Recurse {"n":1}',
					'Recurse {"n":0}',
				})
			end).toErrorDev(
				"Legacy context API has been detected within a strict-mode tree.\n\n"
					.. "The old API will be supported in all 16.x releases, but applications "
					.. "using it should migrate to the new version.\n\n"
					.. "Please update the following components: Recurse"
			)
		end)

		if not ReactFeatureFlags.disableModulePatternComponents then
			-- ROBLOX TODO: PropTypes
			xit("does not leak own context into context provider (factory components)", function()
				local function Recurse(props, context)
					return {
						getChildContext = function()
							return {
								n = (context.n or 3) - 1,
							}
						end,
						render = function()
							Scheduler.unstable_yieldValue("Recurse " .. JSONStringify(context))

							if context.n == 0 then
								return nil
							end

							return React.createElement(Recurse, nil)
						end,
					}
				end
				-- ROBLOX TODO: indexing into function?
				-- Recurse.contextTypes = {
				--     n = PropTypes.number,
				-- }

				-- ROBLOX TODO: indexing into function?
				-- Recurse.childContextTypes = {
				--     n = PropTypes.number,
				-- }

				ReactNoop.render(React.createElement(Recurse, nil))
				jestExpect(function()
					return jestExpect(Scheduler).toFlushAndYield({
						"Recurse {}",
						'Recurse {"n":2}',
						'Recurse {"n":1}',
						'Recurse {"n":0}',
					})
				end).toErrorDev({
					"Warning: The <Recurse /> component appears to be a function component that returns a class instance. " .. "Change Recurse to a class that extends React.Component instead. " .. "If you can't use a class try assigning the prototype on the function as a workaround. " .. "`Recurse.prototype = React.Component.prototype`. " .. "Don't use an arrow function since it cannot be called with `new` by React.",
					"Legacy context API has been detected within a strict-mode tree.\n\n" .. "The old API will be supported in all 16.x releases, but applications " .. "using it should migrate to the new version.\n\n" .. "Please update the following components: Recurse",
				})
			end)
		end

		-- @gate experimental
		it("provides context when reusing work", function()
			local Intl = React.Component:extend("Intl")

			function Intl:getChildContext()
				return {
					locale = self.props.locale,
				}
			end
			function Intl:render()
				Scheduler.unstable_yieldValue("Intl " .. JSONStringify(self.context))

				return self.props.children
			end

			Intl.childContextTypes = {
				-- deviation: PropTypes workaround
				locale = "",
			}

			local ShowLocale = React.Component:extend("ShowLocale")

			function ShowLocale:render()
				Scheduler.unstable_yieldValue("ShowLocale " .. JSONStringify(self.context))

				return self.context.locale
			end

			ShowLocale.contextTypes = {
				-- deviation: PropTypes workaround
				locale = "",
			}

			ReactNoop.render(React.createElement(
				Intl,
				{
					locale = "fr",
				},
				React.createElement(ShowLocale, nil),
				React.createElement(
					LegacyHiddenDiv,
					{
						mode = "hidden",
					},
					React.createElement(ShowLocale, nil),
					React.createElement(Intl, {
							locale = "ru",
						}, React.createElement(ShowLocale, nil))
				),
				React.createElement(ShowLocale, nil)
			))
			jestExpect(Scheduler).toFlushAndYieldThrough({
				"Intl {}",
				'ShowLocale {"locale":"fr"}',
				'ShowLocale {"locale":"fr"}',
			})
			jestExpect(function()
				return jestExpect(Scheduler).toFlushAndYield({
					'ShowLocale {"locale":"fr"}',
					"Intl {}",
					'ShowLocale {"locale":"ru"}',
				})
			end).toErrorDev(
				"Legacy context API has been detected within a strict-mode tree.\n\n"
					.. "The old API will be supported in all 16.x releases, but applications "
					.. "using it should migrate to the new version.\n\n"
					.. "Please update the following components: Intl, ShowLocale"
			)
		end)
		-- ROBLOX TODO: PropTypes
		xit("reads context when setState is below the provider", function()
			local statefulInst
			local Intl = React.Component:extend("Intl")

			function Intl:getChildContext()
				local childContext = {
					locale = self.props.locale,
				}

				Scheduler.unstable_yieldValue("Intl:provide " .. JSONStringify(childContext))

				return childContext
			end
			function Intl:render()
				Scheduler.unstable_yieldValue("Intl:read " .. JSONStringify(self.context))

				return self.props.children
			end

			Intl.childContextTypes = {
				-- deviation: PropTypes workaround
				locale = "",
			}

			local ShowLocaleClass = React.Component:extend("ShowLocaleClass")

			function ShowLocaleClass:render()
				Scheduler.unstable_yieldValue("ShowLocaleClass:read " .. JSONStringify(self.context))

				return self.context.locale
			end

			ShowLocaleClass.contextTypes = {
				-- deviation: PropTypes workaround
				locale = "",
			}

			local function ShowLocaleFn(props, context)
				-- deviation: PropTypes workaround
				context.locale = context.locale or ""
				Scheduler.unstable_yieldValue("ShowLocaleFn:read " .. JSONStringify(context))

				return context.locale
			end

			local Stateful = React.Component:extend("Stateful")

			function Stateful:render()
				statefulInst = self

				return self.props.children
			end

			local function IndirectionFn(props, context)
				Scheduler.unstable_yieldValue("IndirectionFn " .. JSONStringify(context))

				return props.children
			end

			local IndirectionClass = React.Component:extend("IndirectionClass")

			function IndirectionClass:render()
				Scheduler.unstable_yieldValue("IndirectionClass " .. JSONStringify(self.context))

				return self.props.children
			end

			ReactNoop.render(React.createElement(
				Intl,
				{
					locale = "fr",
				},
				React.createElement(
					IndirectionFn,
					nil,
					React.createElement(
						IndirectionClass,
						nil,
						React.createElement(
							Stateful,
							nil,
							React.createElement(ShowLocaleClass, nil),
							React.createElement(ShowLocaleFn, nil)
						)
					)
				)
			))
			jestExpect(function()
				return jestExpect(Scheduler).toFlushAndYield({
					"Intl:read {}",
					'Intl:provide {"locale":"fr"}',
					"IndirectionFn {}",
					"IndirectionClass {}",
					'ShowLocaleClass:read {"locale":"fr"}',
					'ShowLocaleFn:read {"locale":"fr"}',
				})
			end).toErrorDev(
				"Legacy context API has been detected within a strict-mode tree.\n\n"
					.. "The old API will be supported in all 16.x releases, but applications "
					.. "using it should migrate to the new version.\n\n"
					.. "Please update the following components: Intl, ShowLocaleClass, ShowLocaleFn"
			)
			statefulInst:setState({ x = 1 })
			jestExpect(Scheduler).toFlushWithoutYielding()
			-- All work has been memoized because setState()
			-- happened below the context and could not have affected it.
			jestExpect(Scheduler).toHaveYielded({})
		end)
		-- ROBLOX TODO: received[3] (IndirectionFn {"locale":"fr"}) ~= expected[3] (IndirectionFn {})
		-- could be PropsType workaround is causing issues.
		xit("reads context when setState is above the provider", function()
			local statefulInst
			local Intl = React.Component:extend("Intl")

			function Intl:getChildContext()
				local childContext = {
					locale = self.props.locale,
				}

				Scheduler.unstable_yieldValue("Intl:provide " .. JSONStringify(childContext))

				return childContext
			end
			function Intl:render()
				Scheduler.unstable_yieldValue("Intl:read " .. JSONStringify(self.context))

				return self.props.children
			end

			Intl.childContextTypes = {
				-- deviation: PropTypes workaround
				locale = "",
			}

			local ShowLocaleClass = React.Component:extend("ShowLocaleClass")

			function ShowLocaleClass:render()
				Scheduler.unstable_yieldValue("ShowLocaleClass:read " .. JSONStringify(self.context))

				return self.context.locale
			end

			ShowLocaleClass.contextTypes = {
				-- deviation: PropTypes workaround
				locale = "",
			}

			local function ShowLocaleFn(props, context)
				context.locale = context.locale or ""
				Scheduler.unstable_yieldValue("ShowLocaleFn:read " .. JSONStringify(context))

				return context.locale
			end

			-- ROBLOX TODO: indexing into function?
			-- ShowLocaleFn.contextTypes = {
			--     locale = PropTypes.string,
			-- }

			local function IndirectionFn(props, context)
				Scheduler.unstable_yieldValue("IndirectionFn " .. JSONStringify(context))

				return props.children
			end

			local IndirectionClass = React.Component:extend("IndirectionClass")

			function IndirectionClass:render()
				Scheduler.unstable_yieldValue("IndirectionClass " .. JSONStringify(self.context))

				return self.props.children
			end

			local Stateful = React.Component:extend("Stateful")
			function Stateful:init()
				self.state = { locale = "fr" }
			end
			function Stateful:render()
				statefulInst = self

				return React.createElement(Intl, {
					locale = self.state.locale,
				}, self.props.children)
			end

			ReactNoop.render(React.createElement(
				Stateful,
				nil,
				React.createElement(
					IndirectionFn,
					nil,
					React.createElement(
						IndirectionClass,
						nil,
						React.createElement(ShowLocaleClass, nil),
						React.createElement(ShowLocaleFn, nil)
					)
				)
			))
			jestExpect(function()
				return jestExpect(Scheduler).toFlushAndYield({
					"Intl:read {}",
					'Intl:provide {"locale":"fr"}',
					"IndirectionFn {}",
					"IndirectionClass {}",
					'ShowLocaleClass:read {"locale":"fr"}',
					'ShowLocaleFn:read {"locale":"fr"}',
				})
			end).toErrorDev(
				"Legacy context API has been detected within a strict-mode tree.\n\n"
					.. "The old API will be supported in all 16.x releases, but applications "
					.. "using it should migrate to the new version.\n\n"
					.. "Please update the following components: Intl, ShowLocaleClass, ShowLocaleFn"
			)
			statefulInst:setState({
				locale = "gr",
			})
			jestExpect(Scheduler).toFlushAndYield({
				-- Intl is below setState() so it might have been
				-- affected by it. Therefore we re-render and recompute
				-- its child context.
				"Intl:read {}",
				'Intl:provide {"locale":"gr"}',
				-- TODO: it's unfortunate that we can't reuse work on
				-- these components even though they don't depend on context.
				"IndirectionFn {}",
				"IndirectionClass {}",
				-- These components depend on context:
				'ShowLocaleClass:read {"locale":"gr"}',
				'ShowLocaleFn:read {"locale":"gr"}',
			})
		end)
		it("maintains the correct context when providers bail out due to low priority", function()
			-- Child must be a context provider to trigger the bug
			local Child = React.Component:extend("Child")
			function Child:getChildContext()
				return {}
			end
			function Child:render()
				return React.createElement("div", nil)
			end

			local instance
			local Middle = React.Component:extend("Middle")

			function Middle:init(props, context)
				instance = self
			end

			function Middle:shouldComponentUpdate()
				-- Return false so that our child will get a NoWork priority (and get bailed out)
				return false
			end
			function Middle:render()
				return React.createElement(Child, nil)
			end

			local Root = React.Component:extend("Root")

			function Root:render()
				return React.createElement(Middle, self.props)
			end

			Child.childContextTypes = {}

			-- Init
			ReactNoop.render(React.createElement(Root, nil))
			jestExpect(function()
				return jestExpect(Scheduler).toFlushWithoutYielding()
			end).toErrorDev(
				"Legacy context API has been detected within a strict-mode tree.\n\n"
					.. "The old API will be supported in all 16.x releases, but applications "
					.. "using it should migrate to the new version.\n\n"
					.. "Please update the following components: Child"
			)

			-- Trigger an update in the middle of the tree
			instance:setState({})
			jestExpect(Scheduler).toFlushWithoutYielding()
		end)

		it("maintains the correct context when unwinding due to an error in render", function()
			-- ROBLOX deviation: hoist declaration so correct value is captured
			local ContextProvider = React.Component:extend("ContextProvider")
			local Root = React.Component:extend("Root")

			function Root:componentDidCatch(_error)
				-- If context is pushed/popped correctly,
				-- This method will be used to handle the intentionally-thrown Error.
			end

			function Root:render()
				return React.createElement(ContextProvider, { depth = 1 })
			end

			local instance

			function ContextProvider:init(props, context)
				self.state = {}

				if props.depth == 1 then
					instance = self
				end
			end
			ContextProvider.childContextTypes = {}
			function ContextProvider:getChildContext()
				return {}
			end
			function ContextProvider:render()
				if self.state.throwError then
					error(Error.new())
				end

				return (function()
					if self.props.depth < 4 then
						return React.createElement(ContextProvider, {
							depth = self.props.depth + 1,
						})
					end

					return React.createElement(function()
					end)
				end)()
			end

			-- Init
			ReactNoop.render(React.createElement(Root))
			jestExpect(function()
				return jestExpect(Scheduler).toFlushWithoutYielding()
			end).toErrorDev(
				"Legacy context API has been detected within a strict-mode tree.\n\n"
					.. "The old API will be supported in all 16.x releases, but applications "
					.. "using it should migrate to the new version.\n\n"
					.. "Please update the following components: ContextProvider"
			)

			-- Trigger an update in the middle of the tree
			-- This is necessary to reproduce the error as it currently exists.
			instance:setState({ throwError = true })
			jestExpect(function()
				return jestExpect(Scheduler).toFlushWithoutYielding()
			end).toErrorDev("Error boundaries should implement getDerivedStateFromError()")
		end)

		it("should not recreate masked context unless inputs have changed", function()
			local scuCounter = 0
			local MyComponent = React.Component:extend("MyComponent")
			MyComponent.contextTypes = {}

			function MyComponent:componentDidMount(prevProps, prevState)
				Scheduler.unstable_yieldValue("componentDidMount")
				self:setState({ setStateInCDU = true })
			end
			function MyComponent:componentDidUpdate(prevProps, prevState)
				Scheduler.unstable_yieldValue("componentDidUpdate")

				if self.state.setStateInCDU then
					self:setState({ setStateInCDU = false })
				end
			end
			function MyComponent:UNSAFE_componentWillReceiveProps(nextProps)
				Scheduler.unstable_yieldValue("componentWillReceiveProps")
				self:setState({ setStateInCDU = true })
			end
			function MyComponent:render()
				Scheduler.unstable_yieldValue("render")
				return nil
			end
			function MyComponent:shouldComponentUpdate(nextProps, nextState)
				Scheduler.unstable_yieldValue("shouldComponentUpdate")
				-- deviation: can't one line the return with ++ like in JS
				local ret = scuCounter < 5
				scuCounter += 1
				return ret -- Don't let test hang
			end

			ReactNoop.render(React.createElement(MyComponent, nil))
			jestExpect(function()
				return jestExpect(Scheduler).toFlushAndYield({
					"render",
					"componentDidMount",
					"shouldComponentUpdate",
					"render",
					"componentDidUpdate",
					"shouldComponentUpdate",
					"render",
					"componentDidUpdate",
				})
			end).toErrorDev({
				"Using UNSAFE_componentWillReceiveProps in strict mode is not recommended",
				"Legacy context API has been detected within a strict-mode tree.\n\n"
				.. "The old API will be supported in all 16.x releases, but applications "
				.. "using it should migrate to the new version.\n\n"
				.. "Please update the following components: MyComponent",
			}, {
				withoutStack = 1,
			})
		end)
		-- ROBLOX: xited upstream
		-- xit('should reuse memoized work if pointers are updated before calling lifecycles', function()
		--     local cduNextProps = {}
		--     local cduPrevProps = {}
		--     local scuNextProps = {}
		--     local scuPrevProps = {}
		--     local renderCounter = 0

		--     local function SecondChild(props)
		--         return React.createElement('span', nil, props.children)
		--     end

		--     local FirstChild = {}
		--     local FirstChildMetatable = {__index = FirstChild}

		--     function FirstChild:componentDidUpdate(prevProps, prevState)
		--         cduNextProps.push(self.props)
		--         cduPrevProps.push(prevProps)
		--     end
		--     function FirstChild:shouldComponentUpdate(nextProps, nextState)
		--         scuNextProps.push(nextProps)
		--         scuPrevProps.push(self.props)

		--         return self.props.children ~= nextProps.children
		--     end
		--     function FirstChild:render()
		--         renderCounter = renderCounter + 1

		--         return React.createElement('span', nil, self.props.children)
		--     end

		--     local Middle = {}
		--     local MiddleMetatable = {__index = Middle}

		--     function Middle:render()
		--         return React.createElement('div', nil, React.createElement(FirstChild, nil, self.props.children), React.createElement(SecondChild, nil, self.props.children))
		--     end

		--     local function Root(props)
		--         return React.createElement('div', {hidden = true}, React.createElement(Middle, props))
		--     end

		--     ReactNoop.render(React.createElement(Root, nil, 'A'))
		--     jestExpect(Scheduler).toFlushWithoutYielding()
		--     jestExpect(renderCounter).toBe(1)
		--     ReactNoop.render(React.createElement(Root, nil, 'B'))
		--     ReactNoop.flushDeferredPri(20 + 30 + 5)
		--     jestExpect(renderCounter).toBe(2)
		--     jestExpect(scuPrevProps).toEqual({
		--         {
		--             children = 'A',
		--         },
		--     })
		--     jestExpect(scuNextProps).toEqual({
		--         {
		--             children = 'B',
		--         },
		--     })
		--     jestExpect(cduPrevProps).toEqual({})
		--     jestExpect(cduNextProps).toEqual({})
		--     ReactNoop.render(React.createElement(Root, nil, 'B'))
		--     jestExpect(Scheduler).toFlushWithoutYielding()
		--     jestExpect(renderCounter).toBe(2)
		--     jestExpect(scuPrevProps).toEqual({
		--         {
		--             children = 'A',
		--         },
		--         {
		--             children = 'B',
		--         },
		--     })
		--     jestExpect(scuNextProps).toEqual({
		--         {
		--             children = 'B',
		--         },
		--         {
		--             children = 'B',
		--         },
		--     })
		--     jestExpect(cduPrevProps).toEqual({
		--         {
		--             children = 'A',
		--         },
		--     })
		--     jestExpect(cduNextProps).toEqual({
		--         {
		--             children = 'B',
		--         },
		--     })
		-- end)
		-- ROBLOX TODO: PropTypes
		xit("updates descendants with new context values", function()
			local instance
			local TopContextProvider = React.Component:extend("TopContextProvider")

			function TopContextProvider:init()
				self.getChildContext = function()
					return {
						count = self.state.count,
					}
				end
				self.render = function()
					return self.props.children
				end
				self.updateCount = function()
					return self:setState(function(state)
						return {
							count = state.count + 1,
						}
					end)
				end
				self.state = { count = 0 }
				instance = self
			end

			TopContextProvider.childContextTypes = {
				count = PropTypes.number,
			}

			local Middle = React.Component:extend("Middle")

			local Child = React.Component:extend("Child")

			Child.contextTypes = {
				count = PropTypes.number,
			}

			ReactNoop.render(React.createElement(
				TopContextProvider,
				nil,
				React.createElement(Middle, nil, React.createElement(Child, nil))
			))
			jestExpect(function()
				return jestExpect(Scheduler).toFlushAndYield({
					"count:0",
				})
			end).toErrorDev(
				"Legacy context API has been detected within a strict-mode tree.\n\n"
					.. "The old API will be supported in all 16.x releases, but applications "
					.. "using it should migrate to the new version.\n\n"
					.. "Please update the following components: Child, TopContextProvider"
			)
			instance.updateCount()
			jestExpect(Scheduler).toFlushAndYield({
				"count:1",
			})
		end)
		-- ROBLOX TODO: PropTypes
		xit("updates descendants with multiple context-providing ancestors with new context values", function()
			local instance
			local TopContextProvider = React.Component:extend("TopContextProvider")

			function TopContextProvider:init()
				self.getChildContext = function()
					return {
						count = self.state.count,
					}
				end
				self.render = function()
					return self.props.children
				end
				self.updateCount = function()
					return self:setState(function(state)
						return {
							count = state.count + 1,
						}
					end)
				end
				self.state = { count = 0 }
				instance = self
			end

			TopContextProvider.childContextTypes = {
				count = PropTypes.number,
			}

			local MiddleContextProvider = React.Component:extend("MiddleContextProvider")

			MiddleContextProvider.childContextTypes = {
				name = PropTypes.string,
			}

			local Child = React.Component:extend("Child")

			Child.contextTypes = {
				count = PropTypes.number,
			}

			ReactNoop.render(React.createElement(
				TopContextProvider,
				nil,
				React.createElement(MiddleContextProvider, nil, React.createElement(Child, nil))
			))
			jestExpect(function()
				return jestExpect(Scheduler).toFlushAndYield({
					"count:0",
				})
			end).toErrorDev(
				"Legacy context API has been detected within a strict-mode tree.\n\n"
					.. "The old API will be supported in all 16.x releases, but applications "
					.. "using it should migrate to the new version.\n\n"
					.. "Please update the following components: Child, MiddleContextProvider, TopContextProvider"
			)
			instance.updateCount()
			jestExpect(Scheduler).toFlushAndYield({
				"count:1",
			})
		end)
		-- ROBLOX TODO: PropTypes
		xit("should not update descendants with new context values if shouldComponentUpdate returns false", function()
			local instance
			local TopContextProvider = React.Component:extend("TopContextProvider")

			function TopContextProvider:init()
				self.getChildContext = function()
					return {
						count = self.state.count,
					}
				end
				self.render = function()
					return self.props.children
				end
				self.updateCount = function()
					return self:setState(function(state)
						return {
							count = state.count + 1,
						}
					end)
				end
				self.state = { count = 0 }
				instance = self
			end

			TopContextProvider.childContextTypes = {
				count = PropTypes.number,
			}

			local MiddleScu = React.Component:extend("MiddleScu")

			function MiddleScu:shouldComponentUpdate()
				return false
			end

			local MiddleContextProvider = React.Component:extend("MiddleContextProvider")

			MiddleContextProvider.childContextTypes = {
				name = PropTypes.string,
			}

			local Child = React.Component:extend("Child")

			Child.contextTypes = {
				count = PropTypes.number,
			}

			ReactNoop.render(React.createElement(
				TopContextProvider,
				nil,
				React.createElement(
					MiddleScu,
					nil,
					React.createElement(MiddleContextProvider, nil, React.createElement(Child, nil))
				)
			))
			jestExpect(function()
				return jestExpect(Scheduler).toFlushAndYield({
					"count:0",
				})
			end).toErrorDev(
				"Legacy context API has been detected within a strict-mode tree.\n\n"
					.. "The old API will be supported in all 16.x releases, but applications "
					.. "using it should migrate to the new version.\n\n"
					.. "Please update the following components: Child, MiddleContextProvider, TopContextProvider"
			)
			instance.updateCount()
			jestExpect(Scheduler).toFlushWithoutYielding()
		end)
		-- ROBLOX TODO: PropTypes
		xit(
			"should update descendants with new context values if setState() is called in the middle of the tree",
			function()
				local middleInstance
				local topInstance
				local TopContextProvider = React.Component:extend("TopContextProvider")

				function TopContextProvider:init()
					self.getChildContext = function()
						return {
							count = self.state.count,
						}
					end
					self.render = function()
						return self.props.children
					end
					self.updateCount = function()
						return self:setState(function(state)
							return {
								count = state.count + 1,
							}
						end)
					end
					self.state = { count = 0 }
					topInstance = self
				end

				TopContextProvider.childContextTypes = {
					count = PropTypes.number,
				}

				local MiddleScu = React.Component:extend("MiddleScu")

				function MiddleScu:shouldComponentUpdate()
					return false
				end

				local MiddleContextProvider = React.Component:extend("MiddleContextProvider")

				function MiddleContextProvider:init()
					self.getChildContext = function()
						return {
							name = self.state.name,
						}
					end
					self.updateName = function(name)
						self:setState({ name = name })
					end
					self.render = function()
						return self.props.children
					end
					self.state = {
						name = "brian",
					}
					middleInstance = self
				end

				MiddleContextProvider.childContextTypes = {
					name = PropTypes.string,
				}

				local Child = React.Component:extend("Child")

				Child.contextTypes = {
					count = PropTypes.number,
					name = PropTypes.string,
				}

				ReactNoop.render(React.createElement(
					TopContextProvider,
					nil,
					React.createElement(
						MiddleScu,
						nil,
						React.createElement(MiddleContextProvider, nil, React.createElement(Child, nil))
					)
				))
				jestExpect(function()
					return jestExpect(Scheduler).toFlushAndYield({
						"count:0, name:brian",
					})
				end).toErrorDev(
					"Legacy context API has been detected within a strict-mode tree.\n\n"
						.. "The old API will be supported in all 16.x releases, but applications "
						.. "using it should migrate to the new version.\n\n"
						.. "Please update the following components: Child, MiddleContextProvider, TopContextProvider"
				)
				topInstance.updateCount()
				jestExpect(Scheduler).toFlushWithoutYielding()
				middleInstance.updateName("not brian")
				jestExpect(Scheduler).toFlushAndYield({
					"count:1, name:not brian",
				})
			end
		)
		it("does not interrupt for update at same priority", function()
			local function Child(props)
				Scheduler.unstable_yieldValue("Child: " .. tostring(props.step))
				return nil
			end

			local function Parent(props)
				Scheduler.unstable_yieldValue("Parent: " .. tostring(props.step))

				return React.createElement(Child, {
					step = props.step,
				})
			end

			ReactNoop.render(React.createElement(Parent, { step = 1 }))
			jestExpect(Scheduler).toFlushAndYieldThrough({
				"Parent: 1",
			})
			ReactNoop.render(React.createElement(Parent, { step = 2 }))
			jestExpect(Scheduler).toFlushAndYield({
				"Child: 1",
				"Parent: 2",
				"Child: 2",
			})
		end)
		it("does not interrupt for update at lower priority", function()
			local function Child(props)
				Scheduler.unstable_yieldValue("Child: " .. tostring(props.step))

				return nil
			end

			local function Parent(props)
				Scheduler.unstable_yieldValue("Parent: " .. tostring(props.step))

				return React.createElement(Child, {
					step = props.step,
				})
			end

			ReactNoop.render(React.createElement(Parent, { step = 1 }))
			jestExpect(Scheduler).toFlushAndYieldThrough({
				"Parent: 1",
			})

			-- Interrupt at lower priority
			ReactNoop.expire(2000)
			ReactNoop.render(React.createElement(Parent, { step = 2 }))
			jestExpect(Scheduler).toFlushAndYield({
				"Child: 1",
				"Parent: 2",
				"Child: 2",
			})
		end)
		it("does interrupt for update at higher priority", function()
			local function Child(props)
				Scheduler.unstable_yieldValue("Child: " .. tostring(props.step))
				return nil
			end

			local function Parent(props)
				Scheduler.unstable_yieldValue("Parent: " .. tostring(props.step))

				return React.createElement(Child, {
					step = props.step,
				})
			end

			ReactNoop.render(React.createElement(Parent, { step = 1 }))
			jestExpect(Scheduler).toFlushAndYieldThrough({
				"Parent: 1",
			})

			-- Interrupt at higher priority
			ReactNoop.flushSync(function()
				return ReactNoop.render(React.createElement(Parent, { step = 2 }))
			end)
			jestExpect(Scheduler).toHaveYielded({
				"Parent: 2",
				"Child: 2",
			})
			jestExpect(Scheduler).toFlushAndYield({})
		end)

		-- ROBLOX TODO: sort out default map.set reassignment.
		-- We sometimes use Maps with Fibers as keys.
		-- xit('does not break with a bad Map polyfill', function()
		--     --     local realMapSet = Map.prototype.set

		--     local function triggerCodePathThatUsesFibersAsMapKeys()
		--         local function Thing()
		--             error('No.')
		--         end -- This class uses legacy context, which triggers warnings,
		--         -- the procedures for which use a Map to store fibers.
		--         local Boundary = React.Component:extend("Boundary")

		--         function Boundary:componentDidCatch()
		--             self:setState({didError = true})
		--         end
		--         function Boundary:render()
		--             return(function()
		--                 if self.state.didError then
		--                     return nil
		--                 end

		--                 return React.createElement(Thing, nil)
		--             end)
		--         end

		--         Boundary.contextTypes = {
		--             color = function()
		--                 return nil
		--             end,
		--         }

		--         ReactNoop.render(React.createElement(Boundary, nil))
		--         jestExpect(function()
		--             jestExpect(Scheduler).toFlushWithoutYielding()
		--         end).toErrorDev({
		--             'Legacy context API has been detected within a strict-mode tree',
		--         })
		--     end
		--     -- First, verify that this code path normally receives Fibers as keys,
		--     -- and that they're not extensible.
		--     RobloxJest.resetModules()

		--     local receivedNonExtensibleObjects -- eslint-disable-next-line no-extend-native

		--     Map.prototype.set = function(key)
		--         if typeof(key) == 'object' and key ~= nil then
		--             if not Object.isExtensible(key) then
		--                 receivedNonExtensibleObjects = true
		--             end
		--         end

		--         return realMapSet.apply(self, arguments)
		--     end
		--     React = require('react')
		--     ReactNoop = require('react-noop-renderer')
		--     Scheduler = require('scheduler')

		--     jestExpect(receivedNonExtensibleObjects).toBe(__DEV__)
		--     jest.resetModules()

		--     Map.prototype.set = function(key, value)
		--         if typeof(key) == 'object' and key ~= nil then
		--             key.__internalValueSlot = value
		--         end

		--         return realMapSet.apply(self, arguments)
		--     end
		--     React = require('react')
		--     ReactNoop = require('react-noop-renderer')
		--     Scheduler = require('scheduler')
		-- end)
	end)
end
