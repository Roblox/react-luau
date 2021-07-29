# Deviations
**This is a work in progress! Most of these notes are old!**

The Roact alignment effort aims to map as closely to React's API as possible, but there are a few places where language deviations require us to omit functionality or deviate our approach.

## Class Components
Lua does not have ES6's `class` semantics. For class components, Roact will expose `Component:extend(name: string) -> Component` to bridge this gap. Equivalently, `PureComponent:extend` is used to define PureComponents.

### Constructors
Because of the lack of class semantics, there are also no inheritable constructors; instead, Roact provides a lifecycle method called `init` that takes the place of the constructor, running immediately after an instance is created for that class.

For all intents and purposes, this should function exactly like a constructor for a class component in React, except that there is no need to call `super`.

## Function Components
JavaScript Functions are also objects, which means that they can have member fields defined on them. Lua/Luau does not allow this.

### defaultProps
For the time being, function components do not support the `defaultProps` feature. In the future, we may want to re-implement it in terms of hooks to make sure that function components with hooks are as appealing and feature-rich as possible.

### propTypes
For the time being, function components do not support the `propTypes` feature. While propTypes is less often used and can in many cases be superseded by static type checking, we may want to, in the future, re-implement it in terms of hooks to make sure that function components with hooks are as appealing and feature-rich as possible.

### validateProps
For the time being, we will continue to support legacy Roact's `validateProps`. Old Roact's documentation on this method can be found [here](https://roblox.github.io/roact/api-reference/#validateprops).

### contextTypes
For the time being, function components do not support the `contextTypes` feature. While contextTypes is less often used and can in many cases be superseded by static type checking, we may want to, in the future, re-implement it in terms of hooks to make sure that function components with hooks are as appealing and feature-rich as possible.

## Bindings and Refs
Roact supports function refs, refs created using `React.createRef`, and refs using the `React.useRef` hook. However, under the hood, Refs are built on top of a concept called Bindings.

### Bindings
Roact introduces a bindings feature that provides a unidirectional data binding that can be updated outside of the render cycle (much like refs could).

For now, bindings are documented in more detail [here](https://roblox.github.io/roact/advanced/bindings-and-refs/#bindings).

### Host Properties with Instance Values
The Roblox API exposes certain host properties that must be assigned _Instance references_ as values. Effectively, there are native APIs that expect a `ref.current` value as a value.

The logic of bindings is a perfect fit for this scenario. Consider the following example:
```lua
local PopupButtons = Roact.Component:extend("PopupButtons")
function PopupButtons:init()
	self.confirmRef = Roact.createRef()
	self.cancelRef = Roact.createRef()
end
function PopupButtons:render()
	--[[
			"Some Description"
		
		[ Confirm ]    [ Cancel ]
	]]
	return Roact.createElement("Frame", nil {
		ConfirmButton = Roact.createElement("TextButton", {
			[Roact.Ref] = self.confirmRef,
			Text = "Confirm",
			NextSelectionRight = self.cancelRef.value,
		}),
		CancelButton = Roact.createElement("TextButton", {
			[Roact.Ref] = self.cancelRef,
			Text = "Confirm",
			NextSelectionLeft = self.confirmRef.value,
		}),
	})
end
```
This example poses a problem. Since children will be rendered in an arbitrary order, one of the following will happen:
1. Confirm Button renders first and its ref is assigned
2. Confirm Button's NextSelectionRight property is set to the Cancel Button's ref, **which is currently nil**
3. Cancel Button renders and its ref is assigned
4. Cancel Button's NextSelectionLeft property is properly set to the Confirm Button's ref

Or:
1. Cancel Button renders first and its ref is assigned
2. Cancel Button's NextSelectionLeft property is set to the Confirm Button's ref, **which is currently nil**
3. Confirm Button renders and its ref is assigned
4. Confirm Button's NextSelectionRight property is properly set to the Cancel Button's ref

Thus, it would require much more trickery to make even a simple gamepad neighbor assignment work correctly. However *when refs are implemented as bindings*, the above scenario can be solved pretty simply:
```lua
-- ...
	return Roact.createElement("Frame", nil {
		ConfirmButton = Roact.createElement("TextButton", {
			[Roact.Ref] = self.confirmRef,
			Text = "Confirm",
			-- pass the ref itself, which is a binding
			NextSelectionRight = self.cancelRef,
		}),
		CancelButton = Roact.createElement("TextButton", {
			[Roact.Ref] = self.cancelRef,
			Text = "Confirm",
			-- pass the ref itself, which is a binding
			NextSelectionLeft = self.confirmRef,
		}),
	})
-- ...
```
With refs using binding logic, and with the above implementation, something like the following happens
1. Confirm Button renders first and its ref is assigned
2. Confirm Button's NextSelectionRight property is set to the Cancel Button's ref, **which is currently nil**
3. Cancel Button renders and its ref is assigned
	* The binding value updates, and the Confirm button's NextSelectionRight property is assigned to the Cancel Button's new ref value
4. Cancel Button's NextSelectionLeft property is properly set to the Confirm Button's ref

...or the inverse, with the Cancel Button rendering first. Either way, both refs are assigned, and both neighbor properties are assigned by the time the render is complete.