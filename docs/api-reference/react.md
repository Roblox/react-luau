# React

The React package is the entry point for most React logic and behavior. Most members align directly to their equivalents in [React JS](https://reactjs.org/docs/react-api.html). Some API members have slightly different behavior, different guidance around their use, or slightly different function signatures to better accommodate Luau functionality and idioms.

There are currently a few notable absences from React JS 17.0.1:

* `React.createFactory` - Considered legacy and will likely not be included
* `React.useDebugValue` - Not yet implemented

There are also some features that are undocumented in React JS 17.0.1, but are implemented. The following are included, but may be less stable than existing features:

* `React.createMutableSource`
* `React.useMutableSource`

## React.Component
Refer to [`React.Component` documentation](https://reactjs.org/docs/react-api.html#reactcomponent).

### Deviations
Luau does not have ES6's class semantics, so class components work differently from React JS in a few ways:

* Use `Component:extend` in place of ES6 class semantics
* Implement an `init` method on components instead of a constructor
* Instead of initializing component state by assigning a value to `self.state` in the `init` method, use `setState` as you would elsewhere

Check the [deviations guide](../deviations.md#class-components) for more detailed information.

## React.PureComponent
Refer to [`React.PureComponent` documentation](https://reactjs.org/docs/react-api.html#reactpurecomponent).

### Deviations
The same deviations to `React.Component` apply equivalently to `React.PureComponent`. Check the [deviations guide](../deviations.md#class-components) for more detailed information.

## React.memo
Refer to [`React.memo` documentation](https://reactjs.org/docs/react-api.html#reactmemo). Guidance specified in the React documentation applies to Roact as well. Use this only as a performance optimization, and only when relevant to the use case.

## React.createElement
Refer to [`React.createElement` documentation](https://reactjs.org/docs/react-api.html#createelement).

### Deviations

* (actual behavior is the same)
* (however, unlike in React, createElement is not superseded by JSX)

## React.cloneElement
Refer to [`React.cloneElement` documentation](https://reactjs.org/docs/react-api.html#cloneelement).

## React.isValidElement
Refer to [`React.isValidElement` documentation](https://reactjs.org/docs/react-api.html#isvalidelement).

## React.Children
Refer to [`React.Children` documentation](https://reactjs.org/docs/react-api.html#reactchildren).

### Deviations

* React Children with type "userdata" will be treated as nil in callbacks. This means that a `React.None` child passed to forEach or map will be treated the same as a nil value or boolean in the callbacks. React.Children.count will not include userdata children in the count.
* The `context` argument for mapChildren is not passed to the callback. This is typically used to pass `this` in javascript, but does not have an equivalent in lua.
* React Children works with keyed arrays

### React.Children.only
Refer to [`React.Children.only` documentation](https://reactjs.org/docs/react-api.html#reactchildrenonly).

### React.Children.map
Refer to [`React.Children.map` documentation](https://reactjs.org/docs/react-api.html#reactchildrenmap)

### React.Children.toArray
Refer to [`React.Children.toArray` documentation](https://reactjs.org/docs/react-api.html#reactchildrentoarray)

### React.Children.forEach
Refer to [`React.Children.forEach` documentation](https://reactjs.org/docs/react-api.html#reactchildrenforeach)

### React.Children.count
Refer to [`React.Children.count` documentation](https://reactjs.org/docs/react-api.html#reactchildrencount)

## React.Fragment
Refer to [`React.Fragment` documentation](https://reactjs.org/docs/react-api.html#reactfragment).

## React.createRef
Refer to [`React.createRef` documentation](https://reactjs.org/docs/react-api.html#reactcreateref).

## React.forwardRef
Refer to [`React.forwardRef` documentation](https://reactjs.org/docs/react-api.html#reactforwardref).

## React.createContext
Refer to [`React.createContext` documentation](https://reactjs.org/docs/context.html#reactcreatecontext).

## React.lazy
Refer to [`React.Children.only` documentation](https://reactjs.org/docs/react-api.html#reactchildrenonly).

## React.Suspense
Refer to [`React.Children.only` documentation](https://reactjs.org/docs/react-api.html#reactchildrenonly).


## React.useState

Refer to [`React.useState` documentation](https://reactjs.org/docs/hooks-reference.html#usestate).

### Deviations

Luau does not have syntactic sugar for destructuring like javascript:
```js
const [value, setValue] = React.useState(0);
```
However, it _does_ support multiple return values, so we can support a very similar usage:
```lua
local value, setValue = React.useState(0)
```

## React.useEffect
Refer to [`React.useEffect` documentation](https://reactjs.org/docs/hooks-reference.html#useeffect).

## React.useContext
Refer to [`React.useContext` documentation](https://reactjs.org/docs/hooks-reference.html?#usecontext).

## React.useReducer
Refer to [`React.useReducer` documentation](https://reactjs.org/docs/hooks-reference.html#usereducer).

## React.useCallback
Refer to [`React.useCallback` documentation](https://reactjs.org/docs/hooks-reference.html#usecallback).

## React.useMemo
Refer to [`React.useMemo` documentation](https://reactjs.org/docs/hooks-reference.html#usememo).

## React.useRef
Refer to [`React.useRef` documentation](https://reactjs.org/docs/hooks-reference.html#useref).

## React.useImperativeHandle
Refer to [`React.useImperativeHandle` documentation](https://reactjs.org/docs/hooks-reference.html?#useimperativehandle).

## React.useLayoutEffect
Refer to [`React.useLayoutEffect` documentation](https://reactjs.org/docs/hooks-reference.html?#uselayouteffect).

## React.Profiler
Refer to [React Profiler API documentation](https://reactjs.org/docs/profiler.html).

## React.StrictMode
Refer to [React StrictMode API documentation](https://reactjs.org/docs/strict-mode.html).

## React.createMutableSource
Refer to [relevant React RFC](https://github.com/reactjs/rfcs/pull/147).

## React.useMutableSource
Refer to [relevant React RFC](https://github.com/reactjs/rfcs/pull/147).

<!-- Roact only -->
## React.None
*This API is unique to Roact and does not have an equivalent in React JS.*

A placeholder value that can be used to remove fields from a table (by changing the value to nil) when merging tables. This allows state fields to be nil-able despite lua treating table fields with `nil` values as semantically equivalent to absent fields.

`React.None` can be used to remove values from React class component state via these uses:

* When returning a table from the updater function passed to a class component's [`setState`]() method
    ```lua
    self:setState(function(_prevState)
        return { myStateValue = React.None }
    end)
    ```
* When passing a table directly to a class component's `setState` method
    ```lua
    self:setState({ myStateValue = React.None })
    ```
* When returning a table from a component's `getDerivedStateFromProps` implementation
    ```lua
    function MyComponent.getDerivedStateFromProps(props, state)
        return {
            value = if props.someCondition
                then state.value
                else React.None
        }
    end
    ```

!!! caution
    `React.None` should be used sparingly; component state fields can generally be expressed more clearly with enumerated values or reasonable defaults than with nil-able values.

    Additionally, `React.None` is not intended to be used as a prop value, and may be reverted to nil by internal React logic in some cases if it's provided as one.

## React.Event
*Roact-only*

A special key that can be used to interact with events available on Roblox Instance objects. This behavior matches [the equivalent behavior in legacy Roact](https://roblox.github.io/roact/guide/events/).

## React.Change
*Roact-only*

A special key that can be used to interact with the `GetPropertyChangedSignal` functionality available on Roblox Instance objects. This behavior matches [the equivalent behavior in legacy Roact](https://roblox.github.io/roact/guide/events/).

## React.Tag
*Roact-only*

```lua
local button = Roact.createElement("TextButton", {
    [React.Tag] = "confirm-button"
    Text = "Confirm",
    -- ...
})
```

A special key that can be used to apply [`CollectionService`](https://developer.roblox.com/en-us/api-reference/class/CollectionService) tags to a host component. Multiple tags can be provided as a single space-delimited string. For example:
```lua
[React.Tag] = "some-tag some-other-tag"
```
will apply "some-tag" and "some-other-tag" as `CollectionService` tags to the underlying Roblox Instance when the component mounts it.

## React.createBinding
*This API is unique to Roact and does not have an equivalent in React JS.*

Creates a binding object. This a feature from legacy Roact that's been ported into Roact 17. [Refer to legacy documentation on `Roact.createBinding`](https://roblox.github.io/roact/api-reference/#roactcreatebinding).

## React.joinBindings
*This API is unique to Roact and does not have an equivalent in React JS.*

Joins multiple bindings together. This is a feature from legacy Roact that's been ported into Roact 17. [Refer to legacy documentation on `Roact.joinBindings`](https://roblox.github.io/roact/api-reference/#roactjoinbindings).

## React.useBinding

!!! warning "Unreleased"

*This API is unique to Roact and does not have an equivalent in React JS.*

A [hook](https://reactjs.org/docs/hooks-intro.html) introduced in Roact to complement its [bindings](#reactcreatebinding) feature. Creates and returns a binding and its associated updater function as multiple return values, [similar to `useState`](#reactusestate).

```
useBinding<T>(initialValue: T) -> (ReactBinding<T>, (T) -> ())
```

In class components, you would typically use `createBinding` in your component's `init` lifecycle method to generate a reusable binding.

In function components, the `useBinding` hook provides equivalent functionality, and guarantees that it will return the same binding and updater objects on subsequent calls (just like `useRef` does).

```lua
local function MyComponent(props)
    local absSize, setAbsSize = React.useBinding(Vector2.new(0, 0))
    return React.createElement(React.Fragment, nil,
        React.createElement("ImageLabel", {
            Image = props.image,
            [React.Change.AbsoluteSize] = setAbsSize,
        }),
        React.createElement("TextLabel", {
            Text = absSize:map(function(value)
                return "X = " .. tostring(value.X) .. "; Y = " .. tostring(value.Y)
            end)
        }
    )
end
```
