-- ROBLOX upstream: https://github.com/facebook/react/blob/702fad4b1b48ac8f626ed3f35e8f86f5ea728084/packages/react-dom/src/__tests__/ReactDOMFiber-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 ]]

-- 'use strict'
local Packages = script.Parent.Parent.Parent.Parent

local React
local ReactRoblox
local reactRobloxRoot
local Scheduler
local parent
-- local PropTypes = require('prop-types')

-- local container
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local jest = JestGlobals.jest
local beforeEach = JestGlobals.beforeEach
local it = JestGlobals.it
local xit = JestGlobals.xit

beforeEach(function()
	-- ROBLOX DEVIATION: Document logic does not apply to Roblox
	-- container = document.createElement('div')
	-- document.body.appendChild(container)
	jest.resetModules()
	jest.useFakeTimers()
	React = require(Packages.React)
	ReactRoblox = require(Packages.ReactRoblox)
	parent = Instance.new("Folder")
	reactRobloxRoot = ReactRoblox.createRoot(parent)
	Scheduler = require(Packages.Scheduler)
end)

-- ROBLOX DEVIATION: Document logic does not apply to Roblox
-- afterEach(function()
--   document.body.removeChild(container)
--   container = nil
-- end)

-- it('should render strings as children', () => {
--   local Box = ({value}) => <div>{value}</div>

--   ReactDOM.render(<Box value="foo" />, container)
--   expect(container.textContent).toEqual('foo')
-- })

-- it('should render numbers as children', () => {
--   local Box = ({value}) => <div>{value}</div>

--   ReactDOM.render(<Box value={10} />, container)

--   expect(container.textContent).toEqual('10')
-- })

-- it('should be called a callback argument', () => {
--   -- mounting phase
--   local called = false
--   ReactDOM.render(<div>Foo</div>, container, () => (called = true))
--   expect(called).toEqual(true)

--   -- updating phase
--   called = false
--   ReactDOM.render(<div>Foo</div>, container, () => (called = true))
--   expect(called).toEqual(true)
-- })

-- it('should call a callback argument when the same element is re-rendered', () => {
--   class Foo extends React.Component {
--     render()
--       return <div>Foo</div>
--     }
--   }
--   local element = <Foo />

--   -- mounting phase
--   local called = false
--   ReactDOM.render(element, container, () => (called = true))
--   expect(called).toEqual(true)

--   -- updating phase
--   called = false
--   ReactDOM.unstable_batchedUpdates(() => {
--     ReactDOM.render(element, container, () => (called = true))
--   })
--   expect(called).toEqual(true)
-- })

-- it('should render a component returning strings directly from render', () => {
--   local Text = ({value}) => value

--   ReactDOM.render(<Text value="foo" />, container)
--   expect(container.textContent).toEqual('foo')
-- })

-- it('should render a component returning numbers directly from render', () => {
--   local Text = ({value}) => value

--   ReactDOM.render(<Text value={10} />, container)

--   expect(container.textContent).toEqual('10')
-- })

-- it('finds the DOM Text node of a string child', () => {
--   class Text extends React.Component {
--     render()
--       return this.props.value
--     }
--   }

--   local instance = nil
--   ReactDOM.render(
--     <Text value="foo" ref={ref => (instance = ref)} />,
--     container,
--   )

--   local textNode = ReactDOM.findDOMNode(instance)
--   expect(textNode).toBe(container.firstChild)
--   expect(textNode.nodeType).toBe(3)
--   expect(textNode.nodeValue).toBe('foo')
-- })

-- it('finds the first child when a component returns a fragment', () => {
--   class Fragment extends React.Component {
--     render()
--       return [<div key="a" />, <span key="b" />]
--     }
--   }

--   local instance = nil
--   ReactDOM.render(<Fragment ref={ref => (instance = ref)} />, container)

--   expect(container.childNodes.length).toBe(2)

--   local firstNode = ReactDOM.findDOMNode(instance)
--   expect(firstNode).toBe(container.firstChild)
--   expect(firstNode.tagName).toBe('DIV')
-- })

-- it('finds the first child even when fragment is nested', () => {
--   class Wrapper extends React.Component {
--     render()
--       return this.props.children
--     }
--   }

--   class Fragment extends React.Component {
--     render()
--       return [
--         <Wrapper key="a">
--           <div />
--         </Wrapper>,
--         <span key="b" />,
--       ]
--     }
--   }

--   local instance = nil
--   ReactDOM.render(<Fragment ref={ref => (instance = ref)} />, container)

--   expect(container.childNodes.length).toBe(2)

--   local firstNode = ReactDOM.findDOMNode(instance)
--   expect(firstNode).toBe(container.firstChild)
--   expect(firstNode.tagName).toBe('DIV')
-- })

-- it('finds the first child even when first child renders nil', () => {
--   class NullComponent extends React.Component {
--     render()
--       return nil
--     }
--   }

--   class Fragment extends React.Component {
--     render()
--       return [<NullComponent key="a" />, <div key="b" />, <span key="c" />]
--     }
--   }

--   local instance = nil
--   ReactDOM.render(<Fragment ref={ref => (instance = ref)} />, container)

--   expect(container.childNodes.length).toBe(2)

--   local firstNode = ReactDOM.findDOMNode(instance)
--   expect(firstNode).toBe(container.firstChild)
--   expect(firstNode.tagName).toBe('DIV')
-- })

-- it('renders an empty fragment', () => {
--   local Div = () => <div />
--   local EmptyFragment = () => <></>
--   local NonEmptyFragment = () => (
--     <>
--       <Div />
--     </>
--   )

--   ReactDOM.render(<EmptyFragment />, container)
--   expect(container.firstChild).toBe(null)

--   ReactDOM.render(<NonEmptyFragment />, container)
--   expect(container.firstChild.tagName).toBe('DIV')

--   ReactDOM.render(<EmptyFragment />, container)
--   expect(container.firstChild).toBe(null)

--   ReactDOM.render(<Div />, container)
--   expect(container.firstChild.tagName).toBe('DIV')

--   ReactDOM.render(<EmptyFragment />, container)
--   expect(container.firstChild).toBe(null)
-- })

