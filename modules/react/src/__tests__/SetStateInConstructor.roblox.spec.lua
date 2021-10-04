-- ROBLOX: tests deviant logic for Roblox react which permits use of setState() in component constructor

return function()
    local Packages = script.Parent.Parent.Parent
    local React
    local RobloxJest = require(Packages.Dev.RobloxJest)
	local JestGlobals = require(Packages.Dev.JestGlobals)
    local jestExpect = JestGlobals.expect
    local ReactNoop

    beforeEach(function()
		RobloxJest.resetModules()
        ReactNoop = require(Packages.Dev.ReactNoopRenderer)
        React = require(script.Parent.Parent)


	end)

    local function initTests(defineInitMethod, name)
        it("has correct state populated in render w/ " .. name, function()
            local Component = React.Component:extend("Component")

            defineInitMethod(Component, "name", "Mike")

            local capturedState

            function Component:render()
              capturedState = self.state
            end

            ReactNoop.act(function()
                ReactNoop.render(React.createElement(Component))
            end)

            jestExpect(capturedState).toEqual({
                name = "Mike"
            })

        end)

        it("has derived state populated in render w/ " .. name, function()
            local Component = React.Component:extend("Component")

            defineInitMethod(Component, "name", "Mike")

            local capturedState

            function Component:render()
                capturedState = self.state
            end

            function Component.getDerivedStateFromProps(props, state)
                return {
                    name = state.name,
                    surname = props.surname
                }
            end

            ReactNoop.act(function()
                ReactNoop.render(React.createElement(Component, {surname = "Smith"}))
            end)

            jestExpect(capturedState).toEqual({
                name = "Mike",
                surname = "Smith"
            })
        end)

        it("updates state correctly w/ " .. name, function()
            local Component = React.Component:extend("Component")

            defineInitMethod(Component, "name", "Mike")

            local capturedState
            local capturedSetState

            function Component:render()
                capturedSetState = function(...)
                    self:setState(...)
                end
                capturedState = self.state
            end

            ReactNoop.act(function()
                ReactNoop.render(React.createElement(Component))
            end)

            jestExpect(capturedState).toEqual({
                name = "Mike",
            })

            ReactNoop.act(function()
                capturedSetState({
                    surname = "Smith"
                })
            end)

            jestExpect(capturedState).toEqual({
                name = "Mike",
                surname = "Smith"
            })
        end)

        it("updates state correctly with functional setState w/ " .. name, function()
            local Component = React.Component:extend("Component")

            defineInitMethod(Component, "count", 0)

            local capturedState
            local capturedSetState

            function Component:render()
                capturedSetState = function(...)
                    self:setState(...)
                end
                capturedState = self.state
            end

            ReactNoop.act(function()
                ReactNoop.render(React.createElement(Component))
            end)

            jestExpect(capturedState).toEqual({
                count = 0,
            })

            ReactNoop.act(function()
                capturedSetState(function(state, props)
                    return {
                        count = state.count + 1
                    }
                end)
            end)

            jestExpect(capturedState).toEqual({
                count = 1
            })
        end)
        it("updates a pure component when state changes w/ " .. name, function()
            local Component = React.PureComponent:extend("Component")

            defineInitMethod(Component, "name", "Mike")

            local capturedState
            local capturedSetState
            local renderCount = 0

            function Component:render()
                capturedSetState = function(...)
                    self:setState(...)
                end
                capturedState = self.state
                renderCount += 1
            end

            ReactNoop.act(function()
                ReactNoop.render(React.createElement(Component))
            end)

            jestExpect(capturedState).toEqual({
                name = "Mike",
            })

            local renderCountAfterFirst = renderCount

            ReactNoop.act(function()
                capturedSetState({
                    name = "Bob"
                })
            end)

            jestExpect(capturedState).toEqual({
                name = "Bob"
            })

            jestExpect(renderCountAfterFirst < renderCount).toEqual(true)
        end)
        it("does not update a pure component with a no-op setState w/ " .. name, function()
            local Component = React.PureComponent:extend("Component")

            defineInitMethod(Component, "name", "Mike")

            local capturedState
            local capturedSetState
            local renderCount = 0

            function Component:render()
                capturedSetState = function(...)
                    self:setState(...)
                end
                capturedState = self.state
                renderCount += 1
            end

            ReactNoop.act(function()
                ReactNoop.render(React.createElement(Component))
            end)

            jestExpect(capturedState).toEqual({
                name = "Mike",
            })

            local renderCountAfterFirst = renderCount

            ReactNoop.act(function()
                capturedSetState({
                    name = "Mike"
                })
            end)

            jestExpect(capturedState).toEqual({
                name = "Mike"
            })

            jestExpect(renderCountAfterFirst).toEqual(renderCount)
        end)
    end

    -- runs tests using setState in constructor
    initTests(function(component, key, value)
        function component:init()
            self:setState({
                [key] = value
            })
        end
    end, "setState in constructor")

    -- runs tests using self.state in constructor
    initTests(function(component, key, value)
        function component:init()
            self.state = {
                [key] = value
            }
        end
    end, "self.state in constructor")
end