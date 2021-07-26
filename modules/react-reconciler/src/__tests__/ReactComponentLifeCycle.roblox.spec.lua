-- Copy of ReactComponentLifeCycle.spec.lua that instead tests old Roact lifecycle method names (which we'll support temporarily)

--[[
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
]]
--[[*
 * TODO: We should make any setState calls fail in
 * `getInitialState` and `componentWillMount`. They will usually fail
 * anyways because `this._renderedComponent` is empty, however, if a component
 * is *reused*, then that won't be the case and things will appear to work in
 * some cases. Better to just block all updates in initialization.
 ]]
 --!nolint

 return function()
    local HttpService = game:GetService("HttpService")
    local Packages = script.Parent.Parent.Parent
    local RobloxJest = require(Packages.Dev.RobloxJest)
    local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect

    -- deviation: Move all of the following into the test function body to match
    -- convention
    local React
    -- local ReactDOM
    local ReactNoop
    -- local ReactTestUtils
    -- local PropTypes

    local clone = function(o)
      return HttpService:JSONDecode(HttpService:JSONEncode(o))
    end

    local GET_INIT_STATE_RETURN_VAL = {
      hasWillMountCompleted = false,
      hasRenderCompleted = false,
      hasDidMountCompleted = false,
      hasWillUnmountCompleted = false,
    }

    local INIT_RENDER_STATE = {
      hasWillMountCompleted = true,
      hasRenderCompleted = false,
      hasDidMountCompleted = false,
      hasWillUnmountCompleted = false,
    }

    local DID_MOUNT_STATE = {
      hasWillMountCompleted = true,
      hasRenderCompleted = true,
      hasDidMountCompleted = false,
      hasWillUnmountCompleted = false,
    }

    local NEXT_RENDER_STATE = {
      hasWillMountCompleted = true,
      hasRenderCompleted = true,
      hasDidMountCompleted = true,
      hasWillUnmountCompleted = false,
    }

    local WILL_UNMOUNT_STATE = {
      hasWillMountCompleted = true,
      hasDidMountCompleted = true,
      hasRenderCompleted = true,
      hasWillUnmountCompleted = false,
    }

    local POST_WILL_UNMOUNT_STATE = {
      hasWillMountCompleted = true,
      hasDidMountCompleted = true,
      hasRenderCompleted = true,
      hasWillUnmountCompleted = true,
    }

    --[[
      Every React component is in one of these life cycles.
      * MOUNTED
        * Mounted components have a DOM node representation and are capable of
        receiving new props.
      * UNMOUNTED
        * Unmounted components are inactive and cannot receive new props.
    ]]
    type ComponentLifeCycle = string

    local function getLifeCycleState(instance): ComponentLifeCycle
      return instance.updater.isMounted(instance) and "MOUNTED" or "UNMOUNTED"
    end

    beforeEach(function()
      RobloxJest.resetModules()
      RobloxJest.useFakeTimers()

      React = require(Packages.React)
      ReactNoop = require(Packages.Dev.ReactNoopRenderer)
      -- ReactDOM = require('react-dom')
      -- ReactTestUtils = require('react-dom/test-utils')
      -- PropTypes = require('prop-types')

      -- ROBLOX deviation: these tests are failing with debugRenderPhaseSideEffectsForStrictMode on.
      -- https://github.com/Roblox/roact-alignment/issues/105
      local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
      ReactFeatureFlags.debugRenderPhaseSideEffectsForStrictMode = false
    end)

    it('should correctly determine if a component is mounted', function()
      local isMounted
      local Component = React.Component:extend("Component")

      function Component:init()
        isMounted = function()
          -- No longer a public API, but we can test that it works internally by
          -- reaching into the updater.
          return self.updater.isMounted(self)
        end
      end
      function Component:UNSAFE_componentWillMount()
        jestExpect(isMounted()).toBe(false)
      end
      function Component:didMount()
        -- ROBLOX deviation: assert self is non nil
        jestExpect(self).never.toEqual(nil)
        jestExpect(isMounted()).toBe(true)
      end
      function Component:render()
        jestExpect(isMounted()).toBe(false)
        return React.createElement("div")
      end

      local element = React.createElement(Component)

      jestExpect(function()
        ReactNoop.act(function()
          ReactNoop.render(element)
        end)
        jestExpect(isMounted()).toBe(true)
      end).toErrorDev(
        {
          "Component is accessing isMounted inside its render()",
          "UNSAFE_componentWillMount in strict mode is not recommended",
        },
        {withoutStack = 1}
      )
    end)

    it('should correctly determine if a nil component is mounted', function()
      local isMounted
      local Component = React.Component:extend("Component")

      function Component:init()
        isMounted = function()
          -- No longer a public API, but we can test that it works internally by
          -- reaching into the updater.
          return self.updater.isMounted(self)
        end
      end
      function Component:UNSAFE_componentWillMount()
        jestExpect(isMounted()).toBe(false)
      end
      function Component:didMount()
        jestExpect(isMounted()).toBe(true)
      end
      function Component:render()
        jestExpect(isMounted()).toBe(false)
        return nil
      end

      local element = React.createElement(Component)

      jestExpect(function()
        ReactNoop.act(function()
          ReactNoop.render(element)
        end)
        jestExpect(isMounted()).toBe(true)
      end).toErrorDev(
        {
          "Component is accessing isMounted inside its render()",
          "UNSAFE_componentWillMount in strict mode is not recommended",
        },
        {withoutStack = 1}
      )
    end)

    it('should carry through each of the phases of setup', function()
      local _testJournal: any = {}
      local getTestLifeCycleState, getInstanceState
      local LifeCycleComponent = React.Component:extend("LifeCycleComponent")
      function LifeCycleComponent:init()
        local initState = {
          hasWillMountCompleted = false,
          hasDidMountCompleted = false,
          hasRenderCompleted = false,
          hasWillUnmountCompleted = false,
        }
        getTestLifeCycleState = function()
          return getLifeCycleState(self)
        end
        getInstanceState = function()
          return self.state
        end
        _testJournal.returnedFromGetInitialState = clone(initState)
        _testJournal.lifeCycleAtStartOfGetInitialState = getTestLifeCycleState()
        self.state = initState
      end

      function LifeCycleComponent:UNSAFE_componentWillMount()
        _testJournal.stateAtStartOfWillMount = clone(self.state)
        _testJournal.lifeCycleAtStartOfWillMount = getTestLifeCycleState()
        self.state.hasWillMountCompleted = true
      end

      function LifeCycleComponent:didMount()
        _testJournal.stateAtStartOfDidMount = clone(self.state)
        _testJournal.lifeCycleAtStartOfDidMount = getTestLifeCycleState()
        self:setState({hasDidMountCompleted = true})
      end

      function LifeCycleComponent:render()
          local isInitialRender = not self.state.hasRenderCompleted
          if isInitialRender then
            _testJournal.stateInInitialRender = clone(self.state)
            _testJournal.lifeCycleInInitialRender = getTestLifeCycleState()
          else
            _testJournal.stateInLaterRender = clone(self.state)
            _testJournal.lifeCycleInLaterRender = getTestLifeCycleState()
          end
          -- you would *NEVER* do anything like this in real code!
          self.state.hasRenderCompleted = true
          return React.createElement("TextLabel", { Text = "I am the inner DIV" })
        end

        function LifeCycleComponent:willUnmount()
        -- ROBLOX deviation: assert self is non nil
        jestExpect(self).never.toEqual(nil)

        _testJournal.stateAtStartOfWillUnmount = clone(self.state)
        _testJournal.lifeCycleAtStartOfWillUnmount = getTestLifeCycleState()
        self.state.hasWillUnmountCompleted = true
      end

      -- A component that is merely "constructed" (as in "constructor") but not
      -- yet initialized, or rendered.
      --
      -- local container = document.createElement('div')

      jestExpect(function()
        ReactNoop.act(function()
          ReactNoop.render(React.createElement(LifeCycleComponent))
        end)
      end).toErrorDev(
        {
          "LifeCycleComponent is accessing isMounted inside its render() function",
          "UNSAFE_componentWillMount in strict mode is not recommended",
        },
        {withoutStack = 1}
      )

      -- getInitialState
      jestExpect(_testJournal.returnedFromGetInitialState).toEqual(
        GET_INIT_STATE_RETURN_VAL
      )
      jestExpect(_testJournal.lifeCycleAtStartOfGetInitialState).toBe(
        'UNMOUNTED'
      )

      -- componentWillMount
      jestExpect(_testJournal.stateAtStartOfWillMount).toEqual(
        _testJournal.returnedFromGetInitialState
      )
      jestExpect(_testJournal.lifeCycleAtStartOfWillMount).toBe('UNMOUNTED')

      -- didMount
      jestExpect(_testJournal.stateAtStartOfDidMount).toEqual(
        DID_MOUNT_STATE
      )
      jestExpect(_testJournal.lifeCycleAtStartOfDidMount).toBe('MOUNTED')

      -- initial render
      jestExpect(_testJournal.stateInInitialRender).toEqual(
        INIT_RENDER_STATE
      )
      jestExpect(_testJournal.lifeCycleInInitialRender).toBe('UNMOUNTED')

      jestExpect(getTestLifeCycleState()).toBe('MOUNTED')

      -- Now *update the component*
      -- instance.forceUpdate()
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(LifeCycleComponent))
      end)

      -- render 2nd time
      jestExpect(_testJournal.stateInLaterRender).toEqual(NEXT_RENDER_STATE)
      jestExpect(_testJournal.lifeCycleInLaterRender).toBe('MOUNTED')

      jestExpect(getTestLifeCycleState()).toBe('MOUNTED')

      ReactNoop.act(function()
        ReactNoop.render(nil)
      end)

      jestExpect(_testJournal.stateAtStartOfWillUnmount).toEqual(
        WILL_UNMOUNT_STATE
      )
      -- willUnmount called right before unmount.
      jestExpect(_testJournal.lifeCycleAtStartOfWillUnmount).toBe('MOUNTED')

      -- But the current lifecycle of the component is unmounted.
      jestExpect(getTestLifeCycleState()).toBe('UNMOUNTED')
      jestExpect(getInstanceState()).toEqual(POST_WILL_UNMOUNT_STATE)
    end)

    it('should allow state updates in didMount', function()
      local getComponentState
      --[[*
       * calls setState in an didMount.
       ]]
      local SetStateInComponentDidMount = React.Component:extend("SetStateInComponentDidMount")
      function SetStateInComponentDidMount:init()
        self.state = {
          stateField = self.props.valueToUseInitially,
        }
        getComponentState = function()
          return self.state
        end
      end

      function SetStateInComponentDidMount:didMount()
        self:setState({stateField = self.props.valueToUseAfterMount})
      end

      function SetStateInComponentDidMount:render()
        return React.createElement("div")
      end

      local element =
        React.createElement(SetStateInComponentDidMount, {
          valueToUseInitially = "hello",
          valueToUseAfterMount = "goodbye",
        })
      ReactNoop.act(function()
        ReactNoop.render(element)
      end)
      jestExpect(getComponentState().stateField).toBe("goodbye")
    end)

    it('should call nested legacy lifecycle methods in the right order', function()
      local log
      local logger = function(msg)
        return function()
          -- return true for shouldUpdate
          table.insert(log, msg)
          return true
        end
      end

      local Outer = React.Component:extend("Outer")
      -- pre-declare
      local Inner = React.Component:extend("Inner")
      Outer.UNSAFE_componentWillMount = logger("outer componentWillMount")
      Outer.didMount = logger("outer didMount")
      Outer.UNSAFE_componentWillReceiveProps = logger(
        "outer componentWillReceiveProps"
      )
      Outer.shouldUpdate = logger("outer shouldUpdate")
      Outer.willUpdate = logger("outer willUpdate")
      Outer.didUpdate = logger("outer didUpdate")
      Outer.willUnmount = logger("outer willUnmount")
      function Outer:render()
        return React.createElement("Frame", {},
          React.createElement(Inner, {
            x = self.props.x
          })
        )
      end

      Inner.UNSAFE_componentWillMount = logger("inner componentWillMount")
      Inner.didMount = logger("inner didMount")
      Inner.UNSAFE_componentWillReceiveProps = logger(
          "inner componentWillReceiveProps"
        )
      Inner.shouldUpdate = logger("inner shouldUpdate")
      Inner.willUpdate = logger("inner willUpdate")
      Inner.didUpdate = logger("inner didUpdate")
      Inner.willUnmount = logger("inner willUnmount")
      function Inner:render()
        return React.createElement("TextLabel", { Text = self.props.x })
      end

      log = {}
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(Outer, {x = 1}))
      end)
      jestExpect(log).toEqual({
        "outer componentWillMount",
        "inner componentWillMount",
        "inner didMount",
        "outer didMount",
      })

      -- Dedup warnings
      log = {}
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(Outer, {x = 2}))
      end)
      jestExpect(log).toEqual({
        "outer componentWillReceiveProps",
        "outer shouldUpdate",
        "outer willUpdate",
        "inner componentWillReceiveProps",
        "inner shouldUpdate",
        "inner willUpdate",
        "inner didUpdate",
        "outer didUpdate",
      })

      log = {}
      ReactNoop.act(function()
        ReactNoop.render(nil)
      end)
      jestExpect(log).toEqual({
        "outer willUnmount",
        "inner willUnmount",
      })
    end)

    it('should call nested new lifecycle methods in the right order', function()
      local log
      local logger = function(msg)
        return function()
          -- return true for shouldUpdate
          table.insert(log, msg)
          return true
        end
      end
      local Outer = React.Component:extend("Outer")
      -- pre-declare
      local Inner = React.Component:extend("Inner")
      function Outer:init()
        self.state = {}
      end
      function Outer.getDerivedStateFromProps(props, prevState)
        table.insert(log, "outer getDerivedStateFromProps")
        return nil
      end
      Outer.didMount = logger("outer didMount")
      Outer.shouldUpdate = logger("outer shouldUpdate")
      Outer.getSnapshotBeforeUpdate = logger("outer getSnapshotBeforeUpdate")
      Outer.didUpdate = logger("outer didUpdate")
      Outer.willUnmount = logger("outer willUnmount")
      function Outer:render()
        return React.createElement("Frame", {},
          React.createElement(Inner, {x = self.props.x})
        )
      end

      function Inner:init()
        self.state = {}
      end
      function Inner.getDerivedStateFromProps(props, prevState)
        table.insert(log, "inner getDerivedStateFromProps")
        return nil
      end
      Inner.didMount = logger("inner didMount")
      Inner.shouldUpdate = logger("inner shouldUpdate")
      Inner.getSnapshotBeforeUpdate = logger("inner getSnapshotBeforeUpdate")
      Inner.didUpdate = logger("inner didUpdate")
      Inner.willUnmount = logger("inner willUnmount")
      function Inner:render()
        return React.createElement("TextLabel", {Text = self.props.x})
      end

      log = {}
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(Outer, {x = 1}))
      end)
      jestExpect(log).toEqual({
        "outer getDerivedStateFromProps",
        "inner getDerivedStateFromProps",
        "inner didMount",
        "outer didMount",
      })

      -- Dedup warnings
      log = {}
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(Outer, {x = 2}))
      end)
      jestExpect(log).toEqual({
        "outer getDerivedStateFromProps",
        "outer shouldUpdate",
        "inner getDerivedStateFromProps",
        "inner shouldUpdate",
        "inner getSnapshotBeforeUpdate",
        "outer getSnapshotBeforeUpdate",
        "inner didUpdate",
        "outer didUpdate",
      })

      log = {}
      ReactNoop.act(function()
        ReactNoop.render(nil)
      end)
      jestExpect(log).toEqual({
        "outer willUnmount",
        "inner willUnmount",
      })
    end)

    it("should warn if state is not initialized before getDerivedStateFromProps", function()
      local MyComponent = React.Component:extend("MyComponent")
      function MyComponent.getDerivedStateFromProps()
        return nil
      end
      function MyComponent:render()
        return nil
      end

      jestExpect(function()
        ReactNoop.act(function()
          ReactNoop.render(React.createElement(MyComponent))
        end)
      end).toErrorDev(
        "`MyComponent` uses `getDerivedStateFromProps` but its state has not been initialized. " ..
      "This is not recommended. Instead, define the initial state by " ..
      "passing an object to `self:setState` in the `init` method of `MyComponent`. " ..
      "This ensures that `getDerivedStateFromProps` arguments have a consistent shape."
      )

      -- De-duped
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(MyComponent))
      end)
    end)

    it('should pass the return value from getSnapshotBeforeUpdate to didUpdate', function()
      local log = {}

      local MyComponent = React.Component:extend("MyComponent")
      function MyComponent:init()
        self.state = {
          value = 0,
        }
      end
      function MyComponent.getDerivedStateFromProps(nextProps, prevState)
        return {
          value = prevState.value + 1,
        }
      end
      function MyComponent:getSnapshotBeforeUpdate(prevProps, prevState)
        table.insert(log, string.format(
          "getSnapshotBeforeUpdate() prevProps:%s prevState:%s",
            prevProps.value,
            prevState.value
          )
        )
        return "abc"
      end
      function MyComponent:didUpdate(prevProps, prevState, snapshot)
        table.insert(log, string.format(
          "didUpdate() prevProps:%s prevState:%s snapshot:%s",
            prevProps.value,
            prevState.value,
            snapshot
          )
        )
      end
      function MyComponent:render()
        table.insert(log, "render")
        return nil
      end

      ReactNoop.act(function()
        ReactNoop.render(React.createElement("Frame", {},
          React.createElement(MyComponent, {
            value = "foo",
          })
        ))
      end)
      jestExpect(log).toEqual({"render"})
      log = {}

      ReactNoop.act(function()
        ReactNoop.render(React.createElement("Frame", {},
          React.createElement(MyComponent, {
            value = "bar",
          })
        ))
      end)
      jestExpect(log).toEqual({
        "render",
        "getSnapshotBeforeUpdate() prevProps:foo prevState:1",
        "didUpdate() prevProps:foo prevState:1 snapshot:abc",
      })
      log = {}

      ReactNoop.act(function()
        ReactNoop.render(React.createElement("Frame", {},
          React.createElement(MyComponent, {
            value = "baz",
          })
        ))
      end)
      jestExpect(log).toEqual({
        "render",
        "getSnapshotBeforeUpdate() prevProps:bar prevState:2",
        "didUpdate() prevProps:bar prevState:2 snapshot:abc",
      })
      log = {}

      ReactNoop.act(function()
        ReactNoop.render(React.createElement("Frame"))
      end)
      jestExpect(log).toEqual({})
    end)

    it('should pass previous state to shouldUpdate even with getDerivedStateFromProps', function()
      local divRef = React.createRef()
      local capturedValue
      local SimpleComponent = React.Component:extend("SimpleComponent")
      function SimpleComponent:init(props)
        self.state = {
          value = props.value,
        }
      end

      function SimpleComponent.getDerivedStateFromProps(nextProps, prevState)
        if nextProps.value == prevState.value then
          return nil
        end
        return {value = nextProps.value}
      end

      function SimpleComponent:shouldUpdate(nextProps, nextState)
        return nextState.value ~= self.state.value
      end

      function SimpleComponent:render()
        capturedValue = self.state.value
        return React.createElement("Frame", { ref = divRef },
          React.createElement("TextLabel", { Text = self.state.value })
        )
      end

      ReactNoop.act(function()
        ReactNoop.render(React.createElement(SimpleComponent, {value = "initial"}))
      end)
      jestExpect(capturedValue).toBe("initial")
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(SimpleComponent, {value = "updated"}))
      end)
      jestExpect(capturedValue).toBe("updated")
    end)

    it("should warn if getSnapshotBeforeUpdate is defined with no componentDidUpdate", function()
      local MyComponent = React.Component:extend("MyComponent")
      function MyComponent:getSnapshotBeforeUpdate()
        return nil
      end
      function MyComponent:render()
        return nil
      end

      jestExpect(function()
        ReactNoop.act(function()
          ReactNoop.render(React.createElement(MyComponent))
        end).toErrorDev(
          "MyComponent: getSnapshotBeforeUpdate() should be used with componentDidUpdate(). " ..
            "This component defines getSnapshotBeforeUpdate() only."
        )
      end)

      -- De-duped
      ReactNoop.act(function()
        ReactNoop.render(React.createElement(MyComponent))
      end)
    end)
    it("should warn if using old Roact didMount naming", function()
        local Foo = React.Component:extend("Foo")
        jestExpect(function()
            function Foo:didMount() end
        end).toWarnDev("Foo is using method 'didMount', which is no longer supported and should be updated to 'componentDidMount'\nFile: ReactComponentLifeCycle.roblox.spec:", {withoutStack = true})
    end)
    it("should warn if using old Roact shouldUpdate naming", function()
        local Foo = React.Component:extend("Foo")
        jestExpect(function()
            function Foo:shouldUpdate() end
        end).toWarnDev("Foo is using method 'shouldUpdate', which is no longer supported and should be updated to 'shouldComponentUpdate'\nFile: ReactComponentLifeCycle.roblox.spec:", {withoutStack = true})
    end)
    it("should warn if using old Roact willUpdate naming", function()
        local Foo = React.Component:extend("Foo")
        jestExpect(function()
            function Foo:willUpdate() end
        end).toWarnDev("Foo is using method 'willUpdate', which is no longer supported and should be updated to 'UNSAFE_componentWillUpdate'\nFile: ReactComponentLifeCycle.roblox.spec:", {withoutStack = true})
    end)
    it("should warn if using old Roact didUpdate naming", function()
        local Foo = React.Component:extend("Foo")
        jestExpect(function()
            function Foo:didUpdate() end
        end).toWarnDev("Foo is using method 'didUpdate', which is no longer supported and should be updated to 'componentDidUpdate'\nFile: ReactComponentLifeCycle.roblox.spec:", {withoutStack = true})
    end)
    it("should warn if using old Roact willUnmount naming", function()
        local Foo = React.Component:extend("Foo")
        jestExpect(function()
            function Foo:willUnmount() end
        end).toWarnDev("Foo is using method 'willUnmount', which is no longer supported and should be updated to 'componentWillUnmount'\nFile: ReactComponentLifeCycle.roblox.spec:", {withoutStack = true})
    end)
    it("should warn if both didMount and componentDidMount are both defined within the same class", function()
        local Foo = React.Component:extend("Foo")
        function Foo:componentDidMount() end
        jestExpect(function()
            function Foo:didMount() end
        end).toWarnDev("Warning: Foo already defined 'componentDidMount', but it also defining the deprecated Roact method 'didMount'. Foo should only implement one of these methods, preferably using the non-deprecated name.", {withoutStack = true})
    end)
    it("should warn if both shouldUpdate and shouldComponentUpdate are both defined within the same class", function()
        local Foo = React.Component:extend("Foo")
        function Foo:shouldComponentUpdate() end
        jestExpect(function()
            function Foo:shouldUpdate() end
        end).toWarnDev("Warning: Foo already defined 'shouldComponentUpdate', but it also defining the deprecated Roact method 'shouldUpdate'. Foo should only implement one of these methods, preferably using the non-deprecated name.", {withoutStack = true})
    end)
    it("should warn if both willUpdate and componentWillUpdate are both defined within the same class", function()
        local Foo = React.Component:extend("Foo")
        function Foo:componentWillUpdate() end
        jestExpect(function()
            function Foo:willUpdate() end
        end).toWarnDev("Warning: Foo already defined 'UNSAFE_componentWillUpdate', but it also defining the deprecated Roact method 'willUpdate'. Foo should only implement one of these methods, preferably using the non-deprecated name.", {withoutStack = true})

        -- tests same thing but with UNSAFE_componentWillUpdate() which is the prefered name starting from Roact 16.x
        local Bar = React.Component:extend("Bar")
        function Foo:UNSAFE_componentWillUpdate() end
        jestExpect(function()
            function Foo:willUpdate() end
        end).toWarnDev("Warning: Foo already defined 'UNSAFE_componentWillUpdate', but it also defining the deprecated Roact method 'willUpdate'. Foo should only implement one of these methods, preferably using the non-deprecated name.", {withoutStack = true})
    end)
    it("should worn if both didUpdate and componentDidUpdate are both defined within the same class", function()
        local Foo = React.Component:extend("Foo")
        function Foo:componentDidUpdate() end
        jestExpect(function()
            function Foo:didUpdate() end
        end).toWarnDev("Warning: Foo already defined 'componentDidUpdate', but it also defining the deprecated Roact method 'didUpdate'. Foo should only implement one of these methods, preferably using the non-deprecated name.", {withoutStack = true})
    end)
    it("should warn if both willUnmount and componentWillUnmount are both defined within the same class", function()
        local Foo = React.Component:extend("Foo")
        function Foo:componentWillUnmount() end
        jestExpect(function()
            function Foo:willUnmount() end
        end).toWarnDev("Warning: Foo already defined 'componentWillUnmount', but it also defining the deprecated Roact method 'willUnmount'. Foo should only implement one of these methods, preferably using the non-deprecated name", {withoutStack = true})
    end)
  end