-- local svgEls, htmlEls, mathEls
-- local expectSVG = {ref: el => svgEls.push(el)}
-- local expectHTML = {ref: el => htmlEls.push(el)}
-- local expectMath = {ref: el => mathEls.push(el)}

-- local usePortal = function(tree)
--   return ReactDOM.createPortal(tree, document.createElement('div'))
-- }

-- local assertNamespacesMatch = function(tree)
--   local testContainer = document.createElement('div')
--   svgEls = []
--   htmlEls = []
--   mathEls = []

--   ReactDOM.render(tree, testContainer)
--   svgEls.forEach(el => {
--     expect(el.namespaceURI).toBe('http://www.w3.org/2000/svg')
--   })
--   htmlEls.forEach(el => {
--     expect(el.namespaceURI).toBe('http://www.w3.org/1999/xhtml')
--   })
--   mathEls.forEach(el => {
--     expect(el.namespaceURI).toBe('http://www.w3.org/1998/Math/MathML')
--   })

--   ReactDOM.unmountComponentAtNode(testContainer)
--   expect(testContainer.innerHTML).toBe('')
-- }

it("should render one portal", function()
	local portalContainer = Instance.new("Frame")

	reactRobloxRoot:render(
		React.createElement(
			"Frame",
			{},
			ReactRoblox.createPortal(
				React.createElement("TextLabel", { Text = "portal" }),
				portalContainer
			)
		)
	)
	Scheduler.unstable_flushAllWithoutAsserting()

	local children = portalContainer:GetChildren()

	jestExpect(#children).toBe(1)
	jestExpect(children[1].ClassName).toBe("TextLabel")
	jestExpect(children[1].Text).toBe("portal")

	reactRobloxRoot:unmount()
	Scheduler.unstable_flushAllWithoutAsserting()

	children = portalContainer:GetChildren()

	jestExpect(#children).toBe(0)
end)

-- ROBLOX DEVIATION: unstable_createPortal is not implemented in Roblox
-- -- TODO: remove in React 18
-- if !__EXPERIMENTAL__)
--   it('should support unstable_createPortal alias', () => {
--     local portalContainer = document.createElement('div')

--     expect(() =>
--       ReactDOM.render(
--         <div>
--           {ReactDOM.unstable_createPortal(<div>portal</div>, portalContainer)}
--         </div>,
--         container,
--       ),
--     ).toWarnDev(
--       'The ReactDOM.unstable_createPortal() alias has been deprecated, ' +
--         'and will be removed in React 18+. Update your code to use ' +
--         'ReactDOM.createPortal() instead. It has the exact same API, ' +
--         'but without the "unstable_" prefix.',
--       {withoutStack: true},
--     )
--     expect(portalContainer.innerHTML).toBe('<div>portal</div>')
--     expect(container.innerHTML).toBe('<div></div>')

--     ReactDOM.unmountComponentAtNode(container)
--     expect(portalContainer.innerHTML).toBe('')
--     expect(container.innerHTML).toBe('')
--   })
-- }

