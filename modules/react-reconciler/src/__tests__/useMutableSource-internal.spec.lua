-- Upstream: https://github.com/facebook/react/blob/d13f5b9538e48f74f7c571ef3cde652ca887cca0/packages/react-reconciler/src/__tests__/useMutableSource-test.internal.js
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @emails react-core
--  * @jest-environment node
--  */

local Packages = script.Parent.Parent.Parent
local React
local ReactNoop
local Scheduler
local act
local createMutableSource
local useMutableSource
local RobloxJest = require(Packages.Dev.RobloxJest)

local LuauPolyfill = require(Packages.LuauPolyfill)
local Promise = require(Packages.Promise)
local Array = LuauPolyfill.Array

return function()
    local JestGlobals = require(Packages.Dev.JestGlobals)
    local jestExpect = JestGlobals.expect
    local jest = JestGlobals.jest

    local function loadModules()
        RobloxJest.resetModules()
        RobloxJest.useFakeTimers()
        local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
        ReactFeatureFlags.enableSchedulerTracing = true
        ReactFeatureFlags.enableProfilerTimer = true
        React = require(Packages.React)
        ReactNoop = require(Packages.Dev.ReactNoopRenderer)
        Scheduler = require(Packages.Scheduler)
        act = ReactNoop.act
        createMutableSource = React.createMutableSource
        useMutableSource = React.useMutableSource
    end

    describe('useMutableSource', function()
        local defaultGetSnapshot = function(source)
            return source.value
        end
        local defaultSubscribe = function(source, callback)
            if callback ~= nil then
                return source.subscribe(callback)
            end
            -- ROBLOX deviation: Lua can't insert nils into the callbacks array, so insert a no-op instread
            return source.subscribe(function() end)
        end

        local function createComplexSource(initialValueA, initialValueB)
            local callbacksA = {}
            local callbacksB = {}
            local revision = 1
            local valueA = initialValueA
            local valueB = initialValueB
            local subscribeHelper = function(callbacks, callback)
                if Array.indexOf(callbacks, callback) < 1 then
                    table.insert(callbacks, callback)
                end

                return function()
                    local index = Array.indexOf(callbacks, callback)

                    if index >= 1 then
                        Array.splice(callbacks, index, 1)
                    end
                end
            end

            local metatable = {
                __index = function(table, key)
                    if key == "listenerCountA" then
                        return #callbacksA
                    elseif key == "listenerCountB" then
                        return #callbacksB
                    elseif key == "valueA" then
                        return valueA
                    elseif key == "valueB" then
                        return valueB
                    elseif key == "version" then
                        return revision
                    end
                    return
                end,
                __newindex = function(table, key, newValue)
                    if key == "valueA" then
                        revision += 1
                        valueA = newValue

                        Array.map(callbacksA, function(callback)
                            return callback()
                        end)
                    elseif key == "valueB" then
                        revision += 1
                        valueB = newValue

                        Array.map(callbacksB, function(callback)
                            return callback()
                        end)
                    end
                end
            }

            local tableToReturn = {
                subscribeA = function(callback)
                    return subscribeHelper(callbacksA, callback)
                end,
                subscribeB = function(callback)
                    return subscribeHelper(callbacksB, callback)
                end
            }
            return setmetatable(tableToReturn, metatable)
        end
        local function createSource(initialValue)
            local callbacks = {}
            local revision = 1
            local value = initialValue

            local metatable = {
                __index = function(table, key)
                    if key == "value" then
                        return value
                    elseif key == "version" then
                        return revision
                    elseif key == "listenerCount" then
                        return #callbacks
                    end
                    return
                end,
                __newindex = function(table, key, newValue)
                    if key == "value" then
                        revision += 1
                        value = newValue

                        -- deviation: forEach() translated using Array.map
                        Array.map(callbacks, function(callback)
                            return callback()
                        end)
                    end
                end
            }
            local tableToReturn = {
                subscribe = function(callback)
                    if Array.indexOf(callbacks, callback) < 1 then
                        table.insert(callbacks, callback)
                    end

                    return function()
                        local index = Array.indexOf(callbacks, callback)

                        if index >= 1 then
                            Array.splice(callbacks, index, 1)
                        end
                    end
                end,
            }
            return setmetatable(tableToReturn, metatable)
        end
        local function Component(props)
            local getSnapshot, label, mutableSource, subscribe = props.getSnapshot, props.label, props.mutableSource, props.subscribe
            local snapshot = useMutableSource(mutableSource, getSnapshot, subscribe)
            Scheduler.unstable_yieldValue(("%s:%s"):format(label, snapshot))

            return React.createElement("div", nil, ("%s:%s"):format(label, snapshot))
        end

        beforeEach(function()
            loadModules()
        end)
        -- @gate experimental
        it("should subscribe to a source and schedule updates when it changes", function()
            local source = createSource("one")
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)

            act(function()
                ReactNoop.renderToRootWithID(React.createElement(React.Fragment, nil, React.createElement(Component, {
                    label = "a",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                }), React.createElement(Component, {
                    label = "b",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                })), "root", function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYieldThrough({
                    "a:one",
                    "b:one",
                    "Sync effect",
                })
                -- Subscriptions should be passive
                jestExpect(source.listenerCount).toEqual(0)
                ReactNoop.flushPassiveEffects()
                jestExpect(source.listenerCount).toEqual(2)

                -- Changing values should schedule an update with React
                source.value = "two"

                jestExpect(Scheduler).toFlushAndYieldThrough({
                    "a:two",
                    "b:two",
                })

                -- Umounting a component should remove its subscription.
                ReactNoop.renderToRootWithID(React.createElement(React.Fragment, nil, React.createElement(Component, {
                    label = "a",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                })), "root", function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "a:two",
                    "Sync effect",
                })
                ReactNoop.flushPassiveEffects()
                jestExpect(source.listenerCount).toEqual(1)

                -- Umounting a root should remove the remaining event listeners
                ReactNoop.unmountRootWithID("root")
                jestExpect(Scheduler).toFlushAndYield({})
                ReactNoop.flushPassiveEffects()
                jestExpect(source.listenerCount).toEqual(0)

                -- Changes to source should not trigger an updates or warnings.
                source.value = "three"

                jestExpect(Scheduler).toFlushAndYield({})
            end)
        end)
        -- @gate experimental
        it("should restart work if a new source is mutated during render", function()
            local source = createSource("one")
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)

            act(function()
                ReactNoop.render(React.createElement(React.Fragment, nil, React.createElement(Component, {
                    label = "a",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                }), React.createElement(Component, {
                    label = "b",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                })), function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)

                -- Do enough work to read from one component
                jestExpect(Scheduler).toFlushAndYieldThrough({
                    "a:one",
                })
                -- Mutate source before continuing work
                source.value = "two"

                -- Render work should restart and the updated value should be used
                jestExpect(Scheduler).toFlushAndYield({
                    "a:two",
                    "b:two",
                    "Sync effect",
                })
            end)
        end)
        -- @gate experimental
        it("should schedule an update if a new source is mutated between render and commit (subscription)", function()
            local source = createSource("one")
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)

            act(function()
                ReactNoop.render(React.createElement(React.Fragment, nil, React.createElement(Component, {
                    label = "a",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                }), React.createElement(Component, {
                    label = "b",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                })), function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)

                -- Finish rendering
                jestExpect(Scheduler).toFlushAndYieldThrough({
                    "a:one",
                    "b:one",
                    "Sync effect",
                })

                -- Mutate source before subscriptions are attached
                jestExpect(source.listenerCount).toEqual(0)

                source.value = "two"

                -- Mutation should be detected, and a new render should be scheduled
                jestExpect(Scheduler).toFlushAndYield({
                    "a:two",
                    "b:two",
                })
            end)
        end)
        -- @gate experimental
        it("should unsubscribe and resubscribe if a new source is used", function()
            local sourceA = createSource("a-one")
            local mutableSourceA = createMutableSource(sourceA, function(param)
                return param.versionA
            end)
            local sourceB = createSource("b-one")
            local mutableSourceB = createMutableSource(sourceB, function(param)
                return param.versionB
            end)

            act(function()
                ReactNoop.render(React.createElement(Component, {
                    label = "only",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSourceA,
                    subscribe = defaultSubscribe,
                }), function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "only:a-one",
                    "Sync effect",
                })
                ReactNoop.flushPassiveEffects()
                jestExpect(sourceA.listenerCount).toEqual(1)

                -- Changing values should schedule an update with React
                sourceA.value = "a-two"

                jestExpect(Scheduler).toFlushAndYield({
                    "only:a-two",
                })

                -- If we re-render with a new source, the old one should be unsubscribed.
                ReactNoop.render(React.createElement(Component, {
                    label = "only",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSourceB,
                    subscribe = defaultSubscribe,
                }), function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "only:b-one",
                    "Sync effect",
                })
                ReactNoop.flushPassiveEffects()
                jestExpect(sourceA.listenerCount).toEqual(0)
                jestExpect(sourceB.listenerCount).toEqual(1)

                -- Changing to original source should not schedule updates with React
                sourceA.value = "a-three"

                jestExpect(Scheduler).toFlushAndYield({})

                -- Changing new source value should schedule an update with React
                sourceB.value = "b-two"

                jestExpect(Scheduler).toFlushAndYield({
                    "only:b-two",
                })
            end)
        end)

        it("should unsubscribe and resubscribe if a new subscribe function is provided", function()
            local source = createSource("a-one")
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)

            local unsubscribeA = jest.fn()
            local subscribeA = jest.fn(function(s)
                local unsubscribe = defaultSubscribe(s)

                return function()
                    unsubscribe()
                    unsubscribeA()
                end
            end)

            local unsubscribeB = jest.fn()
            local subscribeB = jest.fn(function(s)
                local unsubscribe = defaultSubscribe(s)

                return function()
                    unsubscribe()
                    unsubscribeB()
                end
            end)

            act(function()
                ReactNoop.renderToRootWithID(React.createElement(Component, {
                    label = "only",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = subscribeA,
                }), "root", function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "only:a-one",
                    "Sync effect",
                })
                ReactNoop.flushPassiveEffects()
                jestExpect(source.listenerCount).toEqual(1)
                jestExpect(subscribeA).toHaveBeenCalledTimes(1)
                ReactNoop.renderToRootWithID(React.createElement(Component, {
                    label = "only",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = subscribeB,
                }), "root", function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "only:a-one",
                    "Sync effect",
                })
                ReactNoop.flushPassiveEffects()
                jestExpect(source.listenerCount).toEqual(1)
                jestExpect(unsubscribeA).toHaveBeenCalledTimes(1)
                jestExpect(subscribeB).toHaveBeenCalledTimes(1)
                ReactNoop.unmountRootWithID("root")
                jestExpect(Scheduler).toFlushAndYield({})
                ReactNoop.flushPassiveEffects()
                jestExpect(source.listenerCount).toEqual(0)
                jestExpect(unsubscribeB).toHaveBeenCalledTimes(1)
            end)
        end)
        it("should re-use previously read snapshot value when reading is unsafe", function()
            local source = createSource("one")
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)

            act(function()
                ReactNoop.render(React.createElement(React.Fragment, nil, React.createElement(Component, {
                    label = "a",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                }), React.createElement(Component, {
                    label = "b",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                })), function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "a:one",
                    "b:one",
                    "Sync effect",
                })

                -- Changing values should schedule an update with React.
                -- Start working on this update but don't finish it.
                source.value = "two"

                jestExpect(Scheduler).toFlushAndYieldThrough({
                    "a:two",
                })

                -- Re-renders that occur before the update is processed
                -- should reuse snapshot so long as the config has not changed
                ReactNoop.flushSync(function()
                    ReactNoop.render(React.createElement(React.Fragment, nil, React.createElement(Component, {
                        label = "a",
                        getSnapshot = defaultGetSnapshot,
                        mutableSource = mutableSource,
                        subscribe = defaultSubscribe,
                    }), React.createElement(Component, {
                        label = "b",
                        getSnapshot = defaultGetSnapshot,
                        mutableSource = mutableSource,
                        subscribe = defaultSubscribe,
                    })), function()
                        return Scheduler.unstable_yieldValue("Sync effect")
                    end)
                end)
                jestExpect(Scheduler).toHaveYielded({
                    "a:one",
                    "b:one",
                    "Sync effect",
                })
                jestExpect(Scheduler).toFlushAndYield({
                    "a:two",
                    "b:two",
                })
            end)
        end)
        -- @gate experimental
        it("should read from source on newly mounted subtree if no pending updates are scheduled for source", function()
            local source = createSource("one")
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)

            act(function()
                ReactNoop.render(React.createElement(React.Fragment, nil, React.createElement(Component, {
                    label = "a",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                })), function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "a:one",
                    "Sync effect",
                })
                ReactNoop.render(React.createElement(React.Fragment, nil, React.createElement(Component, {
                    label = "a",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                }), React.createElement(Component, {
                    label = "b",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                })), function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "a:one",
                    "b:one",
                    "Sync effect",
                })
            end)
        end)
        -- @gate experimental
        it("should throw and restart render if source and snapshot are unavailable during an update", function()
            local source = createSource("one")
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)

            act(function()
                ReactNoop.render(React.createElement(React.Fragment, nil, React.createElement(Component, {
                    label = "a",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                }), React.createElement(Component, {
                    label = "b",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                })), function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "a:one",
                    "b:one",
                    "Sync effect",
                })
                ReactNoop.flushPassiveEffects()
                -- Changing values should schedule an update with React.
                -- Start working on this update but don't finish it.
                Scheduler.unstable_runWithPriority(Scheduler.unstable_LowPriority, function()
                    source.value = "two"

                    jestExpect(Scheduler).toFlushAndYieldThrough({
                        "a:two",
                    })
                end)

                local newGetSnapshot = function(s)
                    return"new:" .. defaultGetSnapshot(s)
                end

                -- Force a higher priority render with a new config.
                -- This should signal that the snapshot is not safe and trigger a full re-render.
                Scheduler.unstable_runWithPriority(Scheduler.unstable_UserBlockingPriority, function()
                    ReactNoop.render(React.createElement(React.Fragment, nil, React.createElement(Component, {
                        label = "a",
                        getSnapshot = newGetSnapshot,
                        mutableSource = mutableSource,
                        subscribe = defaultSubscribe,
                    }), React.createElement(Component, {
                        label = "b",
                        getSnapshot = newGetSnapshot,
                        mutableSource = mutableSource,
                        subscribe = defaultSubscribe,
                    })), function()
                        return Scheduler.unstable_yieldValue("Sync effect")
                    end)
                end)
                jestExpect(Scheduler).toFlushAndYieldThrough({
                    "a:new:two",
                    "b:new:two",
                    "Sync effect",
                })
            end)
        end)
        -- @gate experimental
        it("should throw and restart render if source and snapshot are unavailable during a sync update", function()
            local source = createSource("one")
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)

            act(function()
                ReactNoop.render(React.createElement(React.Fragment, nil, React.createElement(Component, {
                    label = "a",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                }), React.createElement(Component, {
                    label = "b",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                })), function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "a:one",
                    "b:one",
                    "Sync effect",
                })
                ReactNoop.flushPassiveEffects()
                -- Changing values should schedule an update with React.
                -- Start working on this update but don't finish it.
                Scheduler.unstable_runWithPriority(Scheduler.unstable_LowPriority, function()
                    source.value = "two"

                    jestExpect(Scheduler).toFlushAndYieldThrough({
                        "a:two",
                    })
                end)

                local newGetSnapshot = function(s)
                    return"new:" .. defaultGetSnapshot(s)
                end
                -- Force a higher priority render with a new config.
                -- This should signal that the snapshot is not safe and trigger a full re-render.
                ReactNoop.flushSync(function()
                    ReactNoop.render(React.createElement(React.Fragment, nil, React.createElement(Component, {
                        label = "a",
                        getSnapshot = newGetSnapshot,
                        mutableSource = mutableSource,
                        subscribe = defaultSubscribe,
                    }), React.createElement(Component, {
                        label = "b",
                        getSnapshot = newGetSnapshot,
                        mutableSource = mutableSource,
                        subscribe = defaultSubscribe,
                    })), function()
                        return Scheduler.unstable_yieldValue("Sync effect")
                    end)
                end)
                jestExpect(Scheduler).toHaveYielded({
                    "a:new:two",
                    "b:new:two",
                    "Sync effect",
                })
            end)
        end)
        -- @gate experimental
        it("should only update components whose subscriptions fire", function()
            local source = createComplexSource("a:one", "b:one")
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)
            -- Subscribe to part of the store.
            local getSnapshotA = function(s)
                return s.valueA
            end
            local subscribeA = function(s, callback)
                return s.subscribeA(callback)
            end
            local getSnapshotB = function(s)
                return s.valueB
            end
            local subscribeB = function(s, callback)
                return s.subscribeB(callback)
            end

            act(function()
                ReactNoop.render(React.createElement(React.Fragment, nil, React.createElement(Component, {
                    label = "a",
                    getSnapshot = getSnapshotA,
                    mutableSource = mutableSource,
                    subscribe = subscribeA,
                }), React.createElement(Component, {
                    label = "b",
                    getSnapshot = getSnapshotB,
                    mutableSource = mutableSource,
                    subscribe = subscribeB,
                })), function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "a:a:one",
                    "b:b:one",
                    "Sync effect",
                })

                -- Changes to part of the store (e.g. A) should not render other parts.
                source.valueA = "a:two"

                jestExpect(Scheduler).toFlushAndYield({
                    "a:a:two",
                })

                source.valueB = "b:two"

                jestExpect(Scheduler).toFlushAndYield({
                    "b:b:two",
                })
            end)
        end)

        -- @gate experimental
        it("should detect tearing in part of the store not yet subscribed to", function()
            local source = createComplexSource("a:one", "b:one")
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)

            -- Subscribe to part of the store.
            local getSnapshotA = function(s)
                return s.valueA
            end
            local subscribeA = function(s, callback)
                return s.subscribeA(callback)
            end
            local getSnapshotB = function(s)
                return s.valueB
            end
            local subscribeB = function(s, callback)
                return s.subscribeB(callback)
            end

            act(function()
                -- Because the store has not changed yet, there are no pending updates,
                -- so it is considered safe to read from when we start this render.
                ReactNoop.render(React.createElement(React.Fragment, nil, React.createElement(Component, {
                    label = "a",
                    getSnapshot = getSnapshotA,
                    mutableSource = mutableSource,
                    subscribe = subscribeA,
                })), function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "a:a:one",
                    "Sync effect",
                })
                ReactNoop.render(React.createElement(React.Fragment, nil, React.createElement(Component, {
                    label = "a",
                    getSnapshot = getSnapshotA,
                    mutableSource = mutableSource,
                    subscribe = subscribeA,
                }), React.createElement(Component, {
                    label = "b",
                    getSnapshot = getSnapshotB,
                    mutableSource = mutableSource,
                    subscribe = subscribeB,
                }), React.createElement(Component, {
                    label = "c",
                    getSnapshot = getSnapshotB,
                    mutableSource = mutableSource,
                    subscribe = subscribeB,
                })), function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYieldThrough({
                    "a:a:one",
                    "b:b:one",
                })

                -- Mutating the source should trigger a tear detection on the next read,
                -- which should throw and re-render the entire tree.
                source.valueB = "b:two"

                jestExpect(Scheduler).toFlushAndYield({
                    "a:a:one",
                    "b:b:two",
                    "c:b:two",
                    "Sync effect",
                })
            end)
        end)
        -- ROBLOX TODO: jest.fn
        -- @gate experimental
        it("does not schedule an update for subscriptions that fire with an unchanged snapshot", function()
            -- ROBLOX TODO: jest.fn, temporarily uses Component in place of jest:fn(Component)
            local MockComponent = Component
            local source = createSource("one")
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)

            act(function()
                ReactNoop.render(React.createElement(MockComponent, {
                    label = "only",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                }), function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYieldThrough({
                    "only:one",
                    "Sync effect",
                })
                ReactNoop.flushPassiveEffects()
                jestExpect(source.listenerCount).toEqual(1)

                -- Notify subscribe function but don't change the value
                source.value = "one"

                jestExpect(Scheduler).toFlushWithoutYielding()
            end)
        end)
        -- @gate experimental
        it("should throw and restart if getSnapshot changes between scheduled update and re-render", function()
            local source = createSource("one")
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)
            local newGetSnapshot = function(s)
                return "new:" .. defaultGetSnapshot(s)
            end
            local getSnapshot, updateGetSnapshot

            local function WrapperWithState()
                -- ROBLOX deviation: useState has 2 returns, not tuple
                getSnapshot, updateGetSnapshot = React.useState(function()
                    return defaultGetSnapshot
                end)

                return React.createElement(Component, {
                    label = "only",
                    getSnapshot = getSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                })
            end

            act(function()
                ReactNoop.render(React.createElement(WrapperWithState, nil), function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "only:one",
                    "Sync effect",
                })
                ReactNoop.flushPassiveEffects()
                Scheduler.unstable_runWithPriority(Scheduler.unstable_LowPriority, function()
                    -- Change the source (and schedule an update).
                    source.value = "two"
                end)
                -- Schedule a higher priority update that changes getSnapshot.
                Scheduler.unstable_runWithPriority(Scheduler.unstable_UserBlockingPriority, function()
                    updateGetSnapshot(function()
                        return newGetSnapshot
                    end)
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "only:new:two",
                })
            end)
        end)
        -- @gate experimental
        it("should recover from a mutation during yield when other work is scheduled", function()
            local source = createSource("one")
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)

            act(function()
                -- Start a render that uses the mutable source.
                ReactNoop.render(React.createElement(React.Fragment, nil, React.createElement(Component, {
                    label = "a",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                }), React.createElement(Component, {
                    label = "b",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                })))
                jestExpect(Scheduler).toFlushAndYieldThrough({
                    "a:one",
                })

                -- Mutate source
                source.value = "two"

                -- Now render something different.
                ReactNoop.render(React.createElement("div", nil))
                jestExpect(Scheduler).toFlushAndYield({})
            end)
        end)
        -- @gate experimental
        it("should not throw if the new getSnapshot returns the same snapshot value", function()
            local source = createSource("one")
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)
            local onRenderA = jest.fn()
            local onRenderB = jest.fn()
            local getSnapshot, updateGetSnapshot

            local function WrapperWithState()
                getSnapshot, updateGetSnapshot = React.useState(function()
                    return defaultGetSnapshot
                end)

                return React.createElement(Component, {
                    label = "b",
                    getSnapshot = getSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                })
            end

            act(function()
                ReactNoop.render(React.createElement(React.Fragment, nil, React.createElement(React.Profiler, {
                    id = "a",
                    onRender = onRenderA,
                }, React.createElement(Component, {
                    label = "a",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                })), React.createElement(React.Profiler, {
                    id = "b",
                    onRender = onRenderB,
                }, React.createElement(WrapperWithState, nil))), function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "a:one",
                    "b:one",
                    "Sync effect",
                })
                ReactNoop.flushPassiveEffects()
                jestExpect(onRenderA).toHaveBeenCalledTimes(1)
                jestExpect(onRenderB).toHaveBeenCalledTimes(1)

                -- If B's getSnapshot function updates, but the snapshot it returns is the same,
                -- only B should re-render (to update its state).
                updateGetSnapshot(function()
                    return function(s)
                        return defaultGetSnapshot(s)
                    end
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "b:one",
                })
                ReactNoop.flushPassiveEffects()
                jestExpect(onRenderA).toHaveBeenCalledTimes(1)
                jestExpect(onRenderB).toHaveBeenCalledTimes(2)
            end)
        end)

        -- @gate experimental
        it("should not throw if getSnapshot changes but the source can be safely read from anyway", function()
            local source = createSource("one")
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)
            local newGetSnapshot = function(s)
                return"new:" .. defaultGetSnapshot(s)
            end
            local getSnapshot, updateGetSnapshot

            local function WrapperWithState()
                -- ROBLOX deviation: useState has 2 returns
                getSnapshot, updateGetSnapshot = React.useState(function()
                    return defaultGetSnapshot
                end)

                return React.createElement(Component, {
                    label = "only",
                    getSnapshot = getSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                })
            end

            act(function()
                ReactNoop.render(React.createElement(WrapperWithState, nil), function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "only:one",
                    "Sync effect",
                })
                ReactNoop.flushPassiveEffects()

                -- Change the source (and schedule an update)
                -- but also change the snapshot function too.
                ReactNoop.batchedUpdates(function()
                    source.value = "two"
                    updateGetSnapshot(function()
                        return newGetSnapshot
                    end)
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "only:new:two",
                })
            end)
        end)

        -- ROBLOX FIXME: fails with Error: Should have a queue
        -- @gate experimental
        xit("should still schedule an update if an eager selector throws after a mutation", function()
            local source = createSource({
                friends = {
                    {
                        id = 1,
                        name = "Foo",
                    },
                    {
                        id = 2,
                        name = "Bar",
                    },
                },
            })
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)

            local function Friend(props)
                local id = props.id
                local getSnapshot = React.useCallback(function(props_)
                    local value = props_.value
                    -- This selector is intentionally written in a way that will throw
                    -- if no matching friend exists in the store.
                    return Array.find(value.friends, function(friend)
                        return friend.id == id
                    end).name
                end, {id})
                local name = useMutableSource(mutableSource, getSnapshot, defaultSubscribe)

                Scheduler.unstable_yieldValue(("%s:%s"):format(id, name))

                return React.createElement("li", nil, name)
            end

            local function FriendsList()
                local getSnapshot = React.useCallback(function(props)
                    local value = props.value

                    return Array.from(value.friends)
                end, {})
                local friends = useMutableSource(mutableSource, getSnapshot, defaultSubscribe)

                return React.createElement("ul", nil, Array.map(friends, function(friend)
                    return React.createElement(Friend, {
                        key = friend.id,
                        id = friend.id,
                    })
                end))
            end

            act(function()
                ReactNoop.render(React.createElement(FriendsList), function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "1:Foo",
                    "2:Bar",
                    "Sync effect",
                })

                -- This mutation will cause the "Bar" component to throw,
                -- since its value will no longer be a part of the store.
                -- Mutable source should still schedule an update though,
                -- which should unmount "Bar" and mount "Baz".
                source.value = {
                    friends = {
                        {
                            id = 1,
                            name = "Foo",
                        },
                        {
                            id = 3,
                            name = "Baz",
                        },
                    },
                }

                jestExpect(Scheduler).toFlushAndYield({
                    "1:Foo",
                    "3:Baz",
                })
            end)
        end)

        -- @gate experimental
        it("should not warn about updates that fire between unmount and passive unsubscribe", function()
                local source = createSource("one")
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)

            local function Wrapper()
                React.useLayoutEffect(function()
                    return function()
                        Scheduler.unstable_yieldValue("layout unmount")
                    end
                end)

                return React.createElement(Component, {
                    label = "only",
                    getSnapshot = defaultGetSnapshot,
                    mutableSource = mutableSource,
                    subscribe = defaultSubscribe,
                })
            end

            act(function()
                ReactNoop.renderToRootWithID(React.createElement(Wrapper, nil), "root", function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYield({
                    "only:one",
                    "Sync effect",
                })
                ReactNoop.flushPassiveEffects()

                -- Unmounting a root should remove the remaining event listeners in a passive effect
                ReactNoop.unmountRootWithID("root")
                jestExpect(Scheduler).toFlushAndYieldThrough({
                    "layout unmount",
                })

                -- Changes to source should not cause a warning,
                -- even though the unsubscribe hasn't run yet (since it's a pending passive effect).
                source.value = "two"

                jestExpect(Scheduler).toFlushAndYield({})
            end)
        end)

        -- @gate experimental
        it("should support inline selectors and updates that are processed after selector change", function()
            local source = createSource({
                a = "initial",
                b = "initial",
            })
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)
            local getSnapshotA = function()
                return source.value.a
            end
            local getSnapshotB = function()
                return source.value.b
            end

            local function mutateB(newB)
                -- ROBLOX deviation: no table spread available, so we duplicate then add an entry for 'b'
                local tempTable = LuauPolyfill.Object.entries(source.value)
                tempTable.b = newB
                source.value = tempTable
            end
            local function App(props)
                local getSnapshot = props.getSnapshot
                local state = useMutableSource(mutableSource, getSnapshot, defaultSubscribe)

                return state
            end

            local root = ReactNoop.createRoot()

            act(function()
                root.render(React.createElement(App, {getSnapshot = getSnapshotA}))
            end)

            jestExpect(root).toMatchRenderedOutput("initial")

            act(function()
                mutateB("Updated B")
                root.render(React.createElement(App, {getSnapshot = getSnapshotB}))
            end)

            jestExpect(root).toMatchRenderedOutput("Updated B")

            act(function()
                mutateB("Another update")
            end)

            jestExpect(root).toMatchRenderedOutput("Another update")
        end)

        -- @gate experimental
        it("should clear the update queue when getSnapshot changes with pending lower priority updates", function()
            local source = createSource({
                a = "initial",
                b = "initial",
            })
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)
            local getSnapshotA = function()
                return source.value.a
            end
            local getSnapshotB = function()
                return source.value.b
            end

            local function mutateA(newA)
                -- ROBLOX deviation: no table spread available, so we duplicate then add an entry for 'a'
                local tempTable = LuauPolyfill.Object.assign({}, source.value)
                tempTable.a = newA
                source.value = tempTable
            end
            local function mutateB(newB)
                -- ROBLOX deviation: no table spread available, so we duplicate then add an entry for 'b'
                local tempTable = LuauPolyfill.Object.assign({}, source.value)
                tempTable.b = newB
                source.value = tempTable
            end
            local function App(props)
                local toggle = props.toggle
                local state = useMutableSource(mutableSource, (function()
                    if toggle then
                        return getSnapshotB
                    end

                    return getSnapshotA
                end)(), defaultSubscribe)
                local result = (function()
                    if toggle then
                        return"B: "
                    end

                    return"A: "
                end)() .. state

                return result
            end

            local root = ReactNoop.createRoot()
            act(function()
                root.render(React.createElement(App, {toggle = false}))
            end)

            jestExpect(root).toMatchRenderedOutput("A: initial")

            act(function()
                ReactNoop.discreteUpdates(function()
                    -- Update both A and B to the same value
                    mutateA("Update")
                    mutateB("Update") -- Toggle to B in the same batch

                    root.render(React.createElement(App, {toggle = true}))
                end)
                -- Mutate A at lower priority. This should never be rendered, because
                -- by the time we get to the lower priority, we've already switched
                -- to B.

                mutateA("OOPS! This mutation should be ignored")
            end)

            jestExpect(root).toMatchRenderedOutput("B: Update")
        end)

        -- @gate experimental
        it("should clear the update queue when source changes with pending lower priority updates", function()
                local sourceA = createSource("initial")
            local sourceB = createSource("initial")
            local mutableSourceA = createMutableSource(sourceA, function(param)
                return param.versionA
            end)
            local mutableSourceB = createMutableSource(sourceB, function(param)
                return param.versionB
            end)

            local function App(props)
                local toggle = props.toggle
                local state = useMutableSource((function()
                    if toggle then
                        return mutableSourceB
                    end

                    return mutableSourceA
                end)(), defaultGetSnapshot, defaultSubscribe)
                local result = (function()
                    if toggle then
                        return"B: "
                    end

                    return"A: "
                end)() .. state

                return result
            end

            local root = ReactNoop.createRoot()
            act(function()
                root.render(React.createElement(App, {toggle = false}))
            end)

            jestExpect(root).toMatchRenderedOutput("A: initial")

            act(function()
                ReactNoop.discreteUpdates(function()
                    -- Update both A and B to the same value
                    sourceA.value = "Update"
                    sourceB.value = "Update"
                    -- Toggle to B in the same batch
                    root.render(React.createElement(App, {toggle = true}))
                end)
                -- Mutate A at lower priority. This should never be rendered, because
                -- by the time we get to the lower priority, we've already switched
                -- to B.

                sourceA.value = "OOPS! This mutation should be ignored"
            end)

            jestExpect(root).toMatchRenderedOutput("B: Update")
        end)

        -- @gate experimental
        it("should always treat reading as potentially unsafe when getSnapshot changes between renders", function()
                local source = createSource({
                a = "foo",
                b = "bar",
            })
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)
            local getSnapshotA = function()
                return source.value.a
            end
            local getSnapshotB = function()
                return source.value.b
            end

            local function mutateA(newA)
                -- ROBLOX deviation: no table spread available, so we duplicate then add an entry for 'a'
                local tempTable = LuauPolyfill.Object.assign({}, source.value)
                tempTable.a = newA
                source.value = tempTable
            end
            local function App(props)
                local getSnapshotFirst, getSnapshotSecond = props.getSnapshotFirst, props.getSnapshotSecond
                local first = useMutableSource(mutableSource, getSnapshotFirst, defaultSubscribe)
                local second = useMutableSource(mutableSource, getSnapshotSecond, defaultSubscribe)
                local result = ("x: %s, y: %s"):format(first, second)

                if getSnapshotFirst == getSnapshotSecond then
                    -- When both getSnapshot functions are equal,
                    -- the two values must be consistent.
                    if first ~= second then
                        result = "Oops, tearing!"
                    end
                end

                React.useEffect(function()
                    Scheduler.unstable_yieldValue(result)
                end, {result})

                return result
            end

            local root = ReactNoop.createRoot()
            act(function()
                root.render(React.createElement(App, {
                    getSnapshotFirst = getSnapshotA,
                    getSnapshotSecond = getSnapshotB}))
            end)

            -- x and y start out reading from different parts of the store.
            jestExpect(Scheduler).toHaveYielded({
                "x: foo, y: bar",
            })

            act(function()
                ReactNoop.discreteUpdates(function()
                -- At high priority, toggle y so that it reads from A instead of B.
                -- Simultaneously, mutate A.
                mutateA("baz")
                root.render(React.createElement(App, {
                    getSnapshotFirst = getSnapshotA,
                    getSnapshotSecond = getSnapshotA}))
                    -- If this update were processed before the next mutation,
                    -- it would be expected to yield "baz" and "baz".
                end)

                -- At lower priority, mutate A again.
                -- This happens to match the initial value of B.
                mutateA("bar");

                -- When this update is processed,
                -- it is expected to yield "bar" and "bar".
            end)

            -- Check that we didn't commit any inconsistent states.
            -- The actual sequence of work will be:
            -- 1. React renders the high-pri update, sees a new getSnapshot, detects the source has been further mutated, and throws
            -- 2. React re-renders with all pending updates, including the second mutation, and renders "bar" and "bar".
            jestExpect(Scheduler).toHaveYielded({
                "x: bar, y: bar",
            })
        end)

        -- ROBLOX TODO: unimplemented toFlushUntilNextPaint
        -- @gate experimental
        xit("getSnapshot changes and then source is mutated in between paint and passive effect phase", function()
            local source = createSource({
                a = "foo",
                b = "bar",
            })
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)

            local function mutateB(newB)
                -- ROBLOX deviation: no table spread available, so we duplicate then add an entry for 'b'
                local tempTable = LuauPolyfill.Object.entries(source.value)
                tempTable.b = newB
                source.value = tempTable
            end

            local getSnapshotA = function()
                return source.value.a
            end
            local getSnapshotB = function()
                return source.value.b
            end

            local function App(props)
                local getSnapshot = props.getSnapshot
                local value = useMutableSource(mutableSource, getSnapshot, defaultSubscribe)

                Scheduler.unstable_yieldValue("Render: " .. value)
                React.useEffect(function()
                    Scheduler.unstable_yieldValue("Commit: " .. value)
                end, {value})

                return value
            end

            local root = ReactNoop.createRoot()
            act(function()
                root.render(React.createElement(App, {
                    getSnapshot = getSnapshotA}))
            end)

            jestExpect(Scheduler).toHaveYielded({
                "Render: foo",
                "Commit: foo",
            })

            act(function()
                -- Switch getSnapshot to read from B instead
                root.render(React.createElement(App, {
                    getSnapshot = getSnapshotB}))
                -- Render and finish the tree, but yield right after paint, before
                -- the passive effects have fired.
                jestExpect(Scheduler).toFlushUntilNextPaint({"Render: bar"})
                -- Then mutate B.
                mutateB("baz");
            end)

            jestExpect(Scheduler).toHaveYielded({
                "Render: bar",
                -- Fires the effect from the previous render
                "Commit: bar",
                -- During that effect, it should detect that the snapshot has changed
                -- and re-render.
                "Render: baz",
                "Commit: baz",
            })
            jestExpect(root).toMatchRenderedOutput("baz")
        end)

        -- ROBLOX TODO: unimplemented toFlushUntilNextPaint() and getChildrenAsJSX()
        -- @gate experimental
        xit("getSnapshot changes and then source is mutated in between paint and passive effect phase, case 2", function()
                local source = createSource({
                a = "a0",
                b = "b0",
            })
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)
            local getSnapshotA = function()
                return source.value.a
            end
            local getSnapshotB = function()
                return source.value.b
            end

            local function mutateA(newA)
                -- ROBLOX deviation: no table spread available, so we duplicate then add an entry for 'a'
                local tempTable = LuauPolyfill.Object.entries(source.value)
                tempTable.A = newA
                source.value = tempTable
            end
            local function App(props)
                local getSnapshotFirst, getSnapshotSecond = props.getSnapshotFirst, props.getSnapshotSecond
                local first = useMutableSource(mutableSource, getSnapshotFirst, defaultSubscribe)
                local second = useMutableSource(mutableSource, getSnapshotSecond, defaultSubscribe)

                return("first: %s, second: %s"):format(first, second)
            end

            local root = ReactNoop.createRoot()
            act(function()
                root.render(React.createElement(App, {
                    getSnapshotFirst = getSnapshotA,
                    getSnapshotSecond = getSnapshotB}))
            end)
            jestExpect(root.getChildrenAsJSX()).toEqual("first: a0, second: b0")

            act(function()
                -- Switch the second getSnapshot to also read from A
                root.render(React.createElement(App, {
                    getSnapshotFirst = getSnapshotA,
                    getSnapshotSecond = getSnapshotB}))
                -- Render and finish the tree, but yield right after paint, before
                -- the passive effects have fired.
                jestExpect(Scheduler).toFlushUntilNextPaint({})

                -- Now mutate A. Both hooks should update.
                -- This is at high priority so that it doesn't get batched with default
                -- priority updates that might fire during the passive effect
                ReactNoop.discreteUpdates(function()
                    mutateA("a1")
                end)
                jestExpect(Scheduler).toFlushUntilNextPaint({})

                jestExpect(root.getChildrenAsJSX()).toEqual("first: a1, second: a1")
            end)
            jestExpect(root.getChildrenAsJSX()).toEqual("first: a1, second: a1")
        end)

        -- ROBLOX TODO: unimplemented toFlushUntilNextPaint()
        -- @gate experimental
        xit("if source is mutated after initial read but before subscription is set " ..
         "up, should still entangle all pending mutations even if snapshot of " .. "new subscription happens to match", function(
        )
            local source = createSource({
                a = "a0",
                b = "b0",
            })
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)
            local getSnapshotA = function()
                return source.value.a
            end
            local getSnapshotB = function()
                return source.value.b
            end

            local function mutateA(newA)
                -- ROBLOX deviation: no table spread available, so we duplicate then add an entry for 'a'
                local tempTable = LuauPolyfill.Object.assign({}, source.value)
                tempTable.a = newA
                source.value = tempTable
            end
            local function mutateB(newB)
                -- ROBLOX deviation: no table spread available, so we duplicate then add an entry for 'b'
                local tempTable = LuauPolyfill.Object.assign({}, source.value)
                tempTable.b = newB
                source.value = tempTable
            end
            local function Read(props)
                local getSnapshot = props.getSnapshot
                local value = useMutableSource(mutableSource, getSnapshot, defaultSubscribe)

                Scheduler.unstable_yieldValue(value)

                return value
            end
            local function Text(props)
                local text = props.text

                Scheduler.unstable_yieldValue(text)

                return text
            end

            local root = ReactNoop.createRoot()
            act(function()
                root.render(React.createElement(Read, {
                    getSnapshot = getSnapshotA}))
            end)

            jestExpect(Scheduler).toHaveYielded({
                "a0",
            })
            jestExpect(root).toMatchRenderedOutput("a0")
            act(function()
                root.render(React.createElement(React.Fragment, nil,
                    React.createElement(Read, {
                        getSnapshotFirst = getSnapshotA}),
                    React.createElement(Read, {
                        getSnapshotFirst = getSnapshotB}),
                    React.createElement(Text, {
                        text = "c"})
                    ))
                jestExpect(Scheduler).toFlushAndYieldThrough({"a0", "b0"})
                -- Mutate in an event. This schedules a subscription update on a, which
                -- already mounted, but not b, which hasn't subscribed yet.
                mutateA("a1")
                mutateB("b1")

                -- Mutate again at lower priority. This will schedule another subscription
                -- update on a, but not b. When b mounts and subscriptions, the value it
                -- read during render will happen to match the latest value. But it should
                -- still entangle the updates to prevent the previous update (a1) from
                -- rendering by itself.
                Scheduler.unstable_runWithPriority(
                    Scheduler.unstable_IdlePriority,
                    function()
                        mutateA("a0")
                        mutateB("b0")
                    end
                )
                -- Finish the current render
                jestExpect(Scheduler).toFlushUntilNextPaint({"c"})
                -- a0 will re-render because of the mutation update. But it should show
                -- the latest value, not the intermediate one, to avoid tearing with b.
                jestExpect(Scheduler).toFlushUntilNextPaint({"a0"})
                jestExpect(root).toMatchRenderedOutput("a0b0c")
                -- We should be done.
                jestExpect(Scheduler).toFlushAndYield({})
                jestExpect(root).toMatchRenderedOutput("a0b0c")
            end)
        end)

        -- @gate experimental
        it("warns about functions being used as snapshot values", function()
                local source = createSource(function()
                return"a"
            end)
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)
            local getSnapshot = function()
                return source.value
            end

            local function Read()
                local fn = useMutableSource(mutableSource, getSnapshot, defaultSubscribe)
                local value = fn()
                Scheduler.unstable_yieldValue(value)
                return value
            end

            local root = ReactNoop.createRoot()
            act(function()
                root.render(React.createElement(
                    React.Fragment,
                    nil,
                    React.createElement(Read)
                ))
                jestExpect(
                    function()
                        jestExpect(Scheduler).toFlushAndYield({"a"})
                    end
                ).toErrorDev("Mutable source should not return a function as the snapshot value.")
                end)

            jestExpect(root).toMatchRenderedOutput("a")
        end)

        -- @gate experimental
        it("getSnapshot changes and then source is mutated during interleaved event", function()
            local useEffect = React.useEffect

            local source = createComplexSource("1", "2")
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)

            -- Subscribe to part of the store.
            local getSnapshotA = function(s)
                return s.valueA
            end
            local subscribeA = function(s, callback)
                return s.subscribeA(callback)
            end
            local configA = {getSnapshotA, subscribeA}
            local getSnapshotB = function(s)
                return s.valueB
            end
            local subscribeB = function(s, callback)
                return s.subscribeB(callback)
            end
            local configB = {getSnapshotB, subscribeB}

            local function Child(props)
                local parentConfig, childConfig, parentValue = props.parentConfig, props.childConfig, props.parentValue
                local getSnapshot, subscribe = childConfig[1], childConfig[2]
                local childValue = useMutableSource(mutableSource, getSnapshot, subscribe)

                Scheduler.unstable_yieldValue("Child: " .. childValue)

                local result = ("%s, %s"):format(parentValue, childValue)

                if parentConfig == childConfig then
                    -- When both components read using the same config, the two values
                    -- must be consistent.
                    if parentValue ~= childValue then
                        result = "Oops, tearing!"
                    end
                end

                useEffect(function()
                    Scheduler.unstable_yieldValue("Commit: " .. result)
                end, {result})

                return result
            end

            local function App(props)
                local parentConfig, childConfig = props.parentConfig, props.childConfig
                local getSnapshot, subscribe = parentConfig[1], parentConfig[2]
                local parentValue = useMutableSource(mutableSource, getSnapshot, subscribe)
                Scheduler.unstable_yieldValue("Parent: " .. parentValue)

                return React.createElement(Child, {
                    parentConfig = parentConfig,
                    childConfig = childConfig,
                    parentValue = parentValue,
                })
            end

            local root = ReactNoop.createRoot()
            Promise.try(function()
                act(function()
                    root.render(React.createElement(App, {parentConfig = configA, childConfig = configB}))
                end)
            end):await()


            jestExpect(Scheduler).toHaveYielded({
                "Parent: 1",
                "Child: 2",
                "Commit: 1, 2",
            })
            act(function()
                -- Switch the parent and the child to read using the same config
                root.render(React.createElement(App, {parentConfig = configB, childConfig = configB}))
                -- Start rendering the parent, but yield before rendering the child
                jestExpect(Scheduler).toFlushAndYieldThrough({"Parent: 2"})

                -- Mutate the config. This is at lower priority so that 1) to make sure
                -- it doesn't happen to get batched with the in-progress render, and 2)
                -- so it doesn't interrupt the in-progress render.
                Scheduler.unstable_runWithPriority(
                    Scheduler.unstable_IdlePriority,
                    function()
                    source.valueB = "3"
                    end
                )

                jestExpect(Scheduler).toFlushAndYieldThrough({
                    -- The partial render completes
                    "Child: 2",
                    "Commit: 2, 2",
                })

                -- Now there are two pending mutations at different priorities. But they
                -- both read the same version of the mutable source, so we must render
                -- them simultaneously.
                --
                jestExpect(Scheduler).toFlushAndYieldThrough({
                    "Parent: 3",
                    -- Demonstrates that we can yield here
                })
                jestExpect(Scheduler).toFlushAndYield({
                    -- Now finish the rest of the update
                    "Child: 3",
                    "Commit: 3, 3"
                })
            end)

        end)

        -- @gate experimental
        it("should not tear with newly mounted component when updates were scheduled at a lower priority", function()
            local source = createSource("one")
            local mutableSource = createMutableSource(source, function(param)
                return param.version
            end)
            local committedA = nil
            local committedB = nil
            local onRender = function()
                if committedB ~= nil then
                    jestExpect(committedA).toEqual(committedB)
                end
            end

            local function ComponentA()
                local snapshot = useMutableSource(mutableSource, defaultGetSnapshot, defaultSubscribe)

                Scheduler.unstable_yieldValue(("a:%s"):format(snapshot))
                React.useEffect(function()
                    committedA = snapshot
                end, {snapshot})

                return React.createElement("div", nil, ("a:%s"):format(snapshot))
            end
            local function ComponentB()
                local snapshot = useMutableSource(mutableSource, defaultGetSnapshot, defaultSubscribe)

                Scheduler.unstable_yieldValue(("b:%s"):format(snapshot))
                React.useEffect(function()
                    committedB = snapshot
                end, {snapshot})

                return React.createElement("div", nil, ("b:%s"):format(snapshot))
            end

            -- Mount ComponentA with data version 1
            act(function()
                ReactNoop.render(React.createElement(React.Profiler, {
                    id = "root",
                    onRender = onRender,
                }, React.createElement(ComponentA, nil)), function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
            end)
            jestExpect(Scheduler).toHaveYielded({
                "a:one",
                "Sync effect",
            })
            jestExpect(source.listenerCount).toEqual(1)

            -- Mount ComponentB with version 1 (but don't commit it)
            act(function()
                ReactNoop.render(React.createElement(React.Profiler, {
                    id = "root",
                    onRender = onRender,
                }, React.createElement(ComponentA, nil), React.createElement(ComponentB, nil)), function()
                    return Scheduler.unstable_yieldValue("Sync effect")
                end)
                jestExpect(Scheduler).toFlushAndYieldThrough({
                    "a:one",
                    "b:one",
                    "Sync effect",
                })
                jestExpect(source.listenerCount).toEqual(1)

                -- Mutate -> schedule update for ComponentA
                Scheduler.unstable_runWithPriority(Scheduler.unstable_IdlePriority, function()
                    source.value = "two"
                end)

                -- Commit ComponentB -> notice the change and schedule an update for ComponentB
                jestExpect(Scheduler).toFlushAndYield({
                    "a:two",
                    "b:two",
                })
                jestExpect(source.listenerCount).toEqual(2)
            end)
        end)

        if _G.__DEV__ then
            describe("dev warnings", function()
                -- @gate experimental
                it("should warn if the subscribe function does not return an unsubscribe function", function()
                            local source = createSource("one")
                    local mutableSource = createMutableSource(source, function(param)
                        return param.version
                    end)
                    local brokenSubscribe = function() end

                    jestExpect(function()
                        act(function()
                            ReactNoop.render(React.createElement(Component, {
                                label = "only",
                                getSnapshot = defaultGetSnapshot,
                                mutableSource = mutableSource,
                                subscribe = brokenSubscribe,
                            }))
                        end)
                    end).toErrorDev("Mutable source subscribe function must return an unsubscribe function.")
                end)

                -- -- ROBLOX TODO: spyOnDev
                -- -- @gate experimental
                -- xit('should error if multiple renderers of the same type use a mutable source at the same time', function()
                --             --     local source = createSource('one')
                --     local mutableSource = createMutableSource(source, function(param)
                --         return param.version
                --     end)

                --     act(function()
                --         -- Start a render that uses the mutable source.
                --         ReactNoop.render(React.createElement(React.Fragment, nil, React.createElement(Component, {
                --             label = 'a',
                --             getSnapshot = defaultGetSnapshot,
                --             mutableSource = mutableSource,
                --             subscribe = defaultSubscribe,
                --         }), React.createElement(Component, {
                --             label = 'b',
                --             getSnapshot = defaultGetSnapshot,
                --             mutableSource = mutableSource,
                --             subscribe = defaultSubscribe,
                --         })))
                --         jestExpect(Scheduler).toFlushAndYieldThrough({
                --             'a:one',
                --         })

                --         local PrevScheduler = Scheduler
                --         -- Get a new copy of ReactNoop.

                --         loadModules()

                --         spyOnDev(console, 'error')

                --         -- Use the mutablesource again but with a different renderer.
                --         ReactNoop.render(React.createElement(Component, {
                --             label = 'c',
                --             getSnapshot = defaultGetSnapshot,
                --             mutableSource = mutableSource,
                --             subscribe = defaultSubscribe,
                --         }))
                --         jestExpect(Scheduler).toFlushAndYieldThrough({
                --             'c:one',
                --         })
                --         jestExpect(console.error.calls.argsFor(0)[0]).toContain('Detected multiple renderers concurrently rendering the ' + 'same mutable source. This is currently unsupported.')

                --         -- TODO (useMutableSource) Act will automatically flush remaining work from render 1,
                --         -- but at this point something in the hooks dispatcher has been broken by jest.resetModules()
                --         -- Figure out what this is and remove this catch.
                --         jestExpect(function()
                --             return PrevScheduler.unstable_flushAllWithoutAsserting()
                --         end).toThrow('Invalid hook call')
                --     end)
                -- end)

                -- -- ROBLOX TODO: spyOnDev
                -- @gate experimental
                -- xit('should error if multiple renderers of the same type use a mutable source at the same time with mutation between', function(
                -- )
                --         --     local source = createSource('one')
                --     local mutableSource = createMutableSource(source, function(param)
                --         return param.version
                --     end)

                --     act(function()
                --         -- Start a render that uses the mutable source.
                --         ReactNoop.render(React.createElement(React.Fragment, nil, React.createElement(Component, {
                --             label = 'a',
                --             getSnapshot = defaultGetSnapshot,
                --             mutableSource = mutableSource,
                --             subscribe = defaultSubscribe,
                --         }), React.createElement(Component, {
                --             label = 'b',
                --             getSnapshot = defaultGetSnapshot,
                --             mutableSource = mutableSource,
                --             subscribe = defaultSubscribe,
                --         })))
                --         jestExpect(Scheduler).toFlushAndYieldThrough({
                --             'a:one',
                --         })

                --         local PrevScheduler = Scheduler

                --         -- Get a new copy of ReactNoop.
                --         loadModules()

                --         spyOnDev(console, 'error')

                --         -- Mutate before the new render reads from the source.
                --         source.value ='two')

                --         -- Use the mutablesource again but with a different renderer.
                --         ReactNoop.render(React.createElement(Component, {
                --             label = 'c',
                --             getSnapshot = defaultGetSnapshot,
                --             mutableSource = mutableSource,
                --             subscribe = defaultSubscribe,
                --         }))
                --         jestExpect(Scheduler).toFlushAndYieldThrough({
                --             'c:two',
                --         })
                --         jestExpect(console.error.calls.argsFor(0)[0]).toContain('Detected multiple renderers concurrently rendering the ' .. 'same mutable source. This is currently unsupported.')

                --         -- TODO (useMutableSource) Act will automatically flush remaining work from render 1,
                --         -- but at this point something in the hooks dispatcher has been broken by jest.resetModules()
                --         -- Figure out what this is and remove this catch.
                --         jestExpect(function()
                --             return PrevScheduler.unstable_flushAllWithoutAsserting()
                --         end).toThrow('Invalid hook call')
                --     end)
                -- end)
            end)
        end
    end)
end