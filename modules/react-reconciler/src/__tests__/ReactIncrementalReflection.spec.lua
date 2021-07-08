-- upstream: https://github.com/facebook/react/blob/d13f5b9538e48f74f7c571ef3cde652ca887cca0/packages/react-reconciler/src/__tests__/ReactIncrementalReflection-test.js
-- * Copyright (c) Facebook, Inc. and its affiliates.
-- *
-- * This source code is licensed under the MIT license found in the
-- * LICENSE file in the root directory of this source tree.
-- *
-- * @emails react-core
-- * @jest-environment node
--

local Packages = script.Parent.Parent.Parent
local React
local ReactNoop
local Scheduler
local console = require(Packages.Shared).console

return function()
    local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect

    describe('ReactIncrementalReflection', function()
        local RobloxJest = require(Packages.Dev.RobloxJest)
        beforeEach(function()
            RobloxJest.resetModules()

            React = require(Packages.React)
            ReactNoop = require(Packages.Dev.ReactNoopRenderer)
            Scheduler = require(Packages.Scheduler)
        end)

        local function div(...)
            local _, _, children = ...
            -- deviation: commented out unused children processing logic
            -- children = children.map(function(c)
            --     return(function()
            --         if typeof(c) == 'string' then
            --             return{
            --                 text = c,
            --                 hidden = false,
            --             }
            --         end

            --         return c
            --     end)()
            -- end)

            return{
                type = 'div',
                children = children,
                prop = nil,
                hidden = false,
            }
        end
        local function span(prop)
            return{
                type = 'span',
                children = {},
                prop = prop,
                hidden = false,
            }
        end

        it('handles isMounted even when the initial render is deferred', function()
            local instances = {}
            local Component = React.Component:extend("Component")

            function Component:_isMounted()
                -- No longer a public API, but we can test that it works internally by
                -- reaching into the updater.
                return self.updater.isMounted(self)
            end
            function Component:UNSAFE_componentWillMount()
                table.insert(instances, self)
                Scheduler.unstable_yieldValue('componentWillMount: ' .. tostring(self:_isMounted()))
            end
            function Component:componentDidMount()
                Scheduler.unstable_yieldValue('componentDidMount: ' .. tostring(self:_isMounted()))
            end
            function Component:render()
                return React.createElement("span")
            end

            local function Foo()
                return React.createElement(Component, nil)
            end

            ReactNoop.render(React.createElement(Foo))

            -- Render part way through but don't yet commit the updates.
            jestExpect(Scheduler).toFlushAndYieldThrough({
                'componentWillMount: false',
            })
            jestExpect(instances[1]:_isMounted()).toBe(false)

            -- Render the rest and commit the updates.
            jestExpect(function()
                return jestExpect(Scheduler).toFlushAndYield({
                    'componentDidMount: true',
                })
            end).toErrorDev('Using UNSAFE_componentWillMount in strict mode is not recommended', {withoutStack = true})
            jestExpect(instances[1]:_isMounted()).toBe(true)
        end)

        it('handles isMounted when an unmount is deferred', function()
            local instances = {}
            local Component = React.Component:extend('Component')

            function Component:init()
                self.state = {}
            end

            function Component:_isMounted()
                return self.updater.isMounted(self)
            end
            function Component:UNSAFE_componentWillMount()
                table.insert(instances, self)
            end
            function Component:componentWillUnmount()
                Scheduler.unstable_yieldValue('componentWillUnmount: ' .. tostring(self:_isMounted()))
            end
            function Component:render()
                Scheduler.unstable_yieldValue('Component')
                return React.createElement("span", nil)
            end

            local function Other()
                Scheduler.unstable_yieldValue('Other')
                return React.createElement("span", nil)
            end

            local function Foo(props)
                if props.mount then
                    return React.createElement(Component)
                end
                return React.createElement(Other)
            end

            ReactNoop.render(React.createElement(Foo, {mount = true}))
            jestExpect(function()
                return jestExpect(Scheduler).toFlushAndYield({
                    'Component',
                })
            end).toErrorDev('Using UNSAFE_componentWillMount in strict mode is not recommended', {withoutStack = true})

            jestExpect(instances[1]:_isMounted()).toBe(true)

            ReactNoop.render(React.createElement(Foo, {mount = false}))
            -- Render part way through but don't yet commit the updates so it is not
            -- fully unmounted yet.
            jestExpect(Scheduler).toFlushAndYieldThrough({
                'Other',
            })

            jestExpect(instances[1]:_isMounted()).toBe(true)

            -- Finish flushing the unmount.
            jestExpect(Scheduler).toFlushAndYield({
                'componentWillUnmount: true',
            })
            jestExpect(instances[1]:_isMounted()).toBe(false)
        end)
        -- ROBLOX TODO: 292: gets "componentDidMount", but not the inner span. maybe ReactFeatureFlags need alignment for tests?
        xit('finds no node before insertion and correct node before deletion', function()
            local classInstance = nil
            local function findInstance(inst)
                -- We ignore warnings fired by findInstance because we are testing
                -- that the actual behavior still works as expected even though it
                -- is deprecated.
                local oldConsoleError = console.error
                console.error = nil
                local ok, result = pcall(function()
                    -- ROBLOX FIXME: always returns nil because subtreeFlags don't match upstream while finding fiber in getNearestMountedFiber
                    return ReactNoop.findInstance(inst)
                end)
                console.error = oldConsoleError
                if ok then
                    return result
                else
                    error(result)
                end
            end

            local Component = React.Component:extend("Component")

            function Component:UNSAFE_componentWillMount()
                classInstance = self
                Scheduler.unstable_yieldValue({
                    'componentWillMount',
                    findInstance(self),
                })
            end
            function Component:componentDidMount()
                Scheduler.unstable_yieldValue({
                    'componentDidMount',
                    findInstance(self),
                })
            end
            function Component:UNSAFE_componentWillUpdate()
                Scheduler.unstable_yieldValue({
                    'componentWillUpdate',
                    findInstance(self),
                })
            end
            function Component:componentDidUpdate()
                Scheduler.unstable_yieldValue({
                    'componentDidUpdate',
                    findInstance(self),
                })
            end
            function Component:componentWillUnmount()
                Scheduler.unstable_yieldValue({
                    'componentWillUnmount',
                    findInstance(self),
                })
            end
            function Component:render()
                Scheduler.unstable_yieldValue('render')
                return (
                    function ()
                        if self.props.step < 2 then
                            return React.createElement(span, {
                                ref = function(ref)
                                    self.span = ref
                                    return ref
                                end,
                            })
                        elseif self.props.step == 2 then
                            return React.createElement(div, {
                                ref = function(ref)
                                    self.div = ref
                                    return ref
                                end
                            })
                        elseif self.props.step == 3 then
                            return nil
                        elseif self.props.step == 4 then
                            return React.createElement(div, {
                                ref = function(ref)
                                    self.span = ref
                                    return ref
                                end,
                            })
                        else
                            return nil
                        end
                    end)
            end

            local function Sibling()
                -- Sibling is used to assert that we've rendered past the first component.
                Scheduler.unstable_yieldValue('render sibling')
                return React.createElement(span)
            end

            local function Foo(props)
                return{
                    React.createElement(Component, {
                        key = 'a',
                        step = props.step,
                    }),
                    React.createElement(Sibling, {
                        key = 'b',
                    }),
                }
            end

            ReactNoop.render(React.createElement(Foo, {step = 0}))
             -- Flush past Component but don't complete rendering everything yet.
            jestExpect(Scheduler).toFlushAndYieldThrough({
                {
                    'componentWillMount',
                    nil,
                },
                'render',
                'render sibling',
            })

            jestExpect(classInstance).toBeDefined()
            -- The instance has been complete but is still not committed so it should
            -- not find any host nodes in it.
            jestExpect(findInstance(classInstance)).toBe(nil)
            jestExpect(function()
                -- ROBLOX FIXME: toFlushAndYield gets an empty array
                return jestExpect(Scheduler).toFlushAndYield({
                    {
                        'componentDidMount',
                        span(),
                    },
                })
            end).toErrorDev({
                'Using UNSAFE_componentWillMount in strict mode is not recommended',
                'Using UNSAFE_componentWillUpdate in strict mode is not recommended',
            }, {withoutStack = true})

            local hostSpan = classInstance.span
            jestExpect(hostSpan).toBeDefined()

            jestExpect(findInstance(classInstance)).toBe(hostSpan)

            -- Flush next step which will cause an update but not yet render a new host
            -- node.
            ReactNoop.render(React.createElement(Foo, {step = 1}))
            jestExpect(Scheduler).toFlushAndYield({
                {
                    'componentWillUpdate',
                    hostSpan,
                },
                'render',
                'render sibling',
                {
                    'componentDidUpdate',
                    hostSpan,
                },
            })

            jestExpect(ReactNoop.findInstance(classInstance)).toBe(hostSpan)

            -- The next step will render a new host node but won't get committed yet.
            -- We expect this to mutate the original Fiber.
            ReactNoop.render(React.createElement(Foo, {step = 2}))
            jestExpect(Scheduler).toFlushAndYieldThrough({
                {
                    'componentWillUpdate',
                    hostSpan,
                },
                'render',
                'render sibling',
            })

            -- This should still be the host span.
            jestExpect(ReactNoop.findInstance(classInstance)).toBe(hostSpan)

            -- When we finally flush the tree it will get committed.
            jestExpect(Scheduler).toFlushAndYield({
                {
                    'componentDidUpdate',
                    div(),
                },
            })

            local hostDiv = classInstance.div
            jestExpect(hostDiv).toBeDefined()
            jestExpect(hostSpan).never.toBe(hostDiv)

            -- We should now find the new host node.
            jestExpect(ReactNoop.findInstance(classInstance)).toBe(hostDiv)

            -- Render to null but don't commit it yet.
            ReactNoop.render(React.createElement(Foo, {step = 3}))
            jestExpect(Scheduler).toFlushAndYieldThrough({
                {
                    'componentWillUpdate',
                    hostDiv,
                },
                'render',
                'render sibling',
            })

            -- This should still be the host div since the deletion is not committed.
            jestExpect(ReactNoop.findInstance(classInstance)).toBe(hostDiv)

            jestExpect(Scheduler).toFlushAndYield({
                {
                    'componentDidUpdate',
                    nil,
                },
            })

            -- This should still be the host div since the deletion is not committed.
            jestExpect(ReactNoop.findInstance(classInstance)).toBe(nil)

            -- Render a div again
            ReactNoop.render(React.createElement(Foo, {step = 4}))
            jestExpect(Scheduler).toFlushAndYield({
                {
                    'componentWillUpdate',
                    nil,
                },
                'render',
                'render sibling',
                {
                    'componentDidUpdate',
                    div(),
                },
            })

            -- Unmount the component.
            ReactNoop.render({})
            jestExpect(Scheduler).toFlushAndYield({
                {
                    'componentWillUnmount',
                    hostDiv,
                },
            })
        end)
    end)
end