it("should render many portals", function()
	local portalContainer1 = Instance.new("Frame")
	local portalContainer2 = Instance.new("Frame")

	local ops = {}

	local Child = React.Component:extend("Child")

	function Child:componentDidMount()
		ops[#ops + 1] = self.props.name .. " componentDidMount"
	end

	function Child:componentDidUpdate()
		ops[#ops + 1] = self.props.name .. " componentDidUpdate"
	end

	function Child:componentWillUnmount()
		ops[#ops + 1] = self.props.name .. " componentWillUnmount"
	end

	function Child:render()
		return React.createElement("TextLabel", { Text = self.props.name })
	end

	local Parent = React.Component:extend("Parent")

	function Parent:componentDidMount()
		ops[#ops + 1] = "Parent:" .. self.props.step .. " componentDidMount"
	end

	function Parent:componentDidUpdate()
		ops[#ops + 1] = "Parent:" .. self.props.step .. " componentDidUpdate"
	end

	function Parent:componentWillUnmount()
		ops[#ops + 1] = "Parent:" .. self.props.step .. " componentWillUnmount"
	end

	function Parent:render()
		local step = self.props.step
		return {
			React.createElement(Child, {
				key = "a",
				name = "normal[0]:" .. step,
			}),
			ReactRoblox.createPortal(
				React.createElement(Child, {
					key = "b",
					name = "portal1[0]:" .. step,
				}),
				portalContainer1
			),
			React.createElement(Child, {
				key = "c",
				name = "normal[1]:" .. step,
			}),
			ReactRoblox.createPortal({
				React.createElement(Child, {
					key = "d",
					name = "portal2[0]:" .. step,
				}),
				React.createElement(Child, {
					key = "e",
					name = "portal2[1]:" .. step,
				}),
			}, portalContainer2),
		}
	end

	reactRobloxRoot:render(React.createElement(Parent, { step = "a" }))

	Scheduler.unstable_flushAllWithoutAsserting()

	local children1 = portalContainer1:GetChildren()
	jestExpect(#children1).toBe(1)
	jestExpect(children1[1].ClassName).toBe("TextLabel")
	jestExpect(children1[1].Text).toBe("portal1[0]:a")

	local children2 = portalContainer2:GetChildren()
	jestExpect(#children2).toBe(2)
	jestExpect(children2[1].ClassName).toBe("TextLabel")
	jestExpect(children2[1].Text).toBe("portal2[0]:a")
	jestExpect(children2[2].ClassName).toBe("TextLabel")
	jestExpect(children2[2].Text).toBe("portal2[1]:a")

	local childrenParent = parent:GetChildren()
	jestExpect(#childrenParent).toBe(2)
	jestExpect(childrenParent[1].ClassName).toBe("TextLabel")
	jestExpect(childrenParent[1].Text).toBe("normal[0]:a")
	jestExpect(childrenParent[2].ClassName).toBe("TextLabel")
	jestExpect(childrenParent[2].Text).toBe("normal[1]:a")

	jestExpect(ops).toEqual({
		"normal[0]:a componentDidMount",
		"portal1[0]:a componentDidMount",
		"normal[1]:a componentDidMount",
		"portal2[0]:a componentDidMount",
		"portal2[1]:a componentDidMount",
		"Parent:a componentDidMount",
	})

	ops = {}

	reactRobloxRoot:render(React.createElement(Parent, { step = "b" }))

	Scheduler.unstable_flushAllWithoutAsserting()

	children1 = portalContainer1:GetChildren()
	jestExpect(#children1).toBe(1)
	jestExpect(children1[1].ClassName).toBe("TextLabel")
	jestExpect(children1[1].Text).toBe("portal1[0]:b")

	children2 = portalContainer2:GetChildren()
	jestExpect(#children2).toBe(2)
	jestExpect(children2[1].ClassName).toBe("TextLabel")
	jestExpect(children2[1].Text).toBe("portal2[0]:b")
	jestExpect(children2[2].ClassName).toBe("TextLabel")
	jestExpect(children2[2].Text).toBe("portal2[1]:b")

	childrenParent = parent:GetChildren()
	jestExpect(#childrenParent).toBe(2)
	jestExpect(childrenParent[1].ClassName).toBe("TextLabel")
	jestExpect(childrenParent[1].Text).toBe("normal[0]:b")
	jestExpect(childrenParent[2].ClassName).toBe("TextLabel")
	jestExpect(childrenParent[2].Text).toBe("normal[1]:b")

	jestExpect(ops).toEqual({
		"normal[0]:b componentDidUpdate",
		"portal1[0]:b componentDidUpdate",
		"normal[1]:b componentDidUpdate",
		"portal2[0]:b componentDidUpdate",
		"portal2[1]:b componentDidUpdate",
		"Parent:b componentDidUpdate",
	})

	ops = {}

	reactRobloxRoot:unmount()
	Scheduler.unstable_flushAllWithoutAsserting()

	children1 = portalContainer1:GetChildren()
	jestExpect(#children1).toBe(0)

	children2 = portalContainer2:GetChildren()
	jestExpect(#children2).toBe(0)

	childrenParent = parent:GetChildren()
	jestExpect(#childrenParent).toBe(0)

	jestExpect(ops).toEqual({
		"Parent:b componentWillUnmount",
		"normal[0]:b componentWillUnmount",
		"portal1[0]:b componentWillUnmount",
		"normal[1]:b componentWillUnmount",
		"portal2[0]:b componentWillUnmount",
		"portal2[1]:b componentWillUnmount",
	})
end)

it("should render nested portals", function()
	local portalContainer1 = Instance.new("Frame")
	local portalContainer2 = Instance.new("Frame")
	local portalContainer3 = Instance.new("Frame")

	reactRobloxRoot:render({
		React.createElement("TextLabel", { key = "a", Text = "normal[0]" }),
		ReactRoblox.createPortal({
			React.createElement("TextLabel", { key = "b", Text = "portal1[0]" }),
			ReactRoblox.createPortal(
				React.createElement("TextLabel", { key = "c", Text = "portal2[0]" }),
				portalContainer2
			),
			ReactRoblox.createPortal(
				React.createElement("TextLabel", { key = "d", Text = "portal3[0]" }),
				portalContainer3
			),
			React.createElement("TextLabel", { key = "e", Text = "portal1[1]" }),
		}, portalContainer1),
		React.createElement("TextLabel", { key = "f", Text = "normal[1]" }),
	})

	Scheduler.unstable_flushAllWithoutAsserting()

	local children1 = portalContainer1:GetChildren()
	jestExpect(#children1).toBe(2)
	jestExpect(children1[1].Text).toBe("portal1[0]")
	jestExpect(children1[2].Text).toBe("portal1[1]")

	local children2 = portalContainer2:GetChildren()
	jestExpect(#children2).toBe(1)
	jestExpect(children2[1].Text).toBe("portal2[0]")

	local children3 = portalContainer3:GetChildren()
	jestExpect(#children3).toBe(1)
	jestExpect(children3[1].Text).toBe("portal3[0]")

	local childrenParent = parent:GetChildren()
	jestExpect(#childrenParent).toBe(2)
	jestExpect(childrenParent[1].Text).toBe("normal[0]")
	jestExpect(childrenParent[2].Text).toBe("normal[1]")

	reactRobloxRoot:unmount()

	Scheduler.unstable_flushAllWithoutAsserting()

	jestExpect(#portalContainer1:GetChildren()).toBe(0)
	jestExpect(#portalContainer2:GetChildren()).toBe(0)
	jestExpect(#portalContainer3:GetChildren()).toBe(0)
	jestExpect(#parent:GetChildren()).toBe(0)
end)

it("should reconcile portal children", function()
	local portalContainer = Instance.new("Frame")

	reactRobloxRoot:render(React.createElement("Frame", {}, {
		ReactRoblox.createPortal(
			React.createElement("TextLabel", { Text = "portal:1" }),
			portalContainer
		),
	}))

	Scheduler.unstable_flushAllWithoutAsserting()
	jestExpect(#portalContainer:GetChildren()).toBe(1)
	jestExpect(portalContainer:GetChildren()[1].Text).toBe("portal:1")
	jestExpect(#parent:GetChildren()).toBe(1)
	jestExpect(#parent:GetChildren()[1]:GetChildren()).toBe(0)

	reactRobloxRoot:render(React.createElement("Frame", {}, {
		ReactRoblox.createPortal(
			React.createElement("TextLabel", { Text = "portal:2" }),
			portalContainer
		),
	}))

	Scheduler.unstable_flushAllWithoutAsserting()
	jestExpect(#portalContainer:GetChildren()).toBe(1)
	jestExpect(portalContainer:GetChildren()[1].Text).toBe("portal:2")
	jestExpect(#parent:GetChildren()).toBe(1)
	jestExpect(#parent:GetChildren()[1]:GetChildren()).toBe(0)

	reactRobloxRoot:render(React.createElement("Frame", {}, {
		ReactRoblox.createPortal(
			React.createElement("TextLabel", { Text = "portal:3" }),
			portalContainer
		),
	}))

	Scheduler.unstable_flushAllWithoutAsserting()
	jestExpect(#portalContainer:GetChildren()).toBe(1)
	jestExpect(portalContainer:GetChildren()[1].Text).toBe("portal:3")
	jestExpect(#parent:GetChildren()).toBe(1)
	jestExpect(#parent:GetChildren()[1]:GetChildren()).toBe(0)

	reactRobloxRoot:render(React.createElement(
		"Frame",
		{},
		ReactRoblox.createPortal({
			-- ROBLOX deviation START: upstream uses text children, which are
			-- exempt from key warnings, but we get them if we don't provide keys
			React.createElement("TextLabel", { key = "1", Text = "Hi" }),
			React.createElement("TextLabel", { key = "2", Text = "Bye" }),
			-- ROBLOX deviation END
		}, portalContainer)
	))

	Scheduler.unstable_flushAllWithoutAsserting()
	jestExpect(#portalContainer:GetChildren()).toBe(2)
	jestExpect(portalContainer:GetChildren()[1].Text).toBe("Hi")
	jestExpect(portalContainer:GetChildren()[2].Text).toBe("Bye")
	jestExpect(#parent:GetChildren()).toBe(1)
	jestExpect(#parent:GetChildren()[1]:GetChildren()).toBe(0)

	reactRobloxRoot:render(React.createElement(
		"Frame",
		{},
		ReactRoblox.createPortal({
			-- ROBLOX deviation START: upstream uses text children, which are
			-- exempt from key warnings, but we get them if we don't provide keys
			React.createElement("TextLabel", { key = "1", Text = "Bye" }),
			React.createElement("TextLabel", { key = "2", Text = "Hi" }),
			-- ROBLOX deviation END
		}, portalContainer)
	))

	Scheduler.unstable_flushAllWithoutAsserting()
	jestExpect(#portalContainer:GetChildren()).toBe(2)
	jestExpect(portalContainer:GetChildren()[1].Text).toBe("Bye")
	jestExpect(portalContainer:GetChildren()[2].Text).toBe("Hi")
	jestExpect(#parent:GetChildren()).toBe(1)
	jestExpect(#parent:GetChildren()[1]:GetChildren()).toBe(0)

	reactRobloxRoot:render(
		React.createElement("Frame", {}, ReactRoblox.createPortal(nil, portalContainer))
	)

	Scheduler.unstable_flushAllWithoutAsserting()
	jestExpect(#portalContainer:GetChildren()).toBe(0)
	jestExpect(#parent:GetChildren()).toBe(1)
	jestExpect(#parent:GetChildren()[1]:GetChildren()).toBe(0)
end)

it("should unmount empty portal component wherever it appears", function()
	local portalContainer = Instance.new("Frame")

	local capturedState
	local capturedSetState

	local Wrapper = React.Component:extend("Wrapper")
	function Wrapper:init()
		self:setState({
			show = true,
		})
	end

	function Wrapper:render()
		capturedState = self.state
		capturedSetState = function(...)
			self:setState(...)
		end

		return React.createElement(
			"Frame",
			{},
			self.state.show
				and React.createElement(
					React.Fragment,
					nil,
					ReactRoblox.createPortal(nil, portalContainer),
					React.createElement("TextLabel", { Text = "child" })
				),
			React.createElement("TextLabel", { Text = "parent" })
		)
	end

	reactRobloxRoot:render(React.createElement(Wrapper))
	Scheduler.unstable_flushAllWithoutAsserting()

	jestExpect(#parent:GetChildren()).toBe(1)

	local children = parent:GetChildren()[1]:GetChildren()
	jestExpect(#children).toBe(2)
	jestExpect(children[1].Text).toBe("child")
	jestExpect(children[2].Text).toBe("parent")

	capturedSetState({ show = false })
	Scheduler.unstable_flushAllWithoutAsserting()
	jestExpect(capturedState.show).toBe(false)
	jestExpect(#parent:GetChildren()).toBe(1)

	children = parent:GetChildren()[1]:GetChildren()
	jestExpect(#children).toBe(1)
	jestExpect(children[1].Text).toBe("parent")
end)

-- ROBLOX DEVIATION: Roblox does not have the same concept of namespaces as upstream React
-- it('should keep track of namespace across portals (simple)', () => {
--   assertNamespacesMatch(
--     <svg {...expectSVG}>
--       <image {...expectSVG} />
--       {usePortal(<div {...expectHTML} />)}
--       <image {...expectSVG} />
--     </svg>,
--   )
--   assertNamespacesMatch(
--     <math {...expectMath}>
--       <mi {...expectMath} />
--       {usePortal(<div {...expectHTML} />)}
--       <mi {...expectMath} />
--     </math>,
--   )
--   assertNamespacesMatch(
--     <div {...expectHTML}>
--       <p {...expectHTML} />
--       {usePortal(
--         <svg {...expectSVG}>
--           <image {...expectSVG} />
--         </svg>,
--       )}
--       <p {...expectHTML} />
--     </div>,
--   )
-- })

-- ROBLOX DEVIATION: Roblox does not have the same concept of namespaces as upstream React
-- it('should keep track of namespace across portals (medium)', () => {
--   assertNamespacesMatch(
--     <svg {...expectSVG}>
--       <image {...expectSVG} />
--       {usePortal(<div {...expectHTML} />)}
--       <image {...expectSVG} />
--       {usePortal(<div {...expectHTML} />)}
--       <image {...expectSVG} />
--     </svg>,
--   )
--   assertNamespacesMatch(
--     <div {...expectHTML}>
--       <math {...expectMath}>
--         <mi {...expectMath} />
--         {usePortal(
--           <svg {...expectSVG}>
--             <image {...expectSVG} />
--           </svg>,
--         )}
--       </math>
--       <p {...expectHTML} />
--     </div>,
--   )
--   assertNamespacesMatch(
--     <math {...expectMath}>
--       <mi {...expectMath} />
--       {usePortal(
--         <svg {...expectSVG}>
--           <image {...expectSVG} />
--           <foreignObject {...expectSVG}>
--             <p {...expectHTML} />
--             <math {...expectMath}>
--               <mi {...expectMath} />
--             </math>
--             <p {...expectHTML} />
--           </foreignObject>
--           <image {...expectSVG} />
--         </svg>,
--       )}
--       <mi {...expectMath} />
--     </math>,
--   )
--   assertNamespacesMatch(
--     <div {...expectHTML}>
--       {usePortal(
--         <svg {...expectSVG}>
--           {usePortal(<div {...expectHTML} />)}
--           <image {...expectSVG} />
--         </svg>,
--       )}
--       <p {...expectHTML} />
--     </div>,
--   )
--   assertNamespacesMatch(
--     <svg {...expectSVG}>
--       <svg {...expectSVG}>
--         {usePortal(<div {...expectHTML} />)}
--         <image {...expectSVG} />
--       </svg>
--       <image {...expectSVG} />
--     </svg>,
--   )
-- })

-- ROBLOX DEVIATION: Roblox does not have the same concept of namespaces as upstream React
-- it('should keep track of namespace across portals (complex)', () => {
--   assertNamespacesMatch(
--     <div {...expectHTML}>
--       {usePortal(
--         <svg {...expectSVG}>
--           <image {...expectSVG} />
--         </svg>,
--       )}
--       <p {...expectHTML} />
--       <svg {...expectSVG}>
--         <image {...expectSVG} />
--       </svg>
--       <svg {...expectSVG}>
--         <svg {...expectSVG}>
--           <image {...expectSVG} />
--         </svg>
--         <image {...expectSVG} />
--       </svg>
--       <p {...expectHTML} />
--     </div>,
--   )
--   assertNamespacesMatch(
--     <div {...expectHTML}>
--       <svg {...expectSVG}>
--         <svg {...expectSVG}>
--           <image {...expectSVG} />
--           {usePortal(
--             <svg {...expectSVG}>
--               <image {...expectSVG} />
--               <svg {...expectSVG}>
--                 <image {...expectSVG} />
--               </svg>
--               <image {...expectSVG} />
--             </svg>,
--           )}
--           <image {...expectSVG} />
--           <foreignObject {...expectSVG}>
--             <p {...expectHTML} />
--             {usePortal(<p {...expectHTML} />)}
--             <p {...expectHTML} />
--           </foreignObject>
--         </svg>
--         <image {...expectSVG} />
--       </svg>
--       <p {...expectHTML} />
--     </div>,
--   )
--   assertNamespacesMatch(
--     <div {...expectHTML}>
--       <svg {...expectSVG}>
--         <foreignObject {...expectSVG}>
--           <p {...expectHTML} />
--           {usePortal(
--             <svg {...expectSVG}>
--               <image {...expectSVG} />
--               <svg {...expectSVG}>
--                 <image {...expectSVG} />
--                 <foreignObject {...expectSVG}>
--                   <p {...expectHTML} />
--                 </foreignObject>
--                 {usePortal(<p {...expectHTML} />)}
--               </svg>
--               <image {...expectSVG} />
--             </svg>,
--           )}
--           <p {...expectHTML} />
--         </foreignObject>
--         <image {...expectSVG} />
--       </svg>
--       <p {...expectHTML} />
--     </div>,
--   )
-- })

-- ROBLOX DEVIATION: Roblox does not have the same concept of namespaces as upstream React
-- it('should unwind namespaces on uncaught errors', () => {
--   function BrokenRender()
--     throw new Error('Hello')
--   }

--   expect(() => {
--     assertNamespacesMatch(
--       <svg {...expectSVG}>
--         <BrokenRender />
--       </svg>,
--     )
--   }).toThrow('Hello')
--   assertNamespacesMatch(<div {...expectHTML} />)
-- })

-- ROBLOX DEVIATION: Roblox does not have the same concept of namespaces as upstream React
-- it('should unwind namespaces on caught errors', () => {
--   function BrokenRender()
--     throw new Error('Hello')
--   }

--   class ErrorBoundary extends React.Component {
--     state = {error: nil}
--     componentDidCatch(error)
--       this.setState({error})
--     }
--     render()
--       if this.state.error)
--         return <p {...expectHTML} />
--       }
--       return this.props.children
--     }
--   }

--   assertNamespacesMatch(
--     <svg {...expectSVG}>
--       <foreignObject {...expectSVG}>
--         <ErrorBoundary>
--           <math {...expectMath}>
--             <BrokenRender />
--           </math>
--         </ErrorBoundary>
--       </foreignObject>
--       <image {...expectSVG} />
--     </svg>,
--   )
--   assertNamespacesMatch(<div {...expectHTML} />)
-- })

-- ROBLOX DEVIATION: Roblox does not have the same concept of namespaces as upstream React
-- it('should unwind namespaces on caught errors in a portal', () => {
--   function BrokenRender()
--     throw new Error('Hello')
--   }

--   class ErrorBoundary extends React.Component {
--     state = {error: nil}
--     componentDidCatch(error)
--       this.setState({error})
--     }
--     render()
--       if this.state.error)
--         return <image {...expectSVG} />
--       }
--       return this.props.children
--     }
--   }

--   assertNamespacesMatch(
--     <svg {...expectSVG}>
--       <ErrorBoundary>
--         {usePortal(
--           <div {...expectHTML}>
--             <math {...expectMath}>
--               <BrokenRender />)
--             </math>
--           </div>,
--         )}
--       </ErrorBoundary>
--       {usePortal(<div {...expectHTML} />)}
--     </svg>,
--   )
-- })

it("should pass portal context when rendering subtree elsewhere", function()
	local portalContainer = Instance.new("Folder")

	local Context = React.createContext(1)

	local function Consumer()
		return React.createElement(Context.Consumer, nil, function(value)
			return React.createElement("TextLabel", { Text = tostring(value) })
		end)
	end

	local function Parent(props)
		return React.createElement(Context.Provider, {
			value = props.value,
		}, {
			Portal = ReactRoblox.createPortal({
				Consumer = React.createElement(Consumer),
			}, portalContainer),
		})
	end

	reactRobloxRoot:render(React.createElement(Parent, { value = "bar" }))
	Scheduler.unstable_flushAllWithoutAsserting()
	jestExpect(#parent:GetChildren()).toBe(0)
	jestExpect(#portalContainer:GetChildren()).toBe(1)
	jestExpect(portalContainer:GetChildren()[1].Text).toBe("bar")
end)

it("should update portal context if it changes due to setState", function()
	local portalContainer = Instance.new("Folder")

	local Context = React.createContext(1)

	local function Consumer()
		return React.createElement(Context.Consumer, nil, function(value)
			return React.createElement("TextLabel", { Text = tostring(value) })
		end)
	end

	local capturedSetState

	local Parent = React.Component:extend("Parent")

	function Parent:init()
		self:setState({
			value = "initial",
		})
	end

	function Parent:render()
		capturedSetState = function(...)
			self:setState(...)
		end

		return React.createElement(Context.Provider, {
			value = self.state.value,
		}, {
			Portal = ReactRoblox.createPortal({
				Consumer = React.createElement(Consumer),
			}, portalContainer),
		})
	end

	reactRobloxRoot:render(React.createElement(Parent))
	Scheduler.unstable_flushAllWithoutAsserting()
	jestExpect(#parent:GetChildren()).toBe(0)
	jestExpect(#portalContainer:GetChildren()).toBe(1)
	jestExpect(portalContainer:GetChildren()[1].Text).toBe("initial")

	capturedSetState({ value = "changed" })
	Scheduler.unstable_flushAllWithoutAsserting()
	jestExpect(#parent:GetChildren()).toBe(0)
	jestExpect(#portalContainer:GetChildren()).toBe(1)
	jestExpect(portalContainer:GetChildren()[1].Text).toBe("changed")
end)

it("should update portal context if it changes due to re-render", function()
	-- ROBLOX TODO: This test is essentially duplicated in RobloxRenderer.roblox.spec.lua. Where do we want it?
	local portalContainer = Instance.new("Folder")

	local Context = React.createContext(1)

	local function Consumer()
		return React.createElement(Context.Consumer, nil, function(value)
			return React.createElement("TextLabel", { Text = tostring(value) })
		end)
	end

	local function Parent(props)
		return React.createElement(Context.Provider, {
			value = props.value,
		}, {
			Portal = ReactRoblox.createPortal({
				Consumer = React.createElement(Consumer),
			}, portalContainer),
		})
	end

	reactRobloxRoot:render(React.createElement(Parent, { value = "initial" }))
	Scheduler.unstable_flushAllWithoutAsserting()
	jestExpect(#parent:GetChildren()).toBe(0)
	jestExpect(#portalContainer:GetChildren()).toBe(1)
	jestExpect(portalContainer:GetChildren()[1].Text).toBe("initial")

	reactRobloxRoot:render(React.createElement(Parent, { value = "changed" }))
	Scheduler.unstable_flushAllWithoutAsserting()
	jestExpect(#parent:GetChildren()).toBe(0)
	jestExpect(#portalContainer:GetChildren()).toBe(1)
	jestExpect(portalContainer:GetChildren()[1].Text).toBe("changed")
end)

-- it('findDOMNode should find dom element after expanding a fragment', () => {
--   class MyNode extends React.Component {
--     render()
--       return !this.props.flag
--         ? [<div key="a" />]
--         : [<span key="b" />, <div key="a" />]
--     }
--   }

--   local myNodeA = ReactDOM.render(<MyNode />, container)
--   local a = ReactDOM.findDOMNode(myNodeA)
--   expect(a.tagName).toBe('DIV')

--   local myNodeB = ReactDOM.render(<MyNode flag={true} />, container)
--   expect(myNodeA == myNodeB).toBe(true)

--   local b = ReactDOM.findDOMNode(myNodeB)
--   expect(b.tagName).toBe('SPAN')
-- })

-- ROBLOX DEVIATION: We do not have event bubbling like this in Roact
xit("should bubble events from the portal to the parent", function()
	--   local portalContainer = document.createElement('div')
	--   document.body.appendChild(portalContainer)
	--   try {
	--     local ops = []
	--     local portal = nil

	--     ReactDOM.render(
	--       <div onClick={() => ops.push('parent clicked')}>
	--         {ReactDOM.createPortal(
	--           <div
	--             onClick={() => ops.push('portal clicked')}
	--             ref={n => (portal = n)}>
	--             portal
	--           </div>,
	--           portalContainer,
	--         )}
	--       </div>,
	--       container,
	--     )

	--     expect(portal.tagName).toBe('DIV')

	--     portal.click()

	--     expect(ops).toEqual(['portal clicked', 'parent clicked'])
	--   } finally {
	--     document.body.removeChild(portalContainer)
	--   }
end)

-- ROBLOX DEVIATION: We do not have event bubbling in Roblox like this
xit("should not onMouseLeave when staying in the portal", function()
	--   local portalContainer = document.createElement('div')
	--   document.body.appendChild(portalContainer)

	--   local ops = []
	--   local firstTarget = nil
	--   local secondTarget = nil
	--   local thirdTarget = nil

	--   function simulateMouseMove(from, to)
	--     if from)
	--       from.dispatchEvent(
	--         new MouseEvent('mouseout', {
	--           bubbles: true,
	--           cancelable: true,
	--           relatedTarget: to,
	--         }),
	--       )
	--     }
	--     if to)
	--       to.dispatchEvent(
	--         new MouseEvent('mouseover', {
	--           bubbles: true,
	--           cancelable: true,
	--           relatedTarget: from,
	--         }),
	--       )
	--     }
	--   }

	--   try {
	--     ReactDOM.render(
	--       <div>
	--         <div
	--           onMouseEnter={() => ops.push('enter parent')}
	--           onMouseLeave={() => ops.push('leave parent')}>
	--           <div ref={n => (firstTarget = n)} />
	--           {ReactDOM.createPortal(
	--             <div
	--               onMouseEnter={() => ops.push('enter portal')}
	--               onMouseLeave={() => ops.push('leave portal')}
	--               ref={n => (secondTarget = n)}>
	--               portal
	--             </div>,
	--             portalContainer,
	--           )}
	--         </div>
	--         <div ref={n => (thirdTarget = n)} />
	--       </div>,
	--       container,
	--     )

	--     simulateMouseMove(null, firstTarget)
	--     expect(ops).toEqual(['enter parent'])

	--     ops = []

	--     simulateMouseMove(firstTarget, secondTarget)
	--     expect(ops).toEqual([
	--       -- Parent did not invoke leave because we're still inside the portal.
	--       'enter portal',
	--     ])

	--     ops = []

	--     simulateMouseMove(secondTarget, thirdTarget)
	--     expect(ops).toEqual([
	--       'leave portal',
	--       'leave parent', -- Only when we leave the portal does onMouseLeave fire.
	--     ])
	--   } finally {
	--     document.body.removeChild(portalContainer)
	--   }
end)

-- -- Regression test for https://github.com/facebook/react/issues/19562
-- it('does not fire mouseEnter twice when relatedTarget is the root node', () => {
--   local ops = []
--   local target = nil

--   function simulateMouseMove(from, to)
--     if from)
--       from.dispatchEvent(
--         new MouseEvent('mouseout', {
--           bubbles: true,
--           cancelable: true,
--           relatedTarget: to,
--         }),
--       )
--     }
--     if to)
--       to.dispatchEvent(
--         new MouseEvent('mouseover', {
--           bubbles: true,
--           cancelable: true,
--           relatedTarget: from,
--         }),
--       )
--     }
--   }

--   ReactDOM.render(
--     <div
--       ref={n => (target = n)}
--       onMouseEnter={() => ops.push('enter')}
--       onMouseLeave={() => ops.push('leave')}
--     />,
--     container,
--   )

--   simulateMouseMove(null, container)
--   expect(ops).toEqual([])

--   ops = []
--   simulateMouseMove(container, target)
--   expect(ops).toEqual(['enter'])

--   ops = []
--   simulateMouseMove(target, container)
--   expect(ops).toEqual(['leave'])

--   ops = []
--   simulateMouseMove(container)
--   expect(ops).toEqual([])
-- })

-- -- @gate enableEagerRootListeners
-- it('listens to events that do not exist in the Portal subtree', () => {
--   local onClick = jest.fn()

--   local ref = React.createRef()
--   ReactDOM.render(
--     <div onClick={onClick}>
--       {ReactDOM.createPortal(<button ref={ref}>click</button>, document.body)}
--     </div>,
--     container,
--   )
--   local event = new MouseEvent('click', {
--     bubbles: true,
--   })
--   ref.current.dispatchEvent(event)

--   expect(onClick).toHaveBeenCalledTimes(1)
-- })

it("should throw on bad createPortal argument", function()
	jestExpect(function()
		ReactRoblox.createPortal(React.createElement("Frame"))
	end).toThrow("Target container is not a Roblox Instance.")
	jestExpect(function()
		ReactRoblox.createPortal(React.createElement("Frame"), "hi")
	end).toThrow("Target container is not a Roblox Instance.")
end)

-- it('should warn for non-functional event listeners', () => {
--   class Example extends React.Component {
--     render()
--       return <div onClick="woops" />
--     }
--   }
--   expect(() => ReactDOM.render(<Example />, container)).toErrorDev(
--     'Expected `onClick` listener to be a function, instead got a value of `string` type.\n' +
--       '    in div (at **)\n' +
--       '    in Example (at **)',
--   )
-- })

-- it('should warn with a special message for `false` event listeners', () => {
--   class Example extends React.Component {
--     render()
--       return <div onClick={false} />
--     }
--   }
--   expect(() => ReactDOM.render(<Example />, container)).toErrorDev(
--     'Expected `onClick` listener to be a function, instead got `false`.\n\n' +
--       'If you used to conditionally omit it with onClick={condition and value}, ' +
--       'pass onClick={condition ? value : undefined} instead.\n' +
--       '    in div (at **)\n' +
--       '    in Example (at **)',
--   )
-- })

-- it('should not update event handlers until commit', () => {
--   spyOnDev(console, 'error')

--   local ops = []
--   local handlerA = () => ops.push('A')
--   local handlerB = () => ops.push('B')

--   function click()
--     local event = new MouseEvent('click', {
--       bubbles: true,
--       cancelable: true,
--     })
--     Object.defineProperty(event, 'timeStamp', {
--       value: 0,
--     })
--     node.dispatchEvent(event)
--   }

--   class Example extends React.Component {
--     state = {flip: false, count: 0}
--     flip()
--       this.setState({flip: true, count: this.state.count + 1})
--     }
--     tick()
--       this.setState({count: this.state.count + 1})
--     }
--     render()
--       local useB = !this.props.forceA and this.state.flip
--       return <div onClick={useB ? handlerB : handlerA} />
--     }
--   }

--   class Click extends React.Component {
--     constructor()
--       super()
--       node.click()
--     }
--     render()
--       return nil
--     }
--   }

--   local inst
--   ReactDOM.render([<Example key="a" ref={n => (inst = n)} />], container)
--   local node = container.firstChild
--   expect(node.tagName).toEqual('DIV')

--   click()

--   expect(ops).toEqual(['A'])
--   ops = []

--   -- Render with the other event handler.
--   inst.flip()

--   click()

--   expect(ops).toEqual(['B'])
--   ops = []

--   -- Rerender without changing any props.
--   inst.tick()

--   click()

--   expect(ops).toEqual(['B'])
--   ops = []

--   -- Render a flip back to the A handler. The second component invokes the
--   -- click handler during render to simulate a click during an aborted
--   -- render. I use this hack because at current time we don't have a way to
--   -- test aborted ReactDOM renders.
--   ReactDOM.render(
--     [<Example key="a" forceA={true} />, <Click key="b" />],
--     container,
--   )

--   -- Because the new click handler has not yet committed, we should still
--   -- invoke B.
--   expect(ops).toEqual(['B'])
--   ops = []

--   -- Any click that happens after commit, should invoke A.
--   click()
--   expect(ops).toEqual(['A'])

--   if __DEV__)
--     -- TODO: this warning shouldn't be firing in the first place if user didn't call it.
--     local errorCalls = console.error.calls.count()
--     for (local i = 0; i < errorCalls; i++)
--       expect(console.error.calls.argsFor(i)[0]).toMatch(
--         'unstable_flushDiscreteUpdates: Cannot flush updates when React is already rendering.',
--       )
--     }
--   }
-- })

-- it('should not crash encountering low-priority tree', () => {
--   ReactDOM.render(
--     <div hidden={true}>
--       <div />
--     </div>,
--     container,
--   )
-- })

-- it('should not warn when rendering into an empty container', () => {
--   ReactDOM.render(<div>foo</div>, container)
--   expect(container.innerHTML).toBe('<div>foo</div>')
--   ReactDOM.render(null, container)
--   expect(container.innerHTML).toBe('')
--   ReactDOM.render(<div>bar</div>, container)
--   expect(container.innerHTML).toBe('<div>bar</div>')
-- })

-- it('should warn when replacing a container which was manually updated outside of React', () => {
--   -- when not messing with the DOM outside of React
--   ReactDOM.render(<div key="1">foo</div>, container)
--   ReactDOM.render(<div key="1">bar</div>, container)
--   expect(container.innerHTML).toBe('<div>bar</div>')
--   -- then we mess with the DOM before an update
--   -- we know this will error - that is expected right now
--   -- It's an error of type 'NotFoundError' with no message
--   container.innerHTML = '<div>MEOW.</div>'

--   expect(() => {
--     expect(() =>
--       ReactDOM.render(<div key="2">baz</div>, container),
--     ).toErrorDev(
--       'render(...): ' +
--         'It looks like the React-rendered content of this container was ' +
--         'removed without using React. This is not supported and will ' +
--         'cause errors. Instead, call ReactDOM.unmountComponentAtNode ' +
--         'to empty a container.',
--       {withoutStack: true},
--     )
--   }).toThrowError()
-- })

-- it('should warn when doing an update to a container manually updated outside of React', () => {
--   -- when not messing with the DOM outside of React
--   ReactDOM.render(<div>foo</div>, container)
--   ReactDOM.render(<div>bar</div>, container)
--   expect(container.innerHTML).toBe('<div>bar</div>')
--   -- then we mess with the DOM before an update
--   container.innerHTML = '<div>MEOW.</div>'
--   expect(() =>
--     ReactDOM.render(<div>baz</div>, container),
--   ).toErrorDev(
--     'render(...): ' +
--       'It looks like the React-rendered content of this container was ' +
--       'removed without using React. This is not supported and will ' +
--       'cause errors. Instead, call ReactDOM.unmountComponentAtNode ' +
--       'to empty a container.',
--     {withoutStack: true},
--   )
-- })

-- it('should warn when doing an update to a container manually cleared outside of React', () => {
--   -- when not messing with the DOM outside of React
--   ReactDOM.render(<div>foo</div>, container)
--   ReactDOM.render(<div>bar</div>, container)
--   expect(container.innerHTML).toBe('<div>bar</div>')
--   -- then we mess with the DOM before an update
--   container.innerHTML = ''
--   expect(() =>
--     ReactDOM.render(<div>baz</div>, container),
--   ).toErrorDev(
--     'render(...): ' +
--       'It looks like the React-rendered content of this container was ' +
--       'removed without using React. This is not supported and will ' +
--       'cause errors. Instead, call ReactDOM.unmountComponentAtNode ' +
--       'to empty a container.',
--     {withoutStack: true},
--   )
-- })

-- it('should render a text component with a text DOM node on the same document as the container', () => {
--   -- 1. Create a new document through the use of iframe
--   -- 2. Set up the spy to make asserts when a text component
--   --    is rendered inside the iframe container
--   local textContent = 'Hello world'
--   local iframe = document.createElement('iframe')
--   document.body.appendChild(iframe)
--   local iframeDocument = iframe.contentDocument
--   iframeDocument.write(
--     '<!DOCTYPE html><html><head></head><body><div></div></body></html>',
--   )
--   iframeDocument.close()
--   local iframeContainer = iframeDocument.body.firstChild

--   local actualDocument
--   local textNode

--   spyOnDevAndProd(iframeContainer, 'appendChild').and.callFake(node => {
--     actualDocument = node.ownerDocument
--     textNode = node
--   })

--   ReactDOM.render(textContent, iframeContainer)

--   expect(textNode.textContent).toBe(textContent)
--   expect(actualDocument).not.toBe(document)
--   expect(actualDocument).toBe(iframeDocument)
--   expect(iframeContainer.appendChild).toHaveBeenCalledTimes(1)
-- })

-- it('should mount into a document fragment', () => {
--   local fragment = document.createDocumentFragment()
--   ReactDOM.render(<div>foo</div>, fragment)
--   expect(container.innerHTML).toBe('')
--   container.appendChild(fragment)
--   expect(container.innerHTML).toBe('<div>foo</div>')
-- })

-- -- Regression test for https://github.com/facebook/react/issues/12643#issuecomment-413727104
-- it('should not diff memoized host components', () => {
--   local inputRef = React.createRef()
--   local didCallOnChange = false

--   class Child extends React.Component {
--     state = {}
--     componentDidMount()
--       document.addEventListener('click', this.update, true)
--     }
--     componentWillUnmount()
--       document.removeEventListener('click', this.update, true)
--     }
--     update = () => {
--       -- We're testing that this setState()
--       -- doesn't cause React to commit updates
--       -- to the input outside (which would itself
--       -- prevent the parent's onChange parent handler
--       -- from firing).
--       this.setState({})
--       -- Note that onChange was always broken when there was an
--       -- earlier setState() in a manual document capture phase
--       -- listener *in the same component*. But that's very rare.
--       -- Here we're testing that a *child* component doesn't break
--       -- the parent if this happens.
--     }
--     render()
--       return <div />
--     }
--   }

--   class Parent extends React.Component {
--     handleChange = val => {
--       didCallOnChange = true
--     }
--     render()
--       return (
--         <div>
--           <Child />
--           <input
--             ref={inputRef}
--             type="checkbox"
--             checked={true}
--             onChange={this.handleChange}
--           />
--         </div>
--       )
--     }
--   }

--   ReactDOM.render(<Parent />, container)
--   inputRef.current.dispatchEvent(
--     new MouseEvent('click', {
--       bubbles: true,
--     }),
--   )
--   expect(didCallOnChange).toBe(true)
-- })

-- it('unmounted legacy roots should never clear newer root content from a container', () => {
--   local ref = React.createRef()

--   function OldApp()
--     local hideOnFocus = () => {
--       -- This app unmounts itself inside of a focus event.
--       ReactDOM.unmountComponentAtNode(container)
--     }

--     return (
--       <button onFocus={hideOnFocus} ref={ref}>
--         old
--       </button>
--     )
--   }

--   function NewApp()
--     return <button ref={ref}>new</button>
--   }

--   ReactDOM.render(<OldApp />, container)
--   ref.current.focus()

--   ReactDOM.render(<NewApp />, container)

--   -- Calling focus again will flush previously scheduled discrete work for the old root-
--   -- but this should not clear out the newly mounted app.
--   ref.current.focus()

--   expect(container.textContent).toBe('new')
-- })
