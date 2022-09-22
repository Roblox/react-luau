# Minimum Requirements

When upgrading to Roact 17+, a small set of legacy patterns and features need to be fixed in order to maintain intended behavior. Once these conditions are met, your legacy Roact code should work as expected in Roact 17.

**All of these requirements can be met using APIs available in legacy Roact**, though most will require a minimum version. This means that a Roact codebase can safely be made _compatible_ with Roact 17 as a preliminary step before adopting it.

## No Reserved Props

In Roact 17, components cannot rely on any reserved prop keywords:

* "ref" - reserved by Roact to assign refs, equivalent to legacy Roact's `Roact.Ref`
* "key" - reserved by Roact to assign stable keys to children
* "children" - reserved by Roact as a special prop representing the children passed down to the component

If your component is using "ref" or "key" as the name of one of its props, **those props will no longer be populated with a value in Roact 17+.**

Additionally, if it's using "children" as the name of one of its props, **the value of the "children" prop will become the table of child elements instead of the value provided by the parent component in Roact 17+.**

!!! info
	This restriction does not involve legacy APIs, so this migration can be completed in codebases depending upon **any version** of legacy Roact.

### Example

Suppose we have a component `OptionButton` and a separate component `ButtonGroup` that uses it.

The `OptionButton` component is using a prop called `key` to pass through to its LayoutOrder. In Roact 17, this prop will be nil because it will be consumed by Roact and used as a [stable key](https://reactjs.org/docs/lists-and-keys.html#keys).

To fix this, we replace the use of the `key` prop with a prop with a different name.

#### Legacy
```lua
local function OptionButton(props)
	return Roact.createElement("TextButton", {
		LayoutOrder = props.key,
		Text = props.text,
		[Roact.Event.Activated] = props.onClick,
	})
end

local function ButtonGroup(props)
	return Roact.createFragment({
		CancelButton = Roact.createElement(OptionButton, {
			key = 1,
			text = "Cancel",
			onClick = props.cancelCallback,
		})
		ConfirmButton = Roact.createElement(OptionButton, {
			key = 2,
			text = "Confirm",
			onClick = props.confirmCallback,
		})
	})
end
```

#### Roact 17 Compatible
```lua hl_lines="3 12 17"
local function OptionButton(props)
	return Roact.createElement("TextButton", {
		LayoutOrder = props.order,
		Text = props.text,
		[Roact.Event.Activated] = props.onClick,
	})
end

local function ButtonGroup(props)
	return Roact.createFragment({
		CancelButton = Roact.createElement(OptionButton, {
			order = 1,
			text = "Cancel",
			onClick = props.cancelCallback,
		})
		ConfirmButton = Roact.createElement(OptionButton, {
			order = 2,
			text = "Confirm",
			onClick = props.confirmCallback,
		})
	})
end
```

You can see a full example of a migration away from reserved keys in [this UIBlox PR](https://github.com/Roblox/uiblox/pull/368).

## No Legacy Context

Legacy Roact implemented a `_context` field on all component instances as an alternative implementation for the Context feature. This is deprecated in legacy Roact and is not supported in Roact 17+. **Attempting to access fields on `self._context` in Roact 17+ will throw an error.**

### How To Convert

Replace any uses of `_context` with the [Provider and Consumer pattern via `createContext`](https://roblox.github.io/roact/advanced/context/). This is the preferred pattern in legacy Roact as well because it allows Roact to trigger updates on context consumers when context providers pass in a new value.

Generally, you'll take the following steps:

1. Create a context object that you will use in place of `_context` by calling `createContext` and saving the result, usually as the return value of a separate `ModuleScript`.
2. Wherever you have a component that _writes_ to `self._context`, instead wrap the component's children in a `Context.Provider` component and provide the value that was previously being written to `self._context`.
3. Wherever you have a component that _reads_ from `self._context`, instead wrap that component's children in a `Context.Consumer` component. The Consumer accepts the `render` prop, which is a function that accepts a context value and returns a Roact element.

!!! info
	The `createContext` API is available in legacy **Roact 1.3.0** (or newer) and is fully supported in Roact 17.

### Example

Suppose we have a `style` object that must be provided to all children of our app. We define it in our top-level `App` component and read from it in our `Label` component.

#### Legacy
```lua
local AppStyle = require(script.Parent.AppStyle)

local Label = Roact.Component:extend("Label")

function Label:init()
	-- reading style from context
	self.style = self._context.style
end

function Label:render()
	return Roact.createElement("TextLabel", {
		BackgroundColor3 = self.style.LabelColor,
		Text = props.text,
	})
end

local App = Roact.Component:extend("App")

function App:init()
	-- defining style in context
	self._context.style = AppStyle
end

function App:render()
	return Roact.createElement("Frame", {
		Size = UDim2.fromScale(1, 1)
	}, {
		Start = Roact.createElement(Button, {
			text = "Hello World",
		})
	})
end
```

#### Roact 17 Compatible
```lua hl_lines="3 8-9 11 14-15 21-24 31"
local AppStyle = require(script.Parent.AppStyle)

local StyleContext = Roact.createContext(nil)

local Label = Roact.Component:extend("Label")

function Label:render()
	return Roact.createElement(StyleContext.Consumer, {
		render = function(style)
			return Roact.createElement("TextLabel", {
				BackgroundColor3 = style.LabelColor,
				Text = props.text,
			})
		end
	})
end

local App = Roact.Component:extend("App")

function App:render()
	return Roact.createElement(StyleContext.Provider, {
		value = AppStyle,
	}, {
		App = Roact.createElement("Frame", {
			Size = UDim2.fromScale(1, 1)
		}, {
			Start = Roact.createElement(Button, {
				text = "Hello World",
			})
		})
	})
end
```

You can see a full example of a migration to the `createContext` API in [this Lua Apps PR](https://github.com/Roblox/lua-apps/pull/3612).

## Explicit Ref Forwarding

Legacy Roact uses `Roact.Ref` as a special prop key to support the refs feature. Assigning the `[Roact.Ref]` property to a callback ref or ref object allows Roact to assign its value. However, Roact only interacts with the `Roact.Ref` property if the component receiving the props is a host component.

Some class component definitions rely on this behavior by accepting and reassigning the `[Roact.Ref]` prop themselves, knowing that Roact won't capture it. The pattern of passing a provided ref onto a child is called "ref forwarding". We refer to using `[Roact.Ref]` as mechanism of ref forwarding as "implicit ref forwarding".

### How To Convert

In Roact 17+, `Roact.Ref` is aliased to the string "ref", and refs that point to class components are now supported. **Components that were using implicit ref forwarding will fail to forward their provided refs when upgrading to Roact 17+.**

Fortunately, this can be easily fixed with the [`forwardRef` function](https://roblox.github.io/roact/advanced/bindings-and-refs/#ref-forwarding). We refer to this as "explicit ref forwarding".

!!! info
	The `forwardRef` API is available in legacy **Roact 1.4.0** (or newer) and is fully supported in Roact 17.

### Example

Suppose we have a `FancyTextBox` component that accepts a ref, and passes it on to an underlying `TextBox`. Rather than accepting the `[Roact.Ref]` prop, we should use the `Roact.forwardRef` wrapper to explicitly accept a ref and assign it to the `TextBox`.

#### Legacy
```lua
local function FancyButton(props)
	return Roact.createElement("TextBox", {
		PlaceholderText = "Enter your text here",
		PlaceholderColor3 = Color3.new(0.4, 0.4, 0.4),
		[Roact.Change.Text] = props.onTextChange,
		-- Implicitly forwarding a ref via the `Roact.Ref` prop
		[Roact.Ref] = props[Roact.Ref],
	})
end
```

#### Roact 17 Compatible
```lua hl_lines="1 6-7"
local FancyButton = Roact.forwardRef(function(props, ref)
	return Roact.createElement("TextBox", {
		PlaceholderText = "Enter your text here",
		PlaceholderColor3 = Color3.new(0.4, 0.4, 0.4),
		[Roact.Change.Text] = props.onTextChange,
		-- Explicitly forwarding a ref passed in via `forwardRef`
		[Roact.Ref] = ref,
	})
end)
```

You can see a full example of `forwardRef` migration in [this UIBlox PR](https://github.com/Roblox/uiblox/pull/275).

## Prefer getDerivedStateFromProps

Legacy Roact allows class components to implement both `willUpdate` and `getDerivedStateFromProps` lifecycle methods.

React JS, however, does not support both methods when implemented on the same component. When `getDerivedStateFromProps` is defined, it _replaces_ `componentWillUpdate` entirely. **Roact 17 inherits this restriction: `getDerivedStateFromProps` will replace `willUpdate` if both are defined.**

### How To Convert

In order to make existing components Roact 17 compatible, make sure to use _either_ `willUpdate` or `getDerivedStateFromProps`, but not both.

Whenever possible, use `getDerivedStateFromProps` to resolve interactions between state and props. Just like in React JS 16.3.0 and onward, `willUpdate` is a deprecated legacy lifecycle method and should be avoided as it can exacerbate problems with asynchronous rendering, a flagship feature of Roact 17+.

!!! info
	The `getDerivedStateFromProps` static lifecycle method is supported in legacy Roact as far back as **Roact 0.2.0** and is fully supported in Roact 17.

### Example

Typically, usage of both `willUpdate` and `getDerivedStateFromProps` is a sign of an overly complicated component, which makes it difficult to provide a simplified example that's meaningful.

Consider looking at other migrations of this kind for more complex examples:

* [This PR to the legacy Infinite Scroller component](https://github.com/Roblox/infinite-scroller/pull/140).
* [This PR to the Roact Gamepad library](https://github.com/Roblox/roact-gamepad/pull/53).

Additionally, refer to the React JS guidance on [migrating away from legacy lifecycle methods](https://reactjs.org/blog/2018/03/27/update-on-async-rendering.html).
