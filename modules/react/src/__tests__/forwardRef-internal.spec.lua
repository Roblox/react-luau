--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 ]]
--!strict

return function()
  local Packages = script.Parent.Parent.Parent
  local RobloxJest = require(Packages.Dev.RobloxJest)
  local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect
  local Error = require(Packages.LuauPolyfill).Error
  local Cryo = require(Packages.Cryo)

  local React
  local ReactFeatureFlags
  local ReactNoop
  local Scheduler

  beforeEach(function()
    RobloxJest.resetModules()
    ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags

    ReactFeatureFlags.replayFailedUnitOfWorkWithInvokeGuardedCallback = false
    React = require(script.Parent.Parent)
    ReactNoop = require(Packages.Dev.ReactNoopRenderer)
    Scheduler = require(Packages.Dev.Scheduler)
  end)

  it("should work without a ref to be forwarded", function()
    local Child = React.Component:extend("Child")
    function Child:render()
      Scheduler.unstable_yieldValue(self.props.value)
      return nil
    end

    local function Wrapper(props)
      return React.createElement(Child, Cryo.Dictionary.join(props, {ref=props.forwardedRef}))
    end

    local RefForwardingComponent = React.forwardRef(function(props, ref)
      return React.createElement(Wrapper, Cryo.Dictionary.join(props, {forwardedRef=ref}))
    end)

    ReactNoop.render(React.createElement(RefForwardingComponent, {value=123}))
    jestExpect(Scheduler).toFlushAndYield({123})
  end)

  -- ROBLOX TODO: Fails in DEV (nothing yielded from `toFlushAndYield`), unclear why
  it("should forward a ref for a single child", function()
    local Child = React.Component:extend("Child")
    function Child:render()
      Scheduler.unstable_yieldValue(self.props.value)
      return nil
    end

    local function Wrapper(props)
    -- ROBLOX TODO: Erroneous warnings in dev here
    return React.createElement(Child, Cryo.Dictionary.join(props, {ref=props.forwardedRef}))
    end

    local RefForwardingComponent = React.forwardRef(function(props, ref)
      return React.createElement(Wrapper, Cryo.Dictionary.join(props, {forwardedRef=ref}))
    end)

    local ref = React.createRef()

    ReactNoop.render(React.createElement(RefForwardingComponent, {ref=ref, value=123}))
    jestExpect(Scheduler).toFlushAndYield({123})
    -- ROBLOX FIXME: When instanceof is implemented, use it
    -- jestExpect(Object.instanceof(ref.current, Child)).toBe(true)
    jestExpect(getmetatable(ref.current).__index).toBe(Child)
  end)

  it("should forward a ref for multiple children", function()
    local Child = React.Component:extend("Child")
    function Child:render()
      Scheduler.unstable_yieldValue(self.props.value)
      return nil
    end

    local function Wrapper(props)
    -- ROBLOX TODO: Erroneous warnings in dev here
    return React.createElement(Child, Cryo.Dictionary.join(props, {ref=props.forwardedRef}))
    end

    local RefForwardingComponent = React.forwardRef(function(props, ref)
      return React.createElement(Wrapper, Cryo.Dictionary.join(props, {forwardedRef=ref}))
    end)

    local ref = React.createRef()

    ReactNoop.render(
      React.createElement("div", {},
        React.createElement("div"),
        React.createElement(RefForwardingComponent, {ref=ref, value=123}),
        React.createElement("div")
      )
    )
    jestExpect(Scheduler).toFlushAndYield({123})
    -- ROBLOX FIXME: When instanceof is implemented, use it
    -- jestExpect(Object.instanceof(ref.current, Child)).toBe(true)
    jestExpect(getmetatable(ref.current).__index).toBe(Child)
  end)

  it("should maintain child instance and ref through updates", function()
    local Child = React.Component:extend("Child")
    function Child:render()
      Scheduler.unstable_yieldValue(self.props.value)
      return nil
    end

    local function Wrapper(props)
      -- ROBLOX TODO: Erroneous warnings in dev here
      return React.createElement(Child, Cryo.Dictionary.join(props, {ref=props.forwardedRef}))
    end

    local RefForwardingComponent = React.forwardRef(function(props, ref)
      return React.createElement(Wrapper, Cryo.Dictionary.join(props, {forwardedRef=ref}))
    end)

    local setRefCount = 0
    local ref

    local setRef = function(r)
      setRefCount += 1
      ref = r
    end

    ReactNoop.render(React.createElement(RefForwardingComponent, {ref=setRef, value=123}))
    jestExpect(Scheduler).toFlushAndYield({123})
    -- ROBLOX FIXME: When instanceof is implemented, use it
    -- jestExpect(Object.instanceof(ref, Child)).toBe(true)
    jestExpect(getmetatable(ref).__index).toBe(Child)
    jestExpect(setRefCount).toBe(1)
    ReactNoop.render(React.createElement(RefForwardingComponent, {ref=setRef, value=456}))
    jestExpect(Scheduler).toFlushAndYield({456})
    -- ROBLOX FIXME: When instanceof is implemented, use it
    -- jestExpect(Object.instanceof(ref, Child)).toBe(true)
    jestExpect(getmetatable(ref).__index).toBe(Child)
    jestExpect(setRefCount).toBe(1)
  end)

  it("should not break lifecycle error handling", function()
    local ErrorBoundary = React.Component:extend("ErrorBoundary")
    function ErrorBoundary:init()
      self.state = {error=nil}
    end
    function ErrorBoundary:componentDidCatch(error_)
      Scheduler.unstable_yieldValue("ErrorBoundary.componentDidCatch")
      self:setState({error=error_})
    end
    function ErrorBoundary:render()
      if self.state.error then
        Scheduler.unstable_yieldValue("ErrorBoundary.render: catch")
        return nil
      end
      Scheduler.unstable_yieldValue("ErrorBoundary.render: try")
      return self.props.children
    end

    local BadRender = React.Component:extend("BadRender")
    function BadRender:render()
      Scheduler.unstable_yieldValue("BadRender throw")
      error(Error.new("oops!"))
    end

    local function Wrapper(props)
      local forwardedRef = props.forwardedRef
      Scheduler.unstable_yieldValue("Wrapper")
      return React.createElement(BadRender, Cryo.Dictionary.join(props, {ref=forwardedRef}))
    end

    local RefForwardingComponent = React.forwardRef(function(props, ref)
      return React.createElement(Wrapper, Cryo.Dictionary.join(props, {forwardedRef=ref}))
    end)

    local ref = React.createRef()

    ReactNoop.render(
      React.createElement(ErrorBoundary, nil,
        React.createElement(RefForwardingComponent, {ref=ref})
      )
    )
    jestExpect(Scheduler).toFlushAndYield({
      "ErrorBoundary.render: try",
      "Wrapper",
      "BadRender throw",

      -- React retries one more time
      "ErrorBoundary.render: try",
      "Wrapper",
      "BadRender throw",

      -- Errored again on retry. Now handle it.
      "ErrorBoundary.componentDidCatch", -- ROBLOX FIXME: not yielding these last two
      "ErrorBoundary.render: catch",
    })
    jestExpect(ref.current).toBe(nil)
  end)

  it("should not re-run the render callback on a deep setState", function()
    local inst

    local Inner = React.Component:extend("Inner")
    function Inner:render()
      Scheduler.unstable_yieldValue("Inner")
      inst = self
      return React.createElement("div", {ref=self.props.forwardedRef})
    end

    local function Middle(props)
      Scheduler.unstable_yieldValue("Middle")
      return React.createElement(Inner, props)
    end

    local Forward = React.forwardRef(function(props, ref)
      Scheduler.unstable_yieldValue("Forward")
      return React.createElement(Middle, Cryo.Dictionary.join(props, {forwardedRef=ref}))
    end)

    local function App()
      Scheduler.unstable_yieldValue("App")
      return React.createElement(Forward)
    end

    ReactNoop.render(React.createElement(App))
    jestExpect(Scheduler).toFlushAndYield({"App", "Forward", "Middle", "Inner"})

    inst:setState({})
    jestExpect(Scheduler).toFlushAndYield({"Inner"})
  end)
end
