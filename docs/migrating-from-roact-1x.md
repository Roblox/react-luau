# Migrating From Roact 1.x


## Minimum Requirements

When upgrading to Roact 17+, uses of certain legacy patterns and features need to be cleaned up entirely to maintain correct behavior. Once these conditions are met, your legacy Roact code should work as expected in Roact 17.

### No Reserved Props

In Roact 17, components cannot rely on any reserved prop keywords:

* "ref" - reserved by Roact to assign refs, equivalent to legacy Roact's `Roact.Ref`
* "key" - reserved by Roact to assign stable keys to children
* "children" - reserved by Roact as a special prop representing the children passed down to the component

If your component is using "ref" or "key" as the name of one of its props, it will no longer be populated with a value in Roact 17+. If it's using "children" as the name of one of its props, it will be populated with the table of child elements instead of any passed-in value.

### No Legacy Context

Legacy Roact implemented a `_context` field on all component instances as an alternative implementation for the Context feature. This is deprecated in legacy Roact and is not supported in Roact 17+.

Instead, use the [Provider and Consumer pattern via `createContext`](https://roblox.github.io/roact/advanced/context/). The `createContext` API is available in legacy Roact 1.3.0 (or newer) and is fully supported in Roact 17.

### Explicit Ref Forwarding

Legacy Roact uses `Roact.Ref` as a special prop key to support the refs feature. Assigning the `[Roact.Ref]` property to a callback ref or ref object allows Roact to assign its value. However, Roact only interacts with the `Roact.Ref` property if the component receiving the props is a host component.

Some class component definitions rely on this behavior by accepting and reassigning the `[Roact.Ref]` prop themselves, knowing that Roact won't capture it. This pattern is called "ref forwarding", and is supported explicitly with the `React.forwardRef` API.

In Roact 17+, `Roact.Ref` is aliased to the string "ref", and refs that point to class components are now supported. Components that were forwarding refs using the above method will now fail to forward their provided refs. To fix this, use the [`forwardRef` function](https://roblox.github.io/roact/advanced/bindings-and-refs/#ref-forwarding).

The `forwardRef` API is available in legacy Roact 1.4.0 (or newer) and is fully supported in Roact 17.

### Prefer getDerivedStateFromProps
Legacy Roact allows class components to implement both `willUpdate` and `getDerivedStateFromProps` lifecycle methods.

React JS, however, does not support both methods when implemented on the same component. When `getDerivedStateFromProps` is defined, it _replaces_ `componentWillUpdate` entirely. **Roact 17 inherits this restriction.**

In order to migrate existing components, make sure to use _either_ `willUpdate` or `getDerivedStateFromProps`, but not both. Whenever possible, use `getDerivedStateFromProps` to resolve interactions between state and props. As in React JS, `componentWillUpdate` is a legacy lifecycle method and should be avoided as [it can exacerbate problems with asynchronous rendering.

Refer to the React JS guidance on [migrating away from legacy lifecycle methods](https://reactjs.org/blog/2018/03/27/update-on-async-rendering.html).

## Adding a Roact 17 Dependency
*Under constructions 🔨*

### Testing with Both

### Replacing Legacy Roact

## Adopting New Rendering Behavior
*Under constructions 🔨*

In addition to newly added APIs, Roact 17 also includes changes to the underlying rendering behavior.

### ReactRoblox.createRoot

### ReactRoblox.act


## Configuration
*Under constructions 🔨*

### Globals

## Updating Conventions and APIs
*Under constructions 🔨*

While not necessary to function properly, some additional changes can be made to adopt the naming conventions and API shape of React JS.

### Component Lifecycle Names

### Context.Consumer

### Fragments

#### Implicit Fragments

#### React.Fragment


### ReactRoblox.createPortal

### Eliminating RoactCompat
