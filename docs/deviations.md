While Roact has been architected to align with React JS's APIs and idioms, a small number of deviations have been introduced for one or several of the following reasons:

* Differences between JavaScript and Luau
* Differences between Roblox and the HTML DOM
* Supporting features from legacy Roact that are not in React JS
* Easier adoption of Roact 17+ by users of legacy Roact

The following list attempts to comprehensively describe all of the differences between Roact 17+ and its equivalent upstream version in React JS. It is intended to be a companion to the [Roact 17 adoption guide](migrating-from-roact-1x.md), which focuses more on the differences between legacy Roact and Roact 17+.

## JSX

The Luau ecosystem does not yet have the tooling to support JSX. Instead, use `React.createElement` as your primary tool for building UIs with Roact 17. Element construction in Roact is exactly like [using React with JSX](https://reactjs.org/docs/react-without-jsx.html).

!!! info
	Future support for a JSX-equivalent feature for Luau has been proposed, and will be considered as Roact 17+ is adopted.

## React.useState

`React.useState` returns two values rather than an array containing two values.

Luau does not have syntactic sugar for destructuring like javascript:
```js
const [value, setValue] = React.useState(0);
```

However, it _does_ support multiple return values, so we can support a very similar usage:
```lua
local value, setValue = React.useState(0)
```

## Stable Keys

In React JS, the reserved "key" prop is used to provide stable identities to DOM elements. This improves performance when list-like data is reordered by helping React understand which elements are which, instead of simply modifying the element at each position to line up with the new ordering (more info in the [React documentation](https://reactjs.org/docs/lists-and-keys.html)).

Since order has no inherent meaning in Roblox's DOM, legacy Roact generally expected children to be provided as a _map_ instead of an array, where the keys to the map are the stable keys associated with the elements. This behavior was used instead of a reserved "key" prop (more info in the [Roact documentation](https://roblox.github.io/roact/performance/reduce-reconciliation/#stable-keys)).

Roact 17+ supports _both_ methods for providing keys. Both of the following examples are valid and equivalent.

With table keys:
```lua
-- Returns a fragment of items in an ordered list
function NumberList(props)
	local numbers = props.numbers
	for i, number in ipairs(numbers) do
		local key = tostring(i)
		listItems[key] = React.createElement("TextLabel", {
			Text = key,
			LayoutOrder = i,
		})
	end);
	return listItems
end
```

Using the special "key" prop:
```lua
-- Returns a fragment of items in an ordered list
function NumberList(props)
	local numbers = props.numbers
	for i, number in ipairs(numbers) do
		local key = tostring(i)
		local element = React.createElement("TextLabel", {
			key = key,
			Text = key,
			LayoutOrder = i,
		})
		table.insert(listItems, element)
	end);
	return listItems
end
```

If your component provides keys using both methods at the same time, Roact will consider this a mistake and print a warning. The following code would result in a warning:
```lua
return React.createElement("Frame", nil, {
	Label = React.createElement("TextLabel", {
		key = "label1",
		Text = "Hello",
	})
})
```

In the above example, Roact doesn't know whether you wanted to use "label1" or "Label" as the key, so it falls back to the explicitly provided key ("label1"). In [Dev Mode](configuration.md#dev), it will output an appropriate warning as well.

## Class Components
Luau does not currently have ES6's `class` semantics. For class components, Roact exposes an `extend` method to provide equivalent behavior.

### React.Component:extend
```
React.Component:extend(name: string): ReactComponent
```
The `extend` method on components replaces the `extend` behavior used in ES6's class components. It returns a React component definition, which can then be used to define lifecycle methods.

For example, a class component in Roact can be created like this:
```lua
local MyComponent = React.Component:extend("MyComponent")

function MyComponent:render()
	return React.createElement("TextLabel", {Text = self.props.text})
end

function MyComponent:componentDidMount()
	print("rendered with text " .. self.props.text)
end
```

Equivalently, `React.PureComponent:extend` is used to define PureComponents.

### Constructors
Since Luau currently lacks a `class` feature, there are also no inheritable constructors; instead, Roact provides a lifecycle method called `init` that takes the place of the constructor, running immediately after an instance of that class is created.

For all intents and purposes, this should behave exactly like a constructor for a class component in React JS, except that there is no `super` logic needed.

### Calling `setState` in Constructors
In React JS, `setState` is not allowed inside component constructors. Instead, React documentation suggests that `this.state` should be assigned to directly, but _never anywhere else_.

Legacy Roact opts to allow `setState` inside of the `init` method (equivalent to a constructor), because it allows documentation to consistently warn against assigning directly to `self.state`. However, for backwards compatibility, it still supports direct assignments to `self.state` in `init`.

#### Recommended Use

As with legacy Roact, Roact 17 allows both direct assignment and use of `setState`. This allows guidance from legacy Roact documentation and common practice to remain accurate.

In Roact 17+, it is still recommended to use `setState` inside of component `init` methods. This means that you will _always_ avoid assigning directly to `self.state`.

#### Behavior

When used in a constructor, `setState` will treat the `updater` argument exactly as it does elsewhere.

* If `setState` is called multiple times in a constructor, each subsequent update will be merged into previous state
* The `updater` argument can be a function that accepts previous state and returns a new table that will be merged into any previous state
* The `updater` argument can be a table that will be merged into any previous state

!!! caution
	When using `setState` in a constructor, the optional `callback` argument will not be used. Instead, consider putting the desired behavior in a `componentDidMount` implementation.

### Property Validation
The legacy api `validateProps` is still present and has a backwards-compatible API.

## Function Components
In JavaScript, functions are also objects, which means that they can have member fields defined on them. Luau does not allow this, so some features are not available on function components.

!!! info
	With the introduction of Hooks, function components are the preferred style of component definition. Giving up features like `defaultProps` and prop validation is not ideal, so future API additions may provide a way to create smarter function components.

### defaultProps
For the time being, function components do not support the `defaultProps` feature. In the future, we may want to re-implement it in terms of hooks to make sure that function components with hooks are as appealing and feature-rich as possible.

### propTypes
For the time being, function components do not support the `propTypes` feature. While propTypes is less often used and can in many cases be superseded by static type checking, we may want to, in the future, re-implement it in terms of hooks to make sure that function components with hooks are as appealing and feature-rich as possible.

### validateProps
In Roact 17, we continue to support legacy Roact's `validateProps`. Prior Roact documentation on this method can be found [here](https://roblox.github.io/roact/api-reference/#validateprops).

## Bindings and Refs
Roact supports callback refs, refs created using `React.createRef`, and refs using the `React.useRef` hook. However, under the hood, Refs are built on top of a concept called Bindings.

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

Thus, it would require much more trickery to make even a simple gamepad neighbor assignment work correctly. However *with refs implemented as bindings*, the above scenario can be solved pretty simply:
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
With the above implementation, something like the following happens:

1. Confirm Button renders first and its ref is assigned
2. Confirm Button's NextSelectionRight property is set to the Cancel Button's ref, **which is currently nil**
3. Cancel Button renders and its ref is assigned
	* The binding value updates, and the Confirm button's NextSelectionRight property is assigned to the Cancel Button's new ref value
4. Cancel Button's NextSelectionLeft property is properly set to the Confirm Button's ref

...or the inverse, with the Cancel Button rendering first. Either way, both refs are assigned, and both neighbor properties are assigned by the time the render is complete.