# React

The React package is the entry point for most React logic and behavior. Most members align directly to their equivalents in [React JS](https://reactjs.org/docs/react-api.html). Some API members have slightly different behavior, different guidance around their use, or slightly different function signatures to better accomodate Luau functionality and idioms.

There are currently a few notable absences from React JS 17.0.1:

* `React.createFactory` - Considered legacy and will likely not be included
* `React.useDebugValue` - Not yet implemented
* `React.Children.forEach` - Not yet implemented
* `React.Children.map` - Not yet implemented
* `React.Children.count` - Not yet implemented
* `React.Children.toArray` - Not yet implemented

There are also some features that are undocumented in React JS 17.0.1, but are implemented. The following are included, but may be less stable than existing features:

* `React.createMutableSource`
* `React.useMutableSource`

## React.Component
Refer to [`React.Component` documentation](https://reactjs.org/docs/react-api.html#reactcomponent).

### Devaitions

* (use `:extend` in place of ES6 class semantics)
* (implement `:init` instead of a constructor)
* (rules about setState and `init`)
* (this should probably be a brief section that links to more detailed deviations info)

## React.PureComponent
Refer to [`React.PureComponent` documentation](https://reactjs.org/docs/react-api.html#reactpurecomponent).

### Deviations

* (same rules apply as above)
* (link to same deviations section)

## React.memo
Refer to [`React.memo` documentation](https://reactjs.org/docs/react-api.html#reactmemo). Guidance specified in the React documenation applies to Roact as well. Use this only as a performance optimization, and only when relevant to the use case.

## React.createElement
Refer to [`React.createElement` documentation](https://reactjs.org/docs/react-api.html#createelement).

### Deviations

* (actual behavior is the same)
* (however, unlike in React, createElement is not superceded by JSX)

## React.cloneElement
Refer to [`React.cloneElement` documentation](https://reactjs.org/docs/react-api.html#cloneelement).

## React.isValidElement
Refer to [`React.isValidElement` documentation](https://reactjs.org/docs/react-api.html#isvalidelement).

## React.Children
Refer to [`React.Children` documentation](https://reactjs.org/docs/react-api.html#reactchildren).

At this time, only `React.Children.only` is implemented.

### React.Children.only
Refer to [`React.Children.only` documentation](https://reactjs.org/docs/react-api.html#reactchildrenonly).

## React.Fragment
Refer to [`React.Fragment` documentation](https://reactjs.org/docs/react-api.html#reactfragment).

## React.createRef
Refer to [`React.createRef` documentation](https://reactjs.org/docs/react-api.html#reactcreateref).

## React.forwardRef
Refer to [`React.forwardRef` documentation](https://reactjs.org/docs/react-api.html#reactforwardref).

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
## React.createBinding
*Roact-only*
Creates a binding object. This a feature from legacy Roact that's been ported into Roact 17. [Refer to legacy documenation on `Roact.createBinding`](https://roblox.github.io/roact/api-reference/#roactcreatebinding).

## React.joinBindings
*Roact-only*
Joins multiple bindings together. This is a feature from legacy Roact that's been ported into Roact 17. [Refer to legacy documenation on `Roact.joinBindings`](https://roblox.github.io/roact/api-reference/#roactjoinbindings).
