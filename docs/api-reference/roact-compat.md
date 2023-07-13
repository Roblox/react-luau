# RoactCompat

The `RoactCompat` package is designed to have the same interface as [legacy Roact](https://roblox.github.io/roact/api-reference/). This should allow easier adoption of Roact 17 in existing Roact code.

`RoactCompat` is fully compatible with all Roact 17 logic. In particular, you may wish to use `RoactCompat` in combination with the [`React`](react.md#react) and [`ReactRoblox`](react-roblox.md#reactroblox) packages that provide the new interface.

!!! caution
	`RoactCompat` is **not** compatible with legacy Roact in any way. It should be used only as a drop-in replacement for legacy Roact, for the purposes of upgrading existing projects written for legacy Roact.

## RoactCompat.Component
Re-exports [React.Component](react.md#ReactComponent).

## RoactCompat.PureComponent
Re-exports [React.PureComponent](react.md#ReactPureComponent).

## RoactCompat.createElement
Re-exports [React.createElement](react.md#ReactcreateElement).

## RoactCompat.createContext
Re-exports [React.createContext](react.md#ReactcreateContext).

## RoactCompat.createRef
Re-exports [React.createRef](react.md#ReactcreateRef).

## RoactCompat.forwardRef
Re-exports [React.forwardRef](react.md#ReactforwardRef).

## RoactCompat.mount

```
RoactCompat.mount(
	element: ReactElement,
	container: Instance?,
	name: string?
): RoactTree
```
Compatibility method mimicking [legacy `Roact.mount`](https://roblox.github.io/roact/api-reference/#roactmount).

For all intents and purposes, this should function equivalently to legacy Roact's `mount` function. Under the hood, RoactCompat takes the following steps:

1. Creates a root using [`React.createRoot`](react.md#reactcreateroot)
	* When `_G.__ROACT_17_COMPAT_LEGACY_ROOT__` is enabled, this will use [`React.createLegacyRoot`](react.md#reactcreatelegacyroot) instead
2. Calls `root:render` with the provided element
	* React's roots take complete control of the provided container, deleting all existing children. Legacy Roact does not tamper with existing children of the provided container. To mimic the legacy behavior, we use a [`Portal`](react.md#reactcreateportal) to mount into the container instead of providing it directly to the root.
	* When `_G.__ROACT_17_INLINE_ACT__` is enabled, the `render` call is automatically wrapped in [`ReactRoblox.act`](react-roblox.md#reactrobloxact) to ensure that mounting behavior resolves synchronously in tests.
3. Returns an opaque handle to the root that can be used with [`RoactCompat.update`](#roactcompatupdate) and [`RoactCompat.unmount`](#roactcompatunmount)

## RoactCompat.update

```
RoactCompat.update(tree: RoactTree, element: ReactElement): RoactTree
```
Compatibility method mimicking [legacy `Roact.update`](https://roblox.github.io/roact/api-reference/#roactupdate).

The first argument should be the value returned from a prior call to [`RoactCompat.mount`](#roactcompatmount) or `RoactCompat.update`. This function will not work if the argument passed in was created with legacy Roact.

## RoactCompat.unmount

```
RoactCompat.unmount(tree: RoactTreeHandle)
```
Compatibility method mimicking [legacy `Roact.unmount`](https://roblox.github.io/roact/api-reference/#roactunmount).

-- API compatibility layers to accommodate old interfaces
## RoactCompat.createFragment

```
RoactCompat.createFragment(elements: { [string | number]: ReactElement }): ReactElement
```
Compatibility method mimicking [`Roact.createFragment`](https://roblox.github.io/roact/api-reference/#roactcreatefragment). Uses the special component [`React.Fragment`](react.md#reactfragment) under the hood.

## RoactCompat.oneChild

```
RoactCompat.oneChild(
	children: { [string | number]: ReactElement } | ReactElement | nil
): ReactElement
```
Compatibility method mimicking [`Roact.oneChild`](https://roblox.github.io/roact/api-reference/#roactonechild). This function is similar to [`React.Children.only`](react.md#reactchildrenonly), but provides additional functionality to unwrap a table that may contain a single element.

## RoactCompat.setGlobalConfig

```
RoactCompat.setGlobalConfig(configValues: { [string]: boolean })
```
Compatibility method mimicking [`Roact.setGlobalConfig`](https://roblox.github.io/roact/api-reference/#roactsetglobalconfig). **This does not apply to Roact 17, so calling this function is a no-op.**

!!! info
	If you need to apply global configuration to Roact 17, you can do so by setting global values [FIXME LINK TO CONFIGURATION DOC](../configuration.md)

## RoactCompat.Portal

Compatibility component mimicking [`Roact.Portal`](https://roblox.github.io/roact/api-reference/#roactportal). Uses the [React.createPortal](react.md#reactcreateportal) function under the hood.

## RoactCompat.Ref

Compatibility field that mimics the special symbol key [`Roact.Ref`](https://roblox.github.io/roact/api-reference/#roactref). In RoactCompat, the `Ref` field is simply equal to the string "ref", which is a reserved prop key in Roact 17.

This allows prop tables that are written for legacy Roact:
```lua
Roact.createElement("TextLabel", {
	Text = "Hello",
	[Roact.Ref] = textLabelRef,
})
```
...to be equivalent to prop tables written for Roact 17, which uses "ref" as a reserved prop name:
```lua
Roact.createElement("TextLabel", {
	Text = "Hello",
	ref = textLabelRef,
})
```

## RoactCompat.Children

Compatibility field that mimics the special symbol key [`Roact.Children`](https://roblox.github.io/roact/api-reference/#roactchildren). In RoactCompat, the `Children` field is simply equal to the string "children", which is a reserved prop key in Roact 17.

This allows prop tables that are written for legacy Roact:
```lua
-- forwards the children provided to this component
Roact.createElement("Frame", nil, self.props[Roact.Children])
```
...to be equivalent to prop tables written for Roact 17, which uses "children" as a reserved prop name:
```lua
-- forwards the children provided to this component
Roact.createElement("Frame", nil, self.props.children)
```

!!! caution
	This is not to be confused with [`React.Children`](react.md#reactchildren), which is a set of utilities for transforming or interacting with sets of children passed to `createElement`.

## RoactCompat.None

Re-exports [React.None](react.md#reactnone).

## RoactCompat.Event

Re-exports [React.Event](react.md#reactrobloxevent).

## RoactCompat.Change

Re-exports [React.Change](react.md#reactrobloxchange).

## RoactCompat.createBinding
Re-exports [ReactRoblox.createBinding](react.md#reactcreatebinding).

## RoactCompat.joinBindings
Re-exports [ReactRoblox.joinBindings](react.md#reactjoinbindings).

## RoactCompat.act
Re-exports [ReactRoblox.act](react-roblox.md#reactrobloxact).
