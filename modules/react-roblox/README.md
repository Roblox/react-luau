# react-roblox-reconciler
A Roblox-opinionated renderer, intended to stand in for native renderers like `react-dom`.

Status: 🔨 Under Construction

---

### ✏️ Notes

* Mimics pieces of the interface exported from `react-dom`

# Translation Plans

## Keys as Names
Roact will assign the keys applied to host elements to their `Name` field to make the resulting Roblox DOM more readable and easily configurable. We need to support this behavior as well.

## Migrating Bindings
Bindings are a Roact feature that are tightly coupled with refs, and currently implemented exclusively in `ReactRoblox` despite having some generic logic.

### Relation to Refs
Currently, bindings are exposed as part of ReactRoblox:
```lua
ReactRoblox.createBinding(nil)
ReactRoblox.joinBindings(binding1, binding2)
```

Bindings are described in detail [in the Roact docs](https://roblox.github.io/roact/advanced/bindings-and-refs/#bindings). Any time a host property is assigned a binding value, Roact does the following:
1. Assign the current value of the binding
2. Create an updater function that assigns new values to the host property
3. Subscribe to the binding object with the updater function

And when either the component is unmounted, or the prop is assigned a different value:
1. Disconnect the binding subscription
2. If the component is not unmounting, assign the host prop to the new primitive value

### Refs as Bindings
This will work just fine in many cases! However, in Roact, the binding implementation is used to power Refs as well. The Roblox API exposes certain host properties that must be assigned _Instance references_ as values. Effectively, there are native APIs that expect a `ref.current` value as a value.

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

Thus, it would require much more trickery to make even a simple gamepad neighbor assignment work correctly. However *when refs are implemented as bindings under the hood*, the above scenario can be solved pretty simply:
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

### Relation to Reconciler Internals
Bindings operate in old Roact's model, which means that they do not interact with any work queues and always update synchronously.

We should be able to carry over bindings as they are into the reconciler by simply replacing the implementation of `createRef` with a binding creation instead. This would restore the behavior described above.

However, the abstraction of bindings leaks into the renderer when the renderer host config is responsible for understanding what bindings are and managing their subscriptions. Should we consider inverting the logic somehow?
* This would add more deviations to the reconciler logic
* It would be difficult (or at least delicate) to integrate this into existing reconciler logic

### Proposed Strategy
1. Replace `ReactCreateRef`'s implementation of `createRef` with that of Roact's
	* This will include changing the type definition of RefObject
	* We may want to also use React's typing logic rather than the Roact logic
	* We should also consider how heavily (and how) we want to obscure internals; the current bindings implementation is pretty zealous about hiding internals
2. Introduce ReactRoblox tests to ensure refs as bindings behave as before
3. Investigate using reconciler internals to manage binding updates. It may be reasonable to adjust how binding subscriptions work so that we can batch, defer, etc. the updates. There's a lot to consider here, so we'll need to proceed thoughtfully. We might consider doing this later on as a separate step.
4. Create a `useBinding` hook. This can have essentially the same signature as `useState`, but with different semantics. By virtue of being a hook, this will make bindings usable in function components.
5. Document bindings and refs. Documentation on bindings ought to make reference to `useState` as well as `useRef`.

### Concerns
* Upstream documentation treats refs as more general objects: https://reactjs.org/docs/hooks-faq.html#is-there-something-like-instance-variables
	* Some of the uses outlined here would might behave differently when refs are implemented as bindings
	* To conform, we'd need to make assigning to `current` equivalent to updating a binding
	* There's a part of these docs I don't understand, where it says: "If we just wanted to set an interval, we wouldn’t need the ref (id could be local to the effect), but it’s useful if we want to clear the interval from an event handler". It's unclear to me why you couldn't just close over a local variable the same way we're closing over intervalRef?
* Is it reasonable to keep Roact's restrictions on refs? This would entail:
	* (deviation) disallow direct assignment to ref.current
		* When attempting to assign to ref.current, provide an error message that guides users to bindings documentation; suggest using either state or bindings, depending on intent
	* (deviation) remove the initialValue from useRef, which makes much less sense than it does in upstream where refs are generalized
		* If an initial value is provided, warn and suggest use of bindings or state

## Text Instances
We've danced around this before; should we support text instances?
* Is it remotely useful to do so?
* Would it be valuable for sheer alignment purposes?

## ReactDOMLegacy.findDOMNode
It's unclear whether we should port this functionality in the long run. For now, we'll hold off. Below are some tradeoffs:

Pros
* Based on reconciler internals (`ReactFiberReconciler.findHostInstance`), which is generic reconciler logic
* Should be relatively easy to port, since the reconciler implementation already exists
* Would it be helpful for gamepad logic? Maybe a viable way of handling default selection?

Cons
* It seems highly abusable, and rarely idiomatic
* Not clear if there are any theoretically valid use cases besides gamepad support

## ReactDOMLegacy.render and ReactDOMLegacy.unmountComponentAtNode
Part of the legacy interface. This is the most recognizable react entry-point:
```javascript
ReactDOM.render(
  <h1>Hello, world!</h1>,
  document.getElementById('root')
);
```

However, it's also being phased out in favor of the "root" apis: `createLegacyRoot`, `createBlockingRoot`, and `createRoot`, the first of which should be equivalent to `render`.

### Proposed Strategy
The `render` and `unmountComponentAtNode` APIs will be [phased out in React 18](https://github.com/reactwg/react-18/discussions/5), so we should strongly consider not porting them at all.

## ReactDOMLegacy unstable update scheduling logic
The following scheduling-related functions are exported from ReactRoblox:
* `unstable_batchedUpdates`
* `unstable_flushControlled`
* `unstable_runWithPriority`

These are intended to be fully released in the future. Should we exclude them until they're stabilized, or include them as is for now?

## Hydration

### ReactDOMLegacy.hydrate
Legacy hydration; we should probably try to avoid supporting the legacy approach; it will be phased out with the roots API.

### `hydrate` Option for Root
Relies upon hydration support in the reconciler. Can be tackled as a single holistic feature implementation. We might want to introduce intentional, user-facing "unimplemented" errors that are thrown when the option is first encountered in `createRoot` implementations.

### scheduleHydration
React 17 currently exports the `unstable_scheduleHydration` API. This will need investigation and implementation as part of implementing hydration

## createEventHandle
React 17 exposes an `unstable_createEventHandle` API for managing event listeners on objects. Roact has its own approach to this sort of behavior via `Roact.Change` and `Roact.Event`, which are pulled into ReactRoblox.

I suspect we'll simply avoid translating this logic, and call it out in documentation for `Change` and `Event`. We may also want to add a warning when accessing it that directs users to `Change` and `Event` documentation, but it may be sufficient to leave it out since it's still `unstable` anyway.

## isNewReconciler
React 17 exposes an `unstable_isNewReconciler` API. This is probably unhelpful for us, since we haven't ported (and won't port) the _old_ reconciler anyways. We should probably just omit this.

## renderSubtreeIntoContainer
React 17 exposes an `unstable_renderSubtreeIntoContainer` API. I'm unclear on what this does, other than it being part of the legacy rendering logic. Warnings around it say that it's deprecated, so we can likely exclude it.

## input, select, option, and textarea tags
These tags have special handling in React to allow for them to play nicely with the DOM, regardless of which is used as a source of truth. Each of them is a DOM element that has its own externally-mutable state.

In order to make them behave correctly, React does a few things:
* Tracks whether or not the `value` has been provided as a prop
	* If so, then changes to the value will _not_ trigger prop updates to the element
	* However, if values are not provided, the element will be changed when external changes to its underlying object are changed
	* In this way, if a component's `value` field is not set, but something else changes it externally, React will understand when re-rendering that it should not unset the value
* Tracks whether or not the value has a default
* Uses special logic when applying prop updates to respect whether or not the component is "controlled" (`value` provided as a prop, React source of truth) or "uncontrolled" (no `value` provided via props, DOM source of truth)

In Roact, we have similar kinds of issues with certain constructs. The only meaningful equivalent I'm aware of is `TextBox`, but it has very similar issues to those of `textarea` in ReactDOM.

Equivalent behavior for `TextBox` would be nice to have, but will need careful implementation.

## Roact.Change and Roact.Event
The Change and Event logic from Roact has been lifted into ReactRoblox. This logic should still behave exactly as it did in Roact. There are a couple things to address:
* This logic needs to be documented as part of Roact 17's deviation documents
* Exposing these as `ReactRoblox.Change` and `ReactRoblox.Event` means that component definitions need to depend upon the ReactRoblox library to provide them
	* This leaks the renderer abstraction into component definitions, which could otherwise be renderer-agnostic
	* While we don't currently have non-roblox targets, is there a possibility that this abstraction leak causes issues?
	* All of the above is also true 
	* A less important concern is the slight ergonomics hit that comes from needing another import
	* Could we possibly genericize this concept and move it into React?
