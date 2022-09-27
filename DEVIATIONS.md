
# Deviations and Conflicts
Upstream naming and logic has some deviations and incompatibilities with existing Roact. These will need to be addressed before aligned Roact can run existing Roact codebases. I'm expecting to do a combination of refactoring those codebases and introducing compatibility layers.

#### Table of Contents
* [Naming](#naming)
  * [Component Lifecycle](#component-lifecycle) c
  * [Reserved Prop Keys: "ref"](#reserved-prop-keys-ref) ✔️
  * [Reserved Prop Keys: "key"](#reserved-prop-keys-key) ✔️
  * [Reserved Prop Keys: "children"](#reserved-prop-keys-children) ✔️
* [Behavior](#behavior)
  * [Old Context](#old-context-roact-only) ✔️
  * [Context.Consumer Interface](#contextconsumer-interface) ✔️
  * [createFragment](#createfragment) ✔️
  * [Ref Forwarding](#ref-forwarding)
  * [Stable Keys](#stable-keys) ✔️
  * [Use of setState](#use-of-setstate) ✔️
  * [Functional setState](#functional-setstate) ✔️
  * [Roact.Portal](#roactportal) ✔️
  * [State Initialization](#state-initialization) ✔️
  * [Functional setState Signature](#functional-setstate-signature) ✔️

## Naming

### Component Lifecycle
**Status:** ✔️ Resolved (backwards compatible with deprecation warnings)
<details>
  <summary>Details</summary>

A portion of the component lifecycle methods exclude the `component` part of their name in Roact.

Lifecycle methods that will not conflict:
* Deprecated lifecycle methods that were never implemented in Roact to begin with: `componentWillMount`, `componentWillReceiveProps`
* Upstream lifecycle methods that will be new additions to Roact: `getDerivedStateFromError`, `componentDidCatch`, `getSnapshotBeforeUpdate`
* Lifecycle methods whose names are already aligned: `render`, `getDerivedStateFromProps`

The conflicting lifecycle names are (Roact / React):
* `didMount` / `componentDidMount`
* `shouldUpdate` / `shouldComponentUpdate`
* `willUpdate` / `componentWillUpdate`
* `didUpdate` / `componentDidUpdate`
* `willUnmount` / `componentWillUnmount`

Additionally, existing Roact uses an `init` method to stand in for a class component constructor, since constructors are not a built-in concept in Lua. The `init` stand-in has already been implemented in roact-alignment.

#### In Production Code
All of our existing component in Lua Apps and beyond use the naming scheme without the `component` prefix. A refactor to change all the names would incur quite a lot of changes, and be very tedious to properly flag.

#### Proposed Alignment Strategy
There are a few clear options:
1. Refactor all Roact consuming code: find/replace instances of the old names with the upstream-aligned ones. This will create a _lot_ of changes, and poses difficulties if those changes are being flagged in tandem with an upgrade as flagging them all may be unreasonably messy.
2. Add deviations in the upstream code to support both sets of names. This may require some fairly surgical changes and could have some degree of performance cost.
3. Deviate wholly on these function names in the alignment effort, using Roact's established names. This creates a gap with React user expectations that we'll have to bridge carefully with documentation and possibly warnings (though, one could argue, option 1 causes the same problem with existing Roact users).

#### Implemented Alignment
An implementation of tactic #2 above was merged in [#88](https://github.com/Roblox/roact-alignment/pull/88). A `__newIndex` metamethod was added to the `React.component` table which catches method declarations using the older naming convention, warns about them and recommends updating the name (in DEV mode), then creates a method in the actual class table under the new API's equivalent name.
</details>

### Reserved Prop Keys: "ref"
**Status:** ✔️ Resolved (consumers updated to comply)

Upstream React reserves the prop key "ref". In Roact the "ref" key is replaced by a Symbol exported as part of the API and applied as a prop with the key `[Roact.Ref]`. This means that there's no need to reserve a key, because the key is already unique and has a special meaning.

In Roact, the equivalent key is also only meaningful on host components, leading to some deviations around [Ref Forwarding](#ref-forwarding).

#### Example
React (adapted from the documentation):
```js
class MyComponent extends React.Component {
  constructor(props) {
    super(props);
    this.myRef = React.createRef();
  }
  render() {
    return <div ref={this.myRef} />;
  }
}
```

Roact:
```lua
local MyComponent = React.Component:extend("MyComponent")

function MyComponent:init()
  self.myRef = Roact.createRef()
end

function MyComponent:render() {
  return React.createElement("Frame", {
    [Roact.Ref] = self.myRef,
  })
end
```

#### In Production Code
The special key `Roact.Ref` is used extensively in existing Lua Apps code, ~850 instances across ~400 files, including [its use for ref forwarding](#ref-forwarding).

#### Proposed Alignment Strategy
It's trivial to create a compatibility shim by exposing a `Roact.Ref` key whose value is simply the string "ref".

This would be blocked by refactors to remove any existing uses of the `ref` key, which are not accounting for its reserved status. A quick search suggests there are few instances of this (~20).

This alignment effort should be considered in tandem with that of [ref forwarding logic](#ref-forwarding).

### Reserved Prop Keys: "key"
**Status:** ✔️ Resolved (consumers updated to comply)

Upstream React reserves the prop key "key". In Roact, "key" has no special meaning.

In React (with the HTML DOM), the order of provided children is meaningful to the resulting layout of host components in the element tree. In Roblox, however, order does not have any relevance on its own.

Instead, Roact expects users to provide children as tables, using the keys in the table as stable keys for the elements. More detail in the [Stable Keys section](#stable-keys)

#### In Production Code
Nearly all Roact components defined in existing code bases rely on the table-keys-as-stable-keys approach.

There are ~10 components in the Lua Apps repo, including dependencies, that use "key", which will become reserved. These will need to be refactored if we keep the reserved key property.

#### Proposed Alignment Strategy
The obvious option is to adopt the reserved `key` prop. This means refactoring the components referred to above that rely on the reserved prop name to use a different name.

However, we may instead consider providing a `Roact.Key` symbol key that can be used for this purpose. This would incur deviations in the alignment repo.

For any approach to stable key assignment, we should additionally support Roact's approach. This alignment effort should be considered in tandem with that of [stable keys](#stable-keys)

### Reserved Prop Keys: "children"
**Status:** ✔️ Resolved (consumers updated to comply)
<details>
Upstream React [reserves the prop key "children"](https://reactjs.org/docs/glossary.html#propschildren). In Roact the "children" key is replaced by a Symbol exported as part of the API and applied as a prop with the key `[Roact.Children]`. This means that there's no need to reserve a key, because the key is already unique and has a special meaning.

In both upstream React and current Roact, `createElement` has an optional third argument for specifying children _separately_ from other props. This is used in the vast majority of cases for Roact code, is often made irrelevant by JSX (as is `createElement` altogether) in React code.

In some cases, however, Roact users may access `self.props[Roact.Children]` explicitly in order to pass children through. They may also define props using by providing the `[Roact.Children]` member of a props table, often when combining props from other sources but still passing through children. Roact will warn if children are provided in _both_ the props table and the optional third argument to `createElement`.

#### Example
React (adapted from the documentation):
```js
function Welcome(props) {
  return <p>{props.children}</p>;
}
```

Roact:
```lua
local function Welcome(props)
  return Roact.createElement("Frame", nil, props[Roact.Children]);
end
```

#### In Production Code
There are ~200 direct references to `Roact.Children` in the Lua Apps repo, including dependencies. These are typically specialized cases in which children are forwarded through a component.

Conversely, there are only a couple of uses of `children` as a key, which would need to be refactored to use a different name in order to adopt the upstream behavior.

#### Proposed Alignment Strategy
The most straightforward approach would be to export `Roact.Children` with a value equal to "children". We need to refactor the few cases of downstream code that use "children" currently.

#### Implemented Alignment
`Roact.Children` was exported with a value equal to `"children"` in the `roact-compat` package. We searched for instances of downstream code that uses `children` as a key but found none.

</details>

### Old Context (Roact only)
**Status:** ✔️ Resolved (consumers updated to comply)

In Roact, the "old" context behavior was a `_context` field defined on every class component instance. To provide context, a component would mutate its `_context` field in `init`:
```lua
function MyProvider:init()
  self._context.Theme = { --[[ some theme data ]] }
end
```
...and consumers would read from it, generally encapsulating any access of `_context` to discourage overusing an incomplete feature:
```lua
function MyConsumer:render()
  local theme = self._context.theme
  return props.render(theme)
end
```

This approach was never meant for widespread consumption and had a few serious downsides:
* Making changes to `self._context` would not cause consumers to update; any users of `_context` would have to rig up subscription logic manually
* Since the `_context` field can be mutated to provide context values to descendants, it needed to be defensively copied by all descendant class components
* Accessing context in function components was impossible without using a wrapper
* The Provider/Consumer component pattern used by `React.createContext` can be built on top of `_context`, but is not available by default and its semantics aren't enforced

React has a different "old" context that involves the static `contextTypes` field on class component definitions. Roact has no equivalent behavior. React and Roact both implement semantically equivalent "new" context APIs via `createContext`, so this behavior only affects older code.

#### In Production Code
An inventory of `_context` usage in the lua apps repo (including dependencies):
* **Simple Provider/Consumer pairs:** ~21
* **More complex use cases of `_context`:** ~5

Examples:
* [Localization (social)](https://github.com/Roblox/lua-apps/tree/master/content/LuaPackages/Localization) - Simple/idiomatic usage
* [RoactServices](https://github.com/Roblox/lua-apps/blob/master/src/internal/LuaApp/Modules/LuaApp/RoactServices.lua) - More complex example, but likely easy to rewrite with new context
* [Avatar Editor Theme](https://github.com/Roblox/lua-apps/blob/master/src/internal/LuaApp/Modules/LuaApp/Components/Avatar/AELoader.lua) - More complex example, likely more work to untangle

#### Proposed Alignment Strategy
We'll likely have to modernize all existing uses of `_context` to instead use the `createContext` API provided by the current version of Roact. This will be a blocker for adopting roact-alignment, which has a semantically equivalent API and should make for a smooth cut-over.

This is likely the biggest refactor effort that the Lua Apps adoption is contingent on. It also incurs some knock-on efforts on projects that the App depends upon, like [roact-rodux](https://github.com/roblox/roact-rodux/issues/26), which has some work completed, [but with unaddressed backwards compatibility problems](https://github.com/Roblox/roact-rodux/pull/38#issuecomment-644902307).

### Context.Consumer Interface
**Status:** ✔️ Resolved (backwards compatible with deprecation warnings)
<details>
  <summary>Details</summary>

The context consumer api doesn't match that of Roact's createContext context consumer.
* Roact's implementation accepts a single prop, which is a render functions `render(contextObject) -> ReactElement`
* React's implementation accepts no props, and a single child, which is a `render` function with the same signature as above

#### Implemented Alignment Strategy
We've provided support for both interfaces. Resolution and more info at https://github.com/Roblox/roact-alignment/pull/119
</details>

### validateProps
**Status:** ✔️ Resolved (backwards compatible)
<details>
#### Implemented Alignment
Roact 17 supports both validateProps. `checkPropTypes` method was expanded to include logic for validateProps. For full details, see [#131](https://github.com/Roblox/roact-alignment/pull/131).
</details>

### createFragment
**Status:** ✔️ Resolved (backwards compatible with deprecation warnings)
<details>
  <summary>Details</summary>

React allows a component to return multiple top-level elements as a special kind of component referred to as a "fragment", which will be siblings within the parent they're rendered into (more in the [React documentation](https://reactjs.org/docs/fragments.html)).

Roact similarly allows this, but since it expects those sibling elements to be in a particular format, and exposes an API called `Roact.createFragment` to allow this.

#### Example
React (adapted from the documentation):
```js
class Columns extends React.Component {
  render() {
    return (
      <>
        <td>Hello</td>
        <td>World</td>
      </>
    );
  }
}
```

Roact:
```lua
local Columns = React.Component:extend("Columns")

function Columns:render()
  return React.createFragment({
    React.createElement("TextLabel", {Text="Hello"}),
    React.createElement("TextLabel", {Text="World"}),
  })
end
```

#### In Production Code
There are ~140 usages of `createFragment` in the lua-app repo, dependencies included. In the roact-alignment repo, fragments translate to simple tables of elements (no special API needed).

#### Proposed Alignment Strategy
There are two readily apparent options:
1. Refactor Roact consumer code to replace all instances of `return Roact.createFragment({ ... })` with `return (React.Fragment, nil, { ... })` for the upgrade. This might be reasonable at the volume that it occurs, but if we flag the Roact upgrade, we'll need to flag these sites as well
2. Provide a `createFragment` function on the top-level API that looks something like this:
```lua
function createFragment(elements)
  return React.createElement(React.Fragment, elements)
end
```
This would be a simple compatibility layer that should require very little maintenance.

#### Implemented Alignment
The `createFragment` function described above was added to React.lua in [#92](https://github.com/Roblox/roact-alignment/pull/92/files).
</details>

### Ref Forwarding
**Status:** ✔️ Resolved (consumers updated to comply)

Ref forwarding is possible in React via the [`forwardRef` API](https://reactjs.org/docs/forwarding-refs.html).

In Roact, however, Refs only work properly on Host components to begin with. For this reason, naming a function or class component's prop `[Roact.Ref]` (the [ref keyword equivalent](#reserved-prop-keys-ref)) would cause it to behave like any old prop. It was possible to forward refs from a class or function component by accepting a ref via the typical ref prop, and pass it on to an underlying host component.

However, this behavior was contingent on refs to class components (and function components) _not_ working the way they do in React. There was no mechanism at all to get a ref to the component instance of a class component.

Because of this, a number of use cases in which Roact code forwards refs relies on the special `[Roact.Ref]` key being _ignored, but passed along_ for function and class components. This may be one of the more difficult compatibility concerns.

#### Example
React (adapted from the documentation):
```js
const FancyButton = React.forwardRef((props, ref) => (
  <button ref={ref} className="FancyButton">
    {props.children}
  </button>
));

// You can now get a ref directly to the DOM button:
const ref = React.createRef();
<FancyButton ref={ref}>Click me!</FancyButton>;
```

Roact:
```lua
local function FancyButton(props)
  return React.createElement("TextButton", {
    Text = props.text,
    -- Ad-hoc forwarding performed by passing along the `Roact.Ref` prop, which
    -- Roact does treats like any old prop.
    [Roact.Ref] = props[Roact.Ref],
  }, props.children)
end

-- You can now get a ref directly to the DOM button:
local ref = React.createRef();
local element = React.createElement(FancyButton, {[Roact.Ref]=ref, text="Click me!"})
```

#### In Production Code
There are ~140 instances of ref forwarding via `[Roact.Ref]` in the Lua Apps repo, including dependencies. Many of these are easily replaceable with `forwardRef` logic, but a few use cases are doing something more complicated with any refs that are passed into them.

#### Proposed Alignment Strategies
Alternative 1: Align to `ref`, allow `Roact.Ref` on host components for compatibility
1. Refactor any existing code that uses `ref`, which will not be expecting it to be a reserved key
2. Continue treating the `Roact.Ref` key as a special case for host components, and any other prop for non-host components
3. Treat `ref` as a reserved key and apply all upstream behavior around it; this means that the only deviation from upstream is that, on host components, a special `Roact.Ref` symbol key can optionally be used instead of `ref`, which we can deprecate in the future

Alternative 2: Align to `Roact.Ref`, which deviates slightly from upstream but does not add any duplicate behavior
1. Create a `forwardRef` utility built for existing Roact
2. Refactor any existing code that forwards refs through `[Roact.Ref]` to instead use the `forwardRef` utility
3. Implement refs in roact-alignment in terms of the key `[Roact.Ref]` _instead of_ using the reserved `ref` keyword. This is an API deviation from upstream, so it requires user-facing documentation.

### Stable Keys
**Status:** ✔️ Resolved (backwards compatible)
<details>
  <summary>Details</summary>

In React, the [reserved "key" prop](#reserved-prop-keys-key) is used to provide stable identities to DOM elements. This provides better performance when list-like data is reordered; React knows to move identified elements instead of simply changing the props of each element at each position to line up with the new ordering (more info in the [React documentation](https://reactjs.org/docs/lists-and-keys.html)).

Since order has no inherent meaning in Roblox's DOM, Roact generally expects children to be provided as a map, where the keys to the map are the stable keys associated with the elements. This behavior is used instead of a reserved "key" prop (more info in the [Roact documentation](https://roblox.github.io/roact/performance/reduce-reconciliation/#stable-keys)).

#### Example
React (adapted from the React documentation):
```jsx
function NumberList(props) {
  const numbers = props.numbers;
  const listItems = numbers.map((number) =>
    // The number is stringified into a stable key associated with the
    // equivalently-numbered element
    <li key={number.toString()}>
      {number}
    </li>
  );
  for (number in numbers) {
    listItems.append((
      <li key={number.toString()}>
        {number}
      </li>
    ));
  }
  return (
    <ul>{listItems}</ul>
  );
}
```

Roact:
```lua
function NumberList(props)
  local numbers = props.numbers;
  local listItems = {
    -- In Roblox, a UIListLayout establishes ordering and layout rules for
    -- its sibling elements
    ListLayout = Roact.createElement("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder})
  }
  for i, number in numbers do
    -- Here, the key in the list (`i`) is the key associated with the
    -- equivalently-numbered element. It can be any kind of value.
    listItems[i] = Roact.createElement("TextLabel", {
      Text = tostring(number),
      -- In Roblox, LayoutOrder must be specified, since an ordered list
      -- of elements has no guaranteed ordering in the dom
      LayoutOrder = i,
    })
  end);
  return Roact.createElement("Frame", nil, listItems)
end
```

#### Proposed Alignment Strategy
We should support Roact's approach to stable keys in addition to supporting the [reserved key prop](#reserved-props-keys-key) of interpreting table keys in child tables as stable keys for those elements.

Any time children are provided as a table (including mixed tables or sparse arrays), the table keys assigned to the elements should be assigned back onto them and interpreted as their `key` prop.

In the event that both a table key and the `key` prop are provided to the same element, we should through a warning in DEV mode that aligns with similar warnings for un-keyed children.

An implementation of this approach was merged in [#68](https://github.com/Roblox/roact-alignment/pull/68).
</details>

### Child Array Default Keys
**Status:** ✔️ Resolved (backwards compatible)
<details>
<summary>Details</summary>
In React 17, keys are not applied to children in an array. However, Legacy Roact automatically set a child's key in an array of children to that child's index in the array. Some downstream behavior relies on this legacy roact behavior, so Roact 17 automatically applies a child's index as its stable key if it is in an array and not passed a key prop.


#### Example
React:
```jsx
function ChildrenArrayComponent(props) {
  // The children of div are not given keys. Order is preservered inherently in the DOM.
  return (
    <div>
      <foo />
      <foo />
      <bar />
    </div>
  )
}
```

Roact 17:
```lua
function ChildrenArrayComponent(props)
  return Roact.createElement("Frame", nil, {
    -- These children receive keys 1, 2, and 3, respectively
    Roact.createElement(Foo),
    Roact.createElement(Foo),
    Roact.createElement(Bar),
  })
end
```

Equivalent Roact 17 with Lua Table Keys:
```lua
function ChildrenArrayComponent(props)
  return Roact.createElement("Frame", nil, {
    -- These children receive keys 1, 2, and 3, respectively
    [1] = Roact.createElement(Foo),
    [2] = Roact.createElement(Foo),
    [3] = Roact.createElement(Bar),
  })
end
```

Equivalent Roact 17 with prop keys:
```lua
function ChildrenArrayComponent(props)
  return Roact.createElement("Frame", nil, {
    -- These children receive keys 1, 2, and 3, respectively
    Roact.createElement(Foo, { key = 1 }),
    Roact.createElement(Foo, { key = 2 }),
    Roact.createElement(Bar, { key = 3 }),
  })
end
```

#### Proposed Alignment Strategy
This change is fully backwards compatible with Legacy Roact. However, users should be wary of elements potentially re-mounting on render when children are not given keys. This case can occur when a user switches from rendering multiple child elements in an array to rendering a single child element. Re-mounting is inefficient in comparison to updating an element on render. To avoid this case, a single child element should be given a key. The particular case is shown below:

Re-mounting Case (inefficient):
```lua
local root = Roact.createLegacyRoot(container)

-- Initial Render
root.render(Roact.createElement(Foo, nil, {
  Roact.createElement(Bar),
  Roact.createElement(Bar),
  Roact.createElement(FooBar),
}))

-- Re-Render
-- Bar will be remounted here. Roact 17 cannot discern if this is
-- the same Bar as above, so it remounts it.
root.render(Roact.createElement(Foo, nil, Roact.createElement(Bar)))
```

Update Case (efficient):
```lua
local root = Roact.createLegacyRoot(container)

-- Initial Render
-- Keys are not necessary here, they are applied by default
-- as { 1 = Bar, 2 = Bar, 3 = FooBar }
root.render(Roact.createElement(Foo, nil, {
  Roact.createElement(Bar),
  Roact.createElement(Bar),
  Roact.createElement(FooBar),
}))

-- Re-Render
-- Bar will be updated here, as the key allows Roact 17 to match
-- this Bar to the first Bar above. If we instead set key to 2, it
-- would match the second Bar above
root.render(Roact.createElement(Foo, nil,
  Roact.createElement(Bar, { key = 1 })
))
```
</details>

### Use of setState
**Status:** ✔️ Resolved (aligned to legacy Roact)
<details>
  <summary>Details</summary>

In React, `setState` is not allowed inside a constructor. Instead, it is recommended to assign directly to `this.state` (more info in the [React documentation](https://reactjs.org/docs/react-component.html#constructor))

Roact allows the use of `setState` in `init`, which is its equivalent to a class component constructor. In Roact, calling setState was deemed to be slightly more correct, since it would interact correctly with `getDerivedStateFromProps`. Roact also allows `self.state` to be assigned in `init` for backwards compatibility.

Our thinking with this was that "never assign directly to `self.state`" would be a better, clearer guideline than "never assign directly to `self.state` except in this one case"; allowing `setState` in `init`, and making it semantically equivalent to state initialization in React, was a step in that direction.

#### Example
React (adapted from the React documentation):
```js
constructor(props) {
  super(props);
  // Don't call this.setState() here!
  this.state = { counter: 0 };
}
```

Roact:
```lua
function MyComponent:init(props)
  -- setState is preferred over `self.state =`, so that we can be consistent
  -- about our "don't assign to state" rule
  self:setState({counter = 0})
end
```

#### In Production Code
It's difficult to measure this without relying heavily on formatting, but it seems that ~90 component definitions in the Lua App repo, including dependencies, invoke `setState` inside of their `init` functions (equivalent to a class component constructor).

#### Implemented Alignment Strategy
We continue to support calling `setState` in init, and ensure that its behavior is equivalent to assigning directly to state.

This maximizes compatibility with existing Roact code, and does not risk incurring significant tech debt, as we anticipate that class components will become less ubiquitous as hooks begin to see adoption.

Resolution and more info at https://github.com/Roblox/roact-alignment/pull/124
</details>

### Functional setState
**Status:** ✔️ Resolved (aligned to legacy Roact)

In both React and Roact, `setState` can accept a function as its argument in place of a table (with async rendering, this is encouraged as the default choice). In React, however, the argument passed to `setState` is invoked via `payload.call(instance, prevState, nextProps)`. In other words, React calls the function in such a way that the `instance` is in scope as `this` in the body of the updater function.

Roact, however, effectively calls the function as `payload(prevState, nextProps)` which does not provide access to `self`. Currently, in roact-alignment, we inherit the upstream behavior as closely as possible and call: `payload(instance, prevState, nextProps)`, which creates an incompatibility. Since the `prevState` and `nextProps` arguments shift over one space, existing uses of functional `setState` will run into trouble.

#### Example
React (adapted from the React documentation):
```js
this.setState((state, props) => {
  // `this` is implicitly accessible in this function body due to the calling
  // syntax in React internals
  return {counter: state.counter + props.step + this.CONSTANT};
});
```

Roact (today):
```lua
self:setState(function(state, props)
  -- `self` is not in function scope (though it _can_ be closed over from
  -- outside of the function scope)
  return {counter = state.counter + props.step + self.CONSTANT}
end)
```

To make our Roact code compatible with the new behavior, we'd need to write:
```lua
self:setState(function(self, state, props)
  return {counter = state.counter + props.step + self.CONSTANT}
end)
```

#### In Production Code
There are ~12 usages of functional setState in lua-apps and its dependencies, so it might be viable to change them.

#### Proposed Alignment Strategy
There does not appear to be any explicit need in any tests to rely on this behavior. The update function passed to setState can, in most scenarios, easily close over `self` if it needs to. The best approach is to simply change the call site in this repo from:
```
payload(instance, prevState, nextProps)
```
to
```
payload(prevState, nextProps)
```

Alternatively, we might consider:
* Align all existing usages, modifying them to accept `self` as their first argument. While this seems reasonable on the surface, there are serious caveats. Since lua and js have different mechanisms of defining and calling methods with `self`, the exact _behavior_ will be more similar to upstream, but the _API_ will deviate and need to be called out in documentation. We'd likely also want to add additional warnings to detect expected misuses.
* Perform some trickery with `setfenv` to allow the arguments to be in the same place, but `self` to be accessible. This is ugly, because it won't be understood by linting and I don't actually know how it will interact with shadowing/closures. As far as I'm concerned, this is a non-option, but it's worth calling out for thoroughness.

#### Implemented Alignment Strategy
We opted to align to legacy roact in our code to reduce impact on adoption. There remains no known use case for explicit injection of `self`, especially when closing over `self` is trivial.

This strategy was implemented in https://github.com/Roblox/roact-alignment/pull/160

### Roact.Portal
**Status:** ✔️ Resolved (backwards compatible with deprecation warnings)
<details>
  <summary>Details</summary>

In Roact, `Portal` is [a special, pre-defined component](https://roblox.github.io/roact/advanced/portals/) that accepts:
* A `target` prop, which is the roblox instance container under which to mount the portal contents
* The standard `[Roact.Children]` prop

In React, the dom renderer exports [a function](https://reactjs.org/docs/portals.html) instead:
```
ReactDOM.createPortal(children, container)
```

While the shape of the API differs, the semantics are identical.

#### Example
React (adapted from the React documentation):
```js
render() {
  // React does *not* create a new div. It renders the children into `domNode`.
  // `domNode` is any valid DOM node, regardless of its location in the DOM.
  return ReactDOM.createPortal(
    this.props.children,
    domNode
  );
}
```

Roact:
```lua
function MyComponent:render()
  -- Roact does *not* create a new Roblox Instance. It renders the children into `instance`.
  -- `instance` is any valid Roblox Instance, regardless of its location in the DataModel.
  return Roact.createElement(Roact.Portal, {
    target = instance,
  }, self.props[Roact.Children])
end
```

#### In Production Code
There are ~40 uses of `Roact.Portal` in the lua app and its dependencies. Many of these are in stories and not production code.

#### Proposed Alignment Strategy
We should create a special component called `Portal`, expose it via our compatibility package, and implement it as a simple function component that unwraps its props and injects them into `createPortal`.
</details>

### State Initialization
**Status:**  Alignment Strategy TBD

In Roact, ["stateful" components](https://roblox.github.io/roact/guide/state-and-lifecycle/) (equivalent of React's "class" components) will automatically initialize their state value to an empty table if it is not assigned via `init` or `getDerivedStateFromProps`.

In React's ["class" components](https://reactjs.org/docs/state-and-lifecycle.html#adding-local-state-to-a-class), state will never be initialized automatically. Any use of `this.state` without a prior assignment to state in the constructor results in an error at runtime.

#### Example
React (adapted from the React documentation):
```js
class ShowCount extends React.Component {
  constructor(props) {
    super(props);
    // this.state = {count: 0};
  }

  render() {
    return (
      // Throws an error:
      // Uncaught TypeError: Cannot read property 'count' of null
      <div>${this.state.count}</div>
    );
  }
}
```

Roact:
```lua
local ShowCount = Roact.Component:extend("ShowCount")
function ShowCount:init()
  -- self.state = {count=0}
end

function ShowCount:render()
  return Roact.createElement("TextLabel", {
    -- `self.state` is an empty table, and `self.state.count` is nil.
    -- Text will be left as its default value for a TextLabel
    Text = self.state.count,
  })
end
```

#### In Production Code
It's difficult to find where this is relied upon in production!

#### Alignment Strategy
Accessing uninitialized state may not be strictly wrong, but it is still a code smell. To encourage proper state initialization, we introduced a compoatibility layer: a singleton `UninitializedState` sentinel object that provides a useful error when accessed in dev mode, and should work just like an empty table in non-dev. 

The solution was implemented here: https://github.com/Roblox/roact-alignment/pull/155

### Functional setState Signature
**Status:** ✔️ Resolved (minor deviation from upstream)
<details>

In both [React](https://reactjs.org/docs/react-component.html#setstate) and [Roact](https://roblox.github.io/roact/api-reference/#setstate), class components can call `setState` with a function instead of a partial state table. When state updates rely on previous state, this can make them more resilient to multiple queued updates. This approach is favored by upstream documentation for this reason, and encouraged in Roact's documentation as well (in anticipation of async rendering).

In React, the updater function is called with `this` in scope, using JavaScript's `bind` function. This poses a problem for the translation: if we want to align this behavior, we need to change the signature of the state updater from `(state, props) -> partialState` to `(self, state, props) -> partialState`. This would be a backwards-incompatible change

#### Example
React (adapted from the React documentation):
```js
this.setState((state, props) => {
  // `this` is in scope here and can be read from
  return {counter: state.counter + props.step};
});
```

Roact:
```lua
self:setState(function(state, props)
  -- `self` is NOT in scope here
  return { counter = state.counter + props.step }
end);
```

#### In Production Code
This functionality is used relatively sparingly in the lua-apps code base (including dependencies), only ~15 confirmed usages and ~45 more possible ones (more investigation needed to confirm).

#### Proposed Alignment Strategy
While it's possible to adapt to the upstream behavior, I was not able to find _any_ idiomatic usages of `this` in the body of a `setState` updater function. We should keep Roact's current behavior, which encourages function purity and serves all known use cases without issue.
</details>

# Unique Features
Roact has a couple of unique features that are not present in upstream, while a number of new features from upstream will be introduced by the alignment effort.

## Roact

### Bindings
Roact provides [an API for unidirectional bindings](https://roblox.github.io/roact/api-reference/#roactcreatebinding), which expand on the capabilities provided by refs and provide a safer, more streamlined way to solve problems that are traditionally solved via refs. Roact's documentation also has a [more detailed section](https://roblox.github.io/roact/advanced/bindings-and-refs/).

### oneChild
A now-obsolete API that will thrown an error when passing a table with more than one child. This was useful before fragments were implemented, particularly when implementing context providers that were meant to have children passed in (but could only render one child without fragment support). More info in [the documentation](https://roblox.github.io/roact/api-reference/#roactonechild).

## Upstream React
Upstream React introduces a number of incoming features. Some of these are already ported or in the process of being ported.

_(section needs filling in...)_

### Hooks
[React Hooks](https://reactjs.org/docs/hooks-intro.html)

Most hooks are ported and exposed (a few experimental and in-development ones are not yet available): https://github.com/Roblox/roact-alignment/blob/v17.0.1-preview.0/modules/react/src/React.lua#L35-L45

### Memo
[React Memo](https://reactjs.org/docs/react-api.html#reactmemo)

Memo is ported and exposed via `React.memo`.

### Lazy
[React Lazy](https://reactjs.org/docs/code-splitting.html#reactlazy)

Lazy is ported and exposed via `React.lazy`.

### Suspense
[React Suspense](https://reactjs.org/docs/react-api.html#reactsuspense)

Suspense is ported and exposed via `React.Suspense`.

### Error Boundaries
[React Error Boundaries](https://reactjs.org/docs/error-boundaries.html)

Error boundaries are ported and exposed via the component lifecycle methods `getDerivedStateFromError` and `componentDidCatch`.

### DEV mode
DEV Mode can be enabled by setting the `__DEV__` global to `true` before the initial require of any Roact package. You can accomplish this either by:
* In Roblox Studio, executing `_G.__DEV__ = true` at the entry point of your test or application (before requiring any React packages)
* In roblox-cli, including the argument `--lua.globals=__DEV__=true` when using the `run` command
* If `__COMPAT_WARNINGS__` is set, it will output Legacy Roact compatibility layer warnings, which will help teams write code that will be forward compatible at the next major version update to Roact.
