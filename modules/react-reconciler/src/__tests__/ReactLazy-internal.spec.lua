-- local PropTypes
local React
local ReactTestRenderer
local Scheduler
local ReactFeatureFlags
local Suspense
local lazy
local Packages = script.Parent.Parent.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
local Error = LuauPolyfill.Error
local setTimeout = LuauPolyfill.setTimeout

local function normalizeCodeLocInfo(str)
	if typeof(str) ~= "string" then
		return str
	end

	str = str:gsub("Check your code at .*:%d+", "Check your code at **")
	-- ROBLOX deviation: In roblox/luau, we're using the stack frame from luau,
	-- which looks like:
	--     in Component (at ModulePath.FileName.lua:123)
	return (str:gsub("\n    in ([%w%-%._]+)[^\n]*", "\n    in %1 (at **)"))
end

return function()
    local RobloxJest = require(Packages.Dev.RobloxJest)
    local Promise = require(Packages.Promise)
    local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect

    describe('ReactLazy', function()
        beforeEach(function()
            RobloxJest.resetModules()

            ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
            ReactFeatureFlags.replayFailedUnitOfWorkWithInvokeGuardedCallback = false
            -- PropTypes = require('prop-types');
            React = require(Packages.React)
            Suspense = React.Suspense
            lazy = React.lazy
            ReactTestRenderer = require(Packages.Dev.ReactTestRenderer)
            Scheduler = require(Packages.Scheduler)
        end)

        -- local verifyInnerPropTypesAreChecked = _async(function(Add)
        --     local LazyAdd = lazy(function()
        --         return fakeImport(Add)
        --     end)

        --     jestExpect(function()
        --         LazyAdd.propTypes = {}
        --     end).toErrorDev('React.lazy(...): It is not supported to assign `propTypes` to ' + 'a lazy component import. Either specify them where the component ' + 'is defined, or create a wrapping component around it.', {withoutStack = true})

        --     local root = ReactTestRenderer.create(React.createElement(Suspense, {
        --         fallback = React.createElement(Text, {
        --             text = 'Loading...',
        --         }),
        --     }, React.createElement(LazyAdd, {
        --         inner = '2',
        --         outer = '2',
        --     })), {unstable_isConcurrent = true})

        --     jestExpect(Scheduler).toFlushAndYield({
        --         'Loading...',
        --     })
        --     jestExpect(root).not.toMatchRenderedOutput('22')

        --     return _await(Promise.resolve(), function()
        --         jestExpect(function()
        --             Scheduler.unstable_flushAll()
        --         end).toErrorDev({
        --             'Invalid prop `inner` of type `string` supplied to `Add`, expected `number`.',
        --         })
        --         jestExpect(root).toMatchRenderedOutput('22')
        --         jestExpect(function()
        --             root.update(React.createElement(Suspense, {
        --                 fallback = React.createElement(Text, {
        --                     text = 'Loading...',
        --                 }),
        --             }, React.createElement(LazyAdd, {
        --                 inner = false,
        --                 outer = false,
        --             })))
        --             jestExpect(Scheduler).toFlushWithoutYielding()
        --         end).toErrorDev('Invalid prop `inner` of type `boolean` supplied to `Add`, expected `number`.')
        --         jestExpect(root).toMatchRenderedOutput('0')
        --     end)
        -- end)

        local fakeImport = function(result)
            -- ROBLOX FIXME: delay(0) because resolved promises are andThen'd on the same tick cycle
            -- remove once addressed in polyfill
            return Promise.delay(0):andThen(function()
                return {default = result}
            end)
        end

        local function Text(props)
            Scheduler.unstable_yieldValue(props.text)

            return props.text
        end

        local delay_ = function(ms)
            return Promise.new(function(resolve)
                return setTimeout(function()
                    return resolve()
                end, ms)
            end)
        end

        it('suspends until module has loaded', function()
            local LazyText = lazy(function()
                return fakeImport(Text)
            end)
            local root = ReactTestRenderer.create(
                React.createElement(Suspense, {
                    fallback = React.createElement(Text, {
                        text = 'Loading...',
                    }),
                }, React.createElement(LazyText, {
                    text = 'Hi',
            })), {unstable_isConcurrent = true})

            jestExpect(Scheduler).toFlushAndYield({
                'Loading...',
            })

            jestExpect(root).never.toMatchRenderedOutput('Hi')

            -- ROBLOX FIXME: delay by one frame is current best translation of `await Promise.resolve()`
            Promise.delay(0):await()

            jestExpect(Scheduler).toFlushAndYield({
                'Hi',
            })
            jestExpect(root).toMatchRenderedOutput('Hi')

            -- Should not suspend on update
            root.update(React.createElement(Suspense, {
                fallback = React.createElement(Text, {
                    text = 'Loading...',
                }),
            }, React.createElement(LazyText, {
                text = 'Hi again',
            })))
            jestExpect(Scheduler).toFlushAndYield({
                'Hi again',
            })
            jestExpect(root).toMatchRenderedOutput('Hi again')

        end)
        it('can resolve synchronously without suspending', function()
            local LazyText = lazy(function()
                return {
                    andThen = function(self, cb)
                        cb({default = Text})
                    end,
                }
            end)
            local root = ReactTestRenderer.create(React.createElement(Suspense, {
                fallback = React.createElement(Text, {
                    text = 'Loading...',
                }),
            }, React.createElement(LazyText, {
                text = 'Hi',
            })))

            jestExpect(Scheduler).toHaveYielded({
                'Hi',
            })
            jestExpect(root).toMatchRenderedOutput('Hi')
        end)
        it('can reject synchronously without suspending', function()
            local LazyText = lazy(function()
                return {
                    andThen = function(self, resolve, reject)
                        reject(Error('oh no'))
                    end,
                }
            end)
            local ErrorBoundary = React.Component:extend("ErrorBoundary")

            function ErrorBoundary:init()
                self.state = {}
            end
            function ErrorBoundary.getDerivedStateFromError(error_)
                return {
                    message = error_.message,
                }
            end
            function ErrorBoundary:render()
                    if self.state.message then
                        return('Error: %s'):format(self.state.message)
                    end
                    return self.props.children
            end

            local root = ReactTestRenderer.create(React.createElement(ErrorBoundary, nil, React.createElement(Suspense, {
                fallback = React.createElement(Text, {
                    text = 'Loading...',
                }),
            }, React.createElement(LazyText, {
                text = 'Hi',
            }))))

            jestExpect(Scheduler).toHaveYielded({})
            jestExpect(root).toMatchRenderedOutput('Error: oh no')
        end)
        it('multiple lazy components', function()
            local function Foo()
                return React.createElement(Text, {
                    text = 'Foo',
                })
            end
            local function Bar()
                return React.createElement(Text, {
                    text = 'Bar',
                })
            end

            local promiseForFoo = delay_(100):andThen(function()
                return fakeImport(Foo)
            end)
            local promiseForBar = delay_(500):andThen(function()
                return fakeImport(Bar)
            end)
            local LazyFoo = lazy(function()
                return promiseForFoo
            end)
            local LazyBar = lazy(function()
                return promiseForBar
            end)
            local root = ReactTestRenderer.create(React.createElement(Suspense, {
                fallback = React.createElement(Text, {
                    text = 'Loading...',
                }),
            }, React.createElement(LazyFoo, nil), React.createElement(LazyBar, nil)), {unstable_isConcurrent = true})

            jestExpect(Scheduler).toFlushAndYield({
                'Loading...',
            })
            jestExpect(root).never.toMatchRenderedOutput('FooBar')
            RobloxJest.advanceTimersByTime(100)

            promiseForFoo:await()
            jestExpect(Scheduler).toFlushAndYield({
                'Foo',
            })
            jestExpect(root).never.toMatchRenderedOutput('FooBar')
            RobloxJest.advanceTimersByTime(500)

            promiseForBar:await()

            jestExpect(Scheduler).toFlushAndYield({
                'Foo',
                'Bar',
            })
            jestExpect(root).toMatchRenderedOutput('FooBar')
        end)
        -- it('does not support arbitrary promises, only module objects', _async(function()
        --     spyOnDev(console, 'error')

        --     local LazyText = lazy(function()
        --         return _await(Text)
        --     end)
        --     local root = ReactTestRenderer.create(React.createElement(Suspense, {
        --         fallback = React.createElement(Text, {
        --             text = 'Loading...',
        --         }),
        --     }, React.createElement(LazyText, {
        --         text = 'Hi',
        --     })), {unstable_isConcurrent = true})

        --     jestExpect(Scheduler).toFlushAndYield({
        --         'Loading...',
        --     })
        --     jestExpect(root).not.toMatchRenderedOutput('Hi')

        --     return _await(Promise.resolve(), function()
        --         if __DEV__ then
        --             jestExpect(console.error).toHaveBeenCalledTimes(1)
        --             jestExpect(console.error.calls.argsFor(0)[0]).toContain('Expected the result of a dynamic import() call')
        --         end

        --         jestExpect(Scheduler).toFlushAndThrow('Element type is invalid')
        --     end)
        -- end))
        it('throws if promise rejects', function()
            local badImport = function()
                 -- ROBLOX FIXME: delay(0) because resolved promises are andThen'd on the same tick cycle
                -- remove once addressed in polyfill
                return Promise.delay(0):andThen(function()
                    error(Error('Bad network'))
                end)
            end
            local LazyText = lazy(badImport)
            local root = ReactTestRenderer.create(React.createElement(Suspense, {
                fallback = React.createElement(Text, {
                    text = 'Loading...',
                }),
            }, React.createElement(LazyText, {
                text = 'Hi',
            })), {unstable_isConcurrent = true})

            -- ROBLOX TODO: this gets the 'Bad Network' error, Suspense fallback 'Loading...' not rendered first
            jestExpect(Scheduler).toFlushAndYield({
                'Loading...',
            })
            jestExpect(root).never.toMatchRenderedOutput('Hi')

            local _, _ = pcall(function()
                -- ROBLOX FIXME: delay by one frame is current best translation of `await Promise.resolve()`
                Promise.delay(0):await()
            end)

            jestExpect(Scheduler).toFlushAndThrow('Bad network')

        end)

        it('mount and reorder', function()
            local Child = React.Component:extend("Child")

            function Child:componentDidMount()
                Scheduler.unstable_yieldValue('Did mount: ' .. self.props.label)
            end
            function Child:componentDidUpdate()
                Scheduler.unstable_yieldValue('Did update: ' .. self.props.label)
            end
            function Child:render()
                return React.createElement(Text, {
                    text = self.props.label,
                })
            end

            local LazyChildA = lazy(function()
                return fakeImport(Child)
            end)
            local LazyChildB = lazy(function()
                return fakeImport(Child)
            end)

            local function Parent(props)
                local children
                if props.swap then
                    children = {
                        React.createElement(LazyChildB, {
                            key = 'B',
                            label = 'B',
                        }),
                        React.createElement(LazyChildA, {
                            key = 'A',
                            label = 'A',
                        }),
                    }
                else
                    children = {
                        React.createElement(LazyChildA, {
                            key = 'A',
                            label = 'A',
                        }),
                        React.createElement(LazyChildB, {
                            key = 'B',
                            label = 'B',
                        }),
                    }
                end
                return React.createElement(Suspense, {
                    fallback = React.createElement(Text, {
                        text = 'Loading...',
                    }),
                }, children)
            end

            local root = ReactTestRenderer.create(React.createElement(Parent, {swap = false}), {unstable_isConcurrent = true})


            jestExpect(Scheduler).toFlushAndYield({
                'Loading...',
            })
            jestExpect(root).never.toMatchRenderedOutput('AB')

            -- ROBLOX FIXME: these are not Promises, so I'm not sure what usptream awaiting them means
            -- LazyChildA:await()
            -- LazyChildB:await()
            -- ROBLOX FIXME: these awaits let the test get further, but values in mountLazyComponent() are way off
            Promise.delay(0):await()
            Promise.delay(0):await()

            jestExpect(Scheduler).toFlushAndYield({
                'A',
                'B',
                'Did mount: A',
                'Did mount: B',
            })
            jestExpect(root).toMatchRenderedOutput('AB')

            -- Swap the potsition of A and B
            root.update(React.createElement(Parent, {swap = true}))
            jestExpect(Scheduler).toFlushAndYield({
                'B',
                'A',
                'Did update: B',
                'Did update: A',
            })
            jestExpect(root).toMatchRenderedOutput('BA')
        end)
        -- it('resolves defaultProps, on mount and update', _async(function()
        --     local function T(props)
        --         return React.createElement(Text, props)
        --     end

        --     T.defaultProps = {
        --         text = 'Hi',
        --     }

        --     local LazyText = lazy(function()
        --         return fakeImport(T)
        --     end)
        --     local root = ReactTestRenderer.create(React.createElement(Suspense, {
        --         fallback = React.createElement(Text, {
        --             text = 'Loading...',
        --         }),
        --     }, React.createElement(LazyText, nil)), {unstable_isConcurrent = true})

        --     jestExpect(Scheduler).toFlushAndYield({
        --         'Loading...',
        --     })
        --     jestExpect(root).not.toMatchRenderedOutput('Hi')

        --     return _await(Promise.resolve(), function()
        --         jestExpect(Scheduler).toFlushAndYield({
        --             'Hi',
        --         })
        --         jestExpect(root).toMatchRenderedOutput('Hi')

        --         T.defaultProps = {
        --             text = 'Hi again',
        --         }

        --         root.update(React.createElement(Suspense, {
        --             fallback = React.createElement(Text, {
        --                 text = 'Loading...',
        --             }),
        --         }, React.createElement(LazyText, nil)))
        --         jestExpect(Scheduler).toFlushAndYield({
        --             'Hi again',
        --         })
        --         jestExpect(root).toMatchRenderedOutput('Hi again')
        --     end)
        -- end))
        -- it('resolves defaultProps without breaking memoization', _async(function()
        --     local function LazyImpl(props)
        --         Scheduler.unstable_yieldValue('Lazy')

        --         return React.createElement(React.Fragment, nil, React.createElement(Text, {
        --             text = props.siblingText,
        --         }), props.children)
        --     end

        --     LazyImpl.defaultProps = {
        --         siblingText = 'Sibling',
        --     }

        --     local Lazy = lazy(function()
        --         return fakeImport(LazyImpl)
        --     end)
        --     local Stateful = {}
        --     local StatefulMetatable = {__index = Stateful}

        --     function Stateful.new()
        --         local self = setmetatable({}, StatefulMetatable)
        --         local _temp2

        --         return
        --     end
        --     function Stateful:render()
        --         return React.createElement(Text, {
        --             text = self.state.text,
        --         })
        --     end

        --     local stateful = React.createRef(nil)
        --     local root = ReactTestRenderer.create(React.createElement(Suspense, {
        --         fallback = React.createElement(Text, {
        --             text = 'Loading...',
        --         }),
        --     }, React.createElement(Lazy, nil, React.createElement(Stateful, {ref = stateful}))), {unstable_isConcurrent = true})

        --     jestExpect(Scheduler).toFlushAndYield({
        --         'Loading...',
        --     })
        --     jestExpect(root).not.toMatchRenderedOutput('SiblingA')

        --     return _await(Promise.resolve(), function()
        --         jestExpect(Scheduler).toFlushAndYield({
        --             'Lazy',
        --             'Sibling',
        --             'A',
        --         })
        --         jestExpect(root).toMatchRenderedOutput('SiblingA')
        --         stateful.current.setState({
        --             text = 'B',
        --         })
        --         jestExpect(Scheduler).toFlushAndYield({
        --             'B',
        --         })
        --         jestExpect(root).toMatchRenderedOutput('SiblingB')
        --     end)
        -- end))
        -- it('resolves defaultProps without breaking bailout due to unchanged props and state, #17151', _async(function()
        --     local LazyImpl = {}
        --     local LazyImplMetatable = {__index = LazyImpl}

        --     function LazyImpl:render()
        --         local text = ('%s: %s'):format(self.props.label, self.props.value)

        --         return React.createElement(Text, {text = text})
        --     end

        --     LazyImpl.defaultProps = {value = 0}

        --     local Lazy = lazy(function()
        --         return fakeImport(LazyImpl)
        --     end)
        --     local instance1 = React.createRef(nil)
        --     local instance2 = React.createRef(nil)
        --     local root = ReactTestRenderer.create(React.createElement(React.Fragment, nil, React.createElement(LazyImpl, {
        --         ref = instance1,
        --         label = 'Not lazy',
        --     }), React.createElement(Suspense, {
        --         fallback = React.createElement(Text, {
        --             text = 'Loading...',
        --         }),
        --     }, React.createElement(Lazy, {
        --         ref = instance2,
        --         label = 'Lazy',
        --     }))), {unstable_isConcurrent = true})

        --     jestExpect(Scheduler).toFlushAndYield({
        --         'Not lazy: 0',
        --         'Loading...',
        --     })
        --     jestExpect(root).not.toMatchRenderedOutput('Not lazy: 0Lazy: 0')

        --     return _await(Promise.resolve(), function()
        --         jestExpect(Scheduler).toFlushAndYield({
        --             'Lazy: 0',
        --         })
        --         jestExpect(root).toMatchRenderedOutput('Not lazy: 0Lazy: 0')
        --         instance1.current.setState(nil)
        --         jestExpect(Scheduler).toFlushAndYield({})
        --         jestExpect(root).toMatchRenderedOutput('Not lazy: 0Lazy: 0')
        --         instance2.current.setState(nil)
        --         jestExpect(Scheduler).toFlushAndYield({})
        --         jestExpect(root).toMatchRenderedOutput('Not lazy: 0Lazy: 0')
        --     end)
        -- end))
        -- it('resolves defaultProps without breaking bailout in PureComponent, #17151', _async(function()
        --     local LazyImpl = {}
        --     local LazyImplMetatable = {__index = LazyImpl}

        --     function LazyImpl.new()
        --         local self = setmetatable({}, LazyImplMetatable)
        --         local _temp3

        --         return
        --     end
        --     function LazyImpl:render()
        --         local text = ('%s: %s'):format(self.props.label, self.props.value)

        --         return React.createElement(Text, {text = text})
        --     end

        --     LazyImpl.defaultProps = {value = 0}

        --     local Lazy = lazy(function()
        --         return fakeImport(LazyImpl)
        --     end)
        --     local instance1 = React.createRef(nil)
        --     local instance2 = React.createRef(nil)
        --     local root = ReactTestRenderer.create(React.createElement(React.Fragment, nil, React.createElement(LazyImpl, {
        --         ref = instance1,
        --         label = 'Not lazy',
        --     }), React.createElement(Suspense, {
        --         fallback = React.createElement(Text, {
        --             text = 'Loading...',
        --         }),
        --     }, React.createElement(Lazy, {
        --         ref = instance2,
        --         label = 'Lazy',
        --     }))), {unstable_isConcurrent = true})

        --     jestExpect(Scheduler).toFlushAndYield({
        --         'Not lazy: 0',
        --         'Loading...',
        --     })
        --     jestExpect(root).not.toMatchRenderedOutput('Not lazy: 0Lazy: 0')

        --     return _await(Promise.resolve(), function()
        --         jestExpect(Scheduler).toFlushAndYield({
        --             'Lazy: 0',
        --         })
        --         jestExpect(root).toMatchRenderedOutput('Not lazy: 0Lazy: 0')
        --         instance1.current.setState({})
        --         jestExpect(Scheduler).toFlushAndYield({})
        --         jestExpect(root).toMatchRenderedOutput('Not lazy: 0Lazy: 0')
        --         instance2.current.setState({})
        --         jestExpect(Scheduler).toFlushAndYield({})
        --         jestExpect(root).toMatchRenderedOutput('Not lazy: 0Lazy: 0')
        --     end)
        -- end))
        -- it('sets defaultProps for modern lifecycles', _async(function()
        --     local C = {}
        --     local CMetatable = {__index = C}

        --     function C.getDerivedStateFromProps(props)
        --         Scheduler.unstable_yieldValue(('getDerivedStateFromProps: %s'):format(props.text))

        --         return nil
        --     end
        --     function C.new(props)
        --         local self = setmetatable({}, CMetatable)

        --         self.state = {}

        --         Scheduler.unstable_yieldValue(('constructor: %s'):format(self.props.text))
        --     end
        --     function C:componentDidMount()
        --         Scheduler.unstable_yieldValue(('componentDidMount: %s'):format(self.props.text))
        --     end
        --     function C:componentDidUpdate(prevProps)
        --         Scheduler.unstable_yieldValue(('componentDidUpdate: %s -> %s'):format(prevProps.text, self.props.text))
        --     end
        --     function C:componentWillUnmount()
        --         Scheduler.unstable_yieldValue(('componentWillUnmount: %s'):format(self.props.text))
        --     end
        --     function C:shouldComponentUpdate(nextProps)
        --         Scheduler.unstable_yieldValue(('shouldComponentUpdate: %s -> %s'):format(self.props.text, nextProps.text))

        --         return true
        --     end
        --     function C:getSnapshotBeforeUpdate(prevProps)
        --         Scheduler.unstable_yieldValue(('getSnapshotBeforeUpdate: %s -> %s'):format(prevProps.text, self.props.text))

        --         return nil
        --     end
        --     function C:render()
        --         return React.createElement(Text, {
        --             text = self.props.text + self.props.num,
        --         })
        --     end

        --     C.defaultProps = {
        --         text = 'A',
        --     }

        --     local LazyClass = lazy(function()
        --         return fakeImport(C)
        --     end)
        --     local root = ReactTestRenderer.create(React.createElement(Suspense, {
        --         fallback = React.createElement(Text, {
        --             text = 'Loading...',
        --         }),
        --     }, React.createElement(LazyClass, {num = 1})), {unstable_isConcurrent = true})

        --     jestExpect(Scheduler).toFlushAndYield({
        --         'Loading...',
        --     })
        --     jestExpect(root).not.toMatchRenderedOutput('A1')

        --     return _await(Promise.resolve(), function()
        --         jestExpect(Scheduler).toFlushAndYield({
        --             'constructor: A',
        --             'getDerivedStateFromProps: A',
        --             'A1',
        --             'componentDidMount: A',
        --         })
        --         root.update(React.createElement(Suspense, {
        --             fallback = React.createElement(Text, {
        --                 text = 'Loading...',
        --             }),
        --         }, React.createElement(LazyClass, {num = 2})))
        --         jestExpect(Scheduler).toFlushAndYield({
        --             'getDerivedStateFromProps: A',
        --             'shouldComponentUpdate: A -> A',
        --             'A2',
        --             'getSnapshotBeforeUpdate: A -> A',
        --             'componentDidUpdate: A -> A',
        --         })
        --         jestExpect(root).toMatchRenderedOutput('A2')
        --         root.update(React.createElement(Suspense, {
        --             fallback = React.createElement(Text, {
        --                 text = 'Loading...',
        --             }),
        --         }, React.createElement(LazyClass, {num = 3})))
        --         jestExpect(Scheduler).toFlushAndYield({
        --             'getDerivedStateFromProps: A',
        --             'shouldComponentUpdate: A -> A',
        --             'A3',
        --             'getSnapshotBeforeUpdate: A -> A',
        --             'componentDidUpdate: A -> A',
        --         })
        --         jestExpect(root).toMatchRenderedOutput('A3')
        --     end)
        -- end))
        -- it('sets defaultProps for legacy lifecycles', _async(function()
        --     local C = {}
        --     local CMetatable = {__index = C}

        --     function C.new()
        --         local self = setmetatable({}, CMetatable)
        --         local _temp4

        --         return
        --     end
        --     function C:UNSAFE_componentWillMount()
        --         Scheduler.unstable_yieldValue(('UNSAFE_componentWillMount: %s'):format(self.props.text))
        --     end
        --     function C:UNSAFE_componentWillUpdate(nextProps)
        --         Scheduler.unstable_yieldValue(('UNSAFE_componentWillUpdate: %s -> %s'):format(self.props.text, nextProps.text))
        --     end
        --     function C:UNSAFE_componentWillReceiveProps(nextProps)
        --         Scheduler.unstable_yieldValue(('UNSAFE_componentWillReceiveProps: %s -> %s'):format(self.props.text, nextProps.text))
        --     end
        --     function C:render()
        --         return React.createElement(Text, {
        --             text = self.props.text + self.props.num,
        --         })
        --     end

        --     C.defaultProps = {
        --         text = 'A',
        --     }

        --     local LazyClass = lazy(function()
        --         return fakeImport(C)
        --     end)
        --     local root = ReactTestRenderer.create(React.createElement(Suspense, {
        --         fallback = React.createElement(Text, {
        --             text = 'Loading...',
        --         }),
        --     }, React.createElement(LazyClass, {num = 1})))

        --     jestExpect(Scheduler).toHaveYielded({
        --         'Loading...',
        --     })
        --     jestExpect(Scheduler).toFlushAndYield({})
        --     jestExpect(root).toMatchRenderedOutput('Loading...')

        --     return _await(Promise.resolve(), function()
        --         jestExpect(Scheduler).toHaveYielded({})
        --         root.update(React.createElement(Suspense, {
        --             fallback = React.createElement(Text, {
        --                 text = 'Loading...',
        --             }),
        --         }, React.createElement(LazyClass, {num = 2})))
        --         jestExpect(Scheduler).toHaveYielded({
        --             'UNSAFE_componentWillMount: A',
        --             'A2',
        --         })
        --         jestExpect(root).toMatchRenderedOutput('A2')
        --         root.update(React.createElement(Suspense, {
        --             fallback = React.createElement(Text, {
        --                 text = 'Loading...',
        --             }),
        --         }, React.createElement(LazyClass, {num = 3})))
        --         jestExpect(Scheduler).toHaveYielded({
        --             'UNSAFE_componentWillReceiveProps: A -> A',
        --             'UNSAFE_componentWillUpdate: A -> A',
        --             'A3',
        --         })
        --         jestExpect(Scheduler).toFlushAndYield({})
        --         jestExpect(root).toMatchRenderedOutput('A3')
        --     end)
        -- end))
        -- it('resolves defaultProps on the outer wrapper but warns', _async(function()
        --     local function T(props)
        --         Scheduler.unstable_yieldValue(props.inner + ' ' + props.outer)

        --         return props.inner + ' ' + props.outer
        --     end

        --     T.defaultProps = {
        --         inner = 'Hi',
        --     }

        --     local LazyText = lazy(function()
        --         return fakeImport(T)
        --     end)

        --     jestExpect(function()
        --         LazyText.defaultProps = {
        --             outer = 'Bye',
        --         }
        --     end).toErrorDev('React.lazy(...): It is not supported to assign `defaultProps` to ' + 'a lazy component import. Either specify them where the component ' + 'is defined, or create a wrapping component around it.', {withoutStack = true})

        --     local root = ReactTestRenderer.create(React.createElement(Suspense, {
        --         fallback = React.createElement(Text, {
        --             text = 'Loading...',
        --         }),
        --     }, React.createElement(LazyText, nil)), {unstable_isConcurrent = true})

        --     jestExpect(Scheduler).toFlushAndYield({
        --         'Loading...',
        --     })
        --     jestExpect(root).not.toMatchRenderedOutput('Hi Bye')

        --     return _await(Promise.resolve(), function()
        --         jestExpect(Scheduler).toFlushAndYield({
        --             'Hi Bye',
        --         })
        --         jestExpect(root).toMatchRenderedOutput('Hi Bye')
        --         root.update(React.createElement(Suspense, {
        --             fallback = React.createElement(Text, {
        --                 text = 'Loading...',
        --             }),
        --         }, React.createElement(LazyText, {
        --             outer = 'World',
        --         })))
        --         jestExpect(Scheduler).toFlushAndYield({
        --             'Hi World',
        --         })
        --         jestExpect(root).toMatchRenderedOutput('Hi World')
        --         root.update(React.createElement(Suspense, {
        --             fallback = React.createElement(Text, {
        --                 text = 'Loading...',
        --             }),
        --         }, React.createElement(LazyText, {
        --             inner = 'Friends',
        --         })))
        --         jestExpect(Scheduler).toFlushAndYield({
        --             'Friends Bye',
        --         })
        --         jestExpect(root).toMatchRenderedOutput('Friends Bye')
        --     end)
        -- end))
        it('throws with a useful error when wrapping invalid type with lazy()', function()
            local BadLazy = lazy(function()
                return fakeImport(42)
            end)
            local root = ReactTestRenderer.create(React.createElement(Suspense, {
                fallback = React.createElement(Text, {
                    text = 'Loading...',
                }),
            }, React.createElement(BadLazy, nil)), {unstable_isConcurrent = true})

            jestExpect(Scheduler).toFlushAndYield({
                'Loading...',
            })

            Promise.delay(0):await()

            root.update(React.createElement(Suspense, {
                fallback = React.createElement(Text, {
                    text = 'Loading...',
                }),
            }, React.createElement(BadLazy, nil)))
            jestExpect(Scheduler).toFlushAndThrow('Element type is invalid. Received a promise that resolves to: 42. ' .. 'Lazy element type must resolve to a class or function.')
        end)
        it('throws with a useful error when wrapping lazy() multiple times', function()
            local Lazy1 = lazy(function()
                return fakeImport(Text)
            end)
            local Lazy2 = lazy(function()
                return fakeImport(Lazy1)
            end)
            local root = ReactTestRenderer.create(React.createElement(Suspense, {
                fallback = React.createElement(Text, {
                    text = 'Loading...',
                }),
            }, React.createElement(Lazy2, {
                text = 'Hello',
            })), {unstable_isConcurrent = true})

            jestExpect(Scheduler).toFlushAndYield({
                'Loading...',
            })
            jestExpect(root).never.toMatchRenderedOutput('Hello')

            -- ROBLOX FIXME: delay by one frame is current best translation of `await Promise.resolve()`
            Promise.delay(0):await()

            root.update(React.createElement(Suspense, {
                fallback = React.createElement(Text, {
                    text = 'Loading...',
                }),
            }, React.createElement(Lazy2, {
                text = 'Hello',
            })))

            local moreThanOnce = _G.__DEV__ and ' Did you wrap a component in React.lazy() more than once?' or ''

            -- ROBLOX FIXME: Using substring of error, not RegExp because currently missing from LuauPolyfill.
            -- Still tests optional dev error and substring of main error, but missing the first sentence below
            -- 'Element type is invalid. Received a promise that resolves to: table: '
            jestExpect(Scheduler).toFlushAndThrow('Lazy element type must resolve to a class or function.' .. moreThanOnce)
        end)
        it('warns about defining propTypes on the outer wrapper', function()
            local LazyText = lazy(function()
                return fakeImport(Text)
            end)

            jestExpect(function()
                LazyText.propTypes = {
                    hello = function() end,
                }
            end).toErrorDev('React.lazy(...): It is not supported to assign `propTypes` to ' ..
                'a lazy component import. Either specify them where the component ' ..
                'is defined, or create a wrapping component around it.',
                {withoutStack = true}
            )
        end)
        -- it('respects propTypes on function component with defaultProps', _async(function()
        --     local function Add(props)
        --         jestExpect(props.innerWithDefault).toBe(42)

        --         return props.inner + props.outer
        --     end

        --     Add.propTypes = {
        --         inner = PropTypes.number.isRequired,
        --         innerWithDefault = PropTypes.number.isRequired,
        --     }
        --     Add.defaultProps = {innerWithDefault = 42}

        --     return _awaitIgnored(verifyInnerPropTypesAreChecked(Add))
        -- end))
        -- it('respects propTypes on function component without defaultProps', _async(function()
        --     local function Add(props)
        --         return props.inner + props.outer
        --     end

        --     Add.propTypes = {
        --         inner = PropTypes.number.isRequired,
        --     }

        --     return _awaitIgnored(verifyInnerPropTypesAreChecked(Add))
        -- end))
        -- it('respects propTypes on class component with defaultProps', _async(function()
        --     local Add = {}
        --     local AddMetatable = {__index = Add}

        --     function Add:render()
        --         jestExpect(self.props.innerWithDefault).toBe(42)

        --         return self.props.inner + self.props.outer
        --     end

        --     Add.propTypes = {
        --         inner = PropTypes.number.isRequired,
        --         innerWithDefault = PropTypes.number.isRequired,
        --     }
        --     Add.defaultProps = {innerWithDefault = 42}

        --     return _awaitIgnored(verifyInnerPropTypesAreChecked(Add))
        -- end))
        -- it('respects propTypes on class component without defaultProps', _async(function()
        --     local Add = {}
        --     local AddMetatable = {__index = Add}

        --     function Add:render()
        --         return self.props.inner + self.props.outer
        --     end

        --     Add.propTypes = {
        --         inner = PropTypes.number.isRequired,
        --     }

        --     return _awaitIgnored(verifyInnerPropTypesAreChecked(Add))
        -- end))
        -- it('respects propTypes on forwardRef component with defaultProps', _async(function()
        --     local Add = React.forwardRef(function(props, ref)
        --         jestExpect(props.innerWithDefault).toBe(42)

        --         return props.inner + props.outer
        --     end)

        --     Add.displayName = 'Add'
        --     Add.propTypes = {
        --         inner = PropTypes.number.isRequired,
        --         innerWithDefault = PropTypes.number.isRequired,
        --     }
        --     Add.defaultProps = {innerWithDefault = 42}

        --     return _awaitIgnored(verifyInnerPropTypesAreChecked(Add))
        -- end))
        -- it('respects propTypes on forwardRef component without defaultProps', _async(function()
        --     local Add = React.forwardRef(function(props, ref)
        --         return props.inner + props.outer
        --     end)

        --     Add.displayName = 'Add'
        --     Add.propTypes = {
        --         inner = PropTypes.number.isRequired,
        --     }

        --     return _awaitIgnored(verifyInnerPropTypesAreChecked(Add))
        -- end))
        -- it('respects propTypes on outer memo component with defaultProps', _async(function()
        --     local Add = function(props)
        --         jestExpect(props.innerWithDefault).toBe(42)

        --         return props.inner + props.outer
        --     end

        --     Add = React.memo(Add)
        --     Add.propTypes = {
        --         inner = PropTypes.number.isRequired,
        --         innerWithDefault = PropTypes.number.isRequired,
        --     }
        --     Add.defaultProps = {innerWithDefault = 42}

        --     return _awaitIgnored(verifyInnerPropTypesAreChecked(Add))
        -- end))
        -- it('respects propTypes on outer memo component without defaultProps', _async(function()
        --     local Add = function(props)
        --         return props.inner + props.outer
        --     end

        --     Add = React.memo(Add)
        --     Add.propTypes = {
        --         inner = PropTypes.number.isRequired,
        --     }

        --     return _awaitIgnored(verifyInnerPropTypesAreChecked(Add))
        -- end))
        -- it('respects propTypes on inner memo component with defaultProps', _async(function()
        --     local Add = function(props)
        --         jestExpect(props.innerWithDefault).toBe(42)

        --         return props.inner + props.outer
        --     end

        --     Add.displayName = 'Add'
        --     Add.propTypes = {
        --         inner = PropTypes.number.isRequired,
        --         innerWithDefault = PropTypes.number.isRequired,
        --     }
        --     Add.defaultProps = {innerWithDefault = 42}

        --     return _awaitIgnored(verifyInnerPropTypesAreChecked(React.memo(Add)))
        -- end))
        -- it('respects propTypes on inner memo component without defaultProps', _async(function()
        --     local Add = function(props)
        --         return props.inner + props.outer
        --     end

        --     Add.displayName = 'Add'
        --     Add.propTypes = {
        --         inner = PropTypes.number.isRequired,
        --     }

        --     return _awaitIgnored(verifyInnerPropTypesAreChecked(React.memo(Add)))
        -- end))
        -- it('uses outer resolved props for validating propTypes on memo', _async(function()
        --     local T = function(props)
        --         return React.createElement(Text, {
        --             text = props.text,
        --         })
        --     end

        --     T.defaultProps = {
        --         text = 'Inner default text',
        --     }
        --     T = React.memo(T)
        --     T.propTypes = {
        --         text = PropTypes.string.isRequired,
        --     }

        --     local LazyText = lazy(function()
        --         return fakeImport(T)
        --     end)
        --     local root = ReactTestRenderer.create(React.createElement(Suspense, {
        --         fallback = React.createElement(Text, {
        --             text = 'Loading...',
        --         }),
        --     }, React.createElement(LazyText, nil)), {unstable_isConcurrent = true})

        --     jestExpect(Scheduler).toFlushAndYield({
        --         'Loading...',
        --     })
        --     jestExpect(root).not.toMatchRenderedOutput('Inner default text')

        --     return _await(Promise.resolve(), function()
        --         jestExpect(function()
        --             jestExpect(Scheduler).toFlushAndYield({
        --                 'Inner default text',
        --             })
        --         end).toErrorDev('The prop `text` is marked as required in `T`, but its value is `undefined`')
        --         jestExpect(root).toMatchRenderedOutput('Inner default text')
        --         jestExpect(function()
        --             root.update(React.createElement(Suspense, {
        --                 fallback = React.createElement(Text, {
        --                     text = 'Loading...',
        --                 }),
        --             }, React.createElement(LazyText, {text = nil})))
        --             jestExpect(Scheduler).toFlushAndYield({nil})
        --         end).toErrorDev('The prop `text` is marked as required in `T`, but its value is `null`')
        --         jestExpect(root).toMatchRenderedOutput(nil)
        --     end)
        -- end))

        -- ROBLOX TODO: wrong component stack, not resolving past Suspense/Lazy wrappers
        xit('includes lazy-loaded component in warning stack', function()
            local LazyFoo = lazy(function()
                Scheduler.unstable_yieldValue('Started loading')

                local Foo = function(props)
                    return React.createElement('div', nil, {
                        React.createElement(Text, {
                            text = 'A',
                        }),
                        React.createElement(Text, {
                            text = 'B',
                        }),
                    })
                end

                return fakeImport(Foo)
            end)
            local root = ReactTestRenderer.create(React.createElement(Suspense, {
                fallback = React.createElement(Text, {
                    text = 'Loading...',
                }),
            }, React.createElement(LazyFoo)), {unstable_isConcurrent = true})

            jestExpect(Scheduler).toFlushAndYield({
                'Started loading',
                'Loading...',
            })
            jestExpect(root).never.toMatchRenderedOutput(React.createElement('div', nil, 'AB'))

            Promise.delay(0):await()

            jestExpect(function()
                jestExpect(Scheduler).toFlushAndYield({
                    'A',
                    'B',
                })
            end).toErrorDev('    in Text (at **)\n' .. '    in Foo (at **)')
            jestExpect(root).toMatchRenderedOutput(React.createElement('div', nil, 'AB'))
        end)

        it('supports class and forwardRef components', function()
            local LazyClass = lazy(function()
                local Foo = React.Component:extend("Foo")

                function Foo:render()
                    return React.createElement(Text, {
                        text = 'Foo',
                    })
                end

                return fakeImport(Foo)
            end)

            local LazyForwardRef = lazy(function()
                local Bar = React.Component:extend("Bar")

                function Bar:render()
                    return React.createElement(Text, {
                        text = 'Bar',
                    })
                end

                return fakeImport(React.forwardRef(function(props, ref)
                    Scheduler.unstable_yieldValue('forwardRef')

                    return React.createElement(Bar, {ref = ref})
                end))
            end)

            local ref = React.createRef()
            local root = ReactTestRenderer.create(React.createElement(Suspense, {
                fallback = React.createElement(Text, {
                    text = 'Loading...',
                }),
            }, React.createElement(LazyClass, nil), React.createElement(LazyForwardRef, {ref = ref})), {unstable_isConcurrent = true})

            jestExpect(Scheduler).toFlushAndYield({
                'Loading...',
            })
            jestExpect(root).never.toMatchRenderedOutput('FooBar')
            jestExpect(ref.current).toBe(nil)

            -- ROBLOX FIXME: delay by one frame is current best translation of `await Promise.resolve()`
            Promise.delay(0):await()

            jestExpect(Scheduler).toFlushAndYield({
                'Foo',
                'forwardRef',
                'Bar',
            })
            jestExpect(root).toMatchRenderedOutput('FooBar')
            jestExpect(ref.current).never.toBe(nil)
        end)
        -- it('supports defaultProps defined on the memo() return value', _async(function()
        --     local Add = React.memo(function(props)
        --         return props.inner + props.outer
        --     end)

        --     Add.defaultProps = {inner = 2}

        --     local LazyAdd = lazy(function()
        --         return fakeImport(Add)
        --     end)
        --     local root = ReactTestRenderer.create(React.createElement(Suspense, {
        --         fallback = React.createElement(Text, {
        --             text = 'Loading...',
        --         }),
        --     }, React.createElement(LazyAdd, {outer = 2})), {unstable_isConcurrent = true})

        --     jestExpect(Scheduler).toFlushAndYield({
        --         'Loading...',
        --     })
        --     jestExpect(root).not.toMatchRenderedOutput('4')

        --     return _await(Promise.resolve(), function()
        --         jestExpect(Scheduler).toFlushWithoutYielding()
        --         jestExpect(root).toMatchRenderedOutput('4')
        --         root.update(React.createElement(Suspense, {
        --             fallback = React.createElement(Text, {
        --                 text = 'Loading...',
        --             }),
        --         }, React.createElement(LazyAdd, {outer = 2})))
        --         jestExpect(Scheduler).toFlushWithoutYielding()
        --         jestExpect(root).toMatchRenderedOutput('4')
        --         root.update(React.createElement(Suspense, {
        --             fallback = React.createElement(Text, {
        --                 text = 'Loading...',
        --             }),
        --         }, React.createElement(LazyAdd, {outer = 3})))
        --         jestExpect(Scheduler).toFlushWithoutYielding()
        --         jestExpect(root).toMatchRenderedOutput('5')
        --         root.update(React.createElement(Suspense, {
        --             fallback = React.createElement(Text, {
        --                 text = 'Loading...',
        --             }),
        --         }, React.createElement(LazyAdd, {outer = 3})))
        --         jestExpect(Scheduler).toFlushWithoutYielding()
        --         jestExpect(root).toMatchRenderedOutput('5')
        --         root.update(React.createElement(Suspense, {
        --             fallback = React.createElement(Text, {
        --                 text = 'Loading...',
        --             }),
        --         }, React.createElement(LazyAdd, {
        --             outer = 1,
        --             inner = 1,
        --         })))
        --         jestExpect(Scheduler).toFlushWithoutYielding()
        --         jestExpect(root).toMatchRenderedOutput('2')
        --         root.update(React.createElement(Suspense, {
        --             fallback = React.createElement(Text, {
        --                 text = 'Loading...',
        --             }),
        --         }, React.createElement(LazyAdd, {
        --             outer = 1,
        --             inner = 1,
        --         })))
        --         jestExpect(Scheduler).toFlushWithoutYielding()
        --         jestExpect(root).toMatchRenderedOutput('2')
        --         root.update(React.createElement(Suspense, {
        --             fallback = React.createElement(Text, {
        --                 text = 'Loading...',
        --             }),
        --         }, React.createElement(LazyAdd, {outer = 1})))
        --         jestExpect(Scheduler).toFlushWithoutYielding()
        --         jestExpect(root).toMatchRenderedOutput('3')
        --     end)
        -- end))
        -- it('merges defaultProps in the correct order', _async(function()
        --     local Add = React.memo(function(props)
        --         return props.inner + props.outer
        --     end)

        --     Add.defaultProps = {inner = 100}
        --     Add = React.memo(Add)
        --     Add.defaultProps = {
        --         inner = 2,
        --         outer = 0,
        --     }

        --     local LazyAdd = lazy(function()
        --         return fakeImport(Add)
        --     end)
        --     local root = ReactTestRenderer.create(React.createElement(Suspense, {
        --         fallback = React.createElement(Text, {
        --             text = 'Loading...',
        --         }),
        --     }, React.createElement(LazyAdd, {outer = 2})), {unstable_isConcurrent = true})

        --     jestExpect(Scheduler).toFlushAndYield({
        --         'Loading...',
        --     })
        --     jestExpect(root).not.toMatchRenderedOutput('4')

        --     return _await(Promise.resolve(), function()
        --         jestExpect(Scheduler).toFlushWithoutYielding()
        --         jestExpect(root).toMatchRenderedOutput('4')
        --         root.update(React.createElement(Suspense, {
        --             fallback = React.createElement(Text, {
        --                 text = 'Loading...',
        --             }),
        --         }, React.createElement(LazyAdd, {outer = 3})))
        --         jestExpect(Scheduler).toFlushWithoutYielding()
        --         jestExpect(root).toMatchRenderedOutput('5')
        --         root.update(React.createElement(Suspense, {
        --             fallback = React.createElement(Text, {
        --                 text = 'Loading...',
        --             }),
        --         }, React.createElement(LazyAdd, nil)))
        --         jestExpect(Scheduler).toFlushWithoutYielding()
        --         jestExpect(root).toMatchRenderedOutput('2')
        --     end)
        -- end))
        it('warns about ref on functions for lazy-loaded components', function()
            local LazyFoo = lazy(function()
                local Foo = function(props)
                    return React.createElement('div', nil)
                end
                return fakeImport(Foo)
            end)
            local ref = React.createRef()

            ReactTestRenderer.create(React.createElement(Suspense, {
                fallback = React.createElement(Text, {
                    text = 'Loading...',
                }),
            }, React.createElement(LazyFoo, {ref = ref})), {unstable_isConcurrent = true})
            jestExpect(Scheduler).toFlushAndYield({
                'Loading...',
            })

            -- ROBLOX FIXME: delay by one frame is current best translation of `await Promise.resolve()`
            Promise.delay(0):await()

            jestExpect(function()
                jestExpect(Scheduler).toFlushAndYield({})
            end).toErrorDev('Function components cannot be given refs')
        end)
        -- ROBLOX TODO: normalizeCodeLocInfo needs regex
        xit('should error with a component stack naming the resolved component', function()
            local componentStackMessage
            local LazyText = lazy(function()
                return fakeImport(function()
                    error(Error('oh no'))
                end)
            end)
            local ErrorBoundary = React.Component:extend("ErrorBoundary")

            function ErrorBoundary:init()
                self.state = {error = nil}
            end
            function ErrorBoundary:componentDidCatch(error_, errMessage)
                componentStackMessage = normalizeCodeLocInfo(errMessage.componentStack)

                self:setState({error = error_})
            end
            function ErrorBoundary:render()
                if self.state.error then
                    return nil
                else
                    return self.props.children
                end
            end

            ReactTestRenderer.create(React.createElement(ErrorBoundary, nil, React.createElement(Suspense, {
                fallback = React.createElement(Text, {
                    text = 'Loading...',
                }),
            }, React.createElement(LazyText, {
                text = 'Hi',
            }))), {unstable_isConcurrent = true})
            jestExpect(Scheduler).toFlushAndYield({
                'Loading...',
            })

            _ = pcall(function()
                Promise.delay(0):await()
            end)

            jestExpect(Scheduler).toFlushAndYield({})
            jestExpect(componentStackMessage).toContain('in ResolvedText')
        end)
        -- ROBLOX FIXME: missing stack frame that contains Lazy
        xit('should error with a component stack containing Lazy if unresolved', function()
            local componentStackMessage
            local LazyText = lazy(function()
                return {
                    andThen = function(resolve, reject)
                        reject(Error('oh no'))
                    end,
                }
            end)
            local ErrorBoundary = React.Component:extend("ErrorBoundary")

            function ErrorBoundary:init()
                self.state = {
                    error_ = nil
                }
            end
            function ErrorBoundary:componentDidCatch(error_, errMessage)
                -- ROBLOX FIXME: componentStack is missing LazyText even before normalize
                componentStackMessage = normalizeCodeLocInfo(errMessage.componentStack)

                self:setState({error_ = error_})
            end
            function ErrorBoundary:render()
                return(function()
                    if self.state.error_ then
                        return nil
                    end

                    return self.props.children
                end)()
            end

            ReactTestRenderer.create(React.createElement(ErrorBoundary, nil, React.createElement(Suspense, {
                fallback = React.createElement(Text, {
                    text = 'Loading...',
                }),
            }, React.createElement(LazyText, {
                text = 'Hi',
            }))))
            jestExpect(Scheduler).toHaveYielded({})
            -- ROBLOX TODO: only this final assert fails
            jestExpect(componentStackMessage).toContain('in Lazy')
        end)

        -- @gate enableLazyElements
        -- xit('mount and reorder lazy elements', function()
        --     local Child = React.Component:extend("Child")

        --     function Child:componentDidMount()
        --         Scheduler.unstable_yieldValue('Did mount: ' .. self.props.label)
        --     end
        --     function Child:componentDidUpdate()
        --         Scheduler.unstable_yieldValue('Did update: ' .. self.props.label)
        --     end
        --     function Child:render()
        --         return React.createElement(Text, {
        --             text = self.props.label,
        --         })
        --     end

        --     local lazyChildA = lazy(function()
        --         Scheduler.unstable_yieldValue('Init A')

        --         return fakeImport(React.createElement(Child, {
        --             key = 'A',
        --             label = 'A',
        --         }))
        --     end)
        --     local lazyChildB = lazy(function()
        --         Scheduler.unstable_yieldValue('Init B')

        --         return fakeImport(React.createElement(Child, {
        --             key = 'B',
        --             label = 'B',
        --         }))
        --     end)
        --     local lazyChildA2 = lazy(function()
        --         Scheduler.unstable_yieldValue('Init A2')

        --         return fakeImport(React.createElement(Child, {
        --             key = 'A',
        --             label = 'a',
        --         }))
        --     end)

        --     local lazyChildB2 = lazy(function()
        --         Scheduler.unstable_yieldValue('Init B2')

        --         return fakeImport(React.createElement(Child, {
        --             key = 'B',
        --             label = 'b',
        --         }))
        --     end)

        --     local function Parent(props)
        --         local swap = props.swap

        --         return React.createElement(Suspense, {
        --             fallback = React.createElement(Text, {
        --                 text = 'Loading...',
        --             })},
        --             (function()
        --             if swap then
        --                 return{lazyChildB2, lazyChildA2}
        --             end

        --             return{lazyChildA, lazyChildB}
        --         end)())
        --     end

        --     local root = ReactTestRenderer.create(React.createElement(Parent, {swap = false}), {
        --         unstable_isConcurrent = true
        --     })

        --     -- ROBLOX FIXME: delay by one frame is current best translation of `await Promise.resolve()`
        --     Promise.delay(0):await()

        --     jestExpect(Scheduler).toFlushAndYield({
        --         'Init A',
        --         'Loading...',
        --     })
        --     jestExpect(root).never.toMatchRenderedOutput('AB')

        --     return _await(lazyChildA, function()
        --         jestExpect(Scheduler).toFlushAndYield({
        --             'Init B',
        --         })

        --         return _await(lazyChildB, function()
        --             jestExpect(Scheduler).toFlushAndYield({
        --                 'A',
        --                 'B',
        --                 'Did mount: A',
        --                 'Did mount: B',
        --             })
        --             jestExpect(root).toMatchRenderedOutput('AB')
        --             root.update(React.createElement(Parent, {swap = true}))
        --             jestExpect(Scheduler).toFlushAndYield({
        --                 'Init B2',
        --                 'Loading...',
        --             })

        --             return _await(lazyChildB2, function()
        --                 jestExpect(Scheduler).toFlushAndYield({
        --                     'Init A2',
        --                     'Loading...',
        --                 })

        --                 return _await(lazyChildA2, function()
        --                     jestExpect(Scheduler).toFlushAndYield({
        --                         'b',
        --                         'a',
        --                         'Did update: b',
        --                         'Did update: a',
        --                     })
        --                     jestExpect(root).toMatchRenderedOutput('ba')
        --                 end)
        --             end)
        --         end)
        --     end)
        -- end)
    end)
end