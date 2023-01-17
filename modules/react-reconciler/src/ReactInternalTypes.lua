--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/7baf9d4128d41903de125527b50285ea9862cf9a/packages/react-reconciler/src/ReactInternalTypes.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
type Array<T> = LuauPolyfill.Array<T>
type Map<K, V> = LuauPolyfill.Map<K, V>
type Object = { [string]: any }
type SimpleSet<T> = { [T]: boolean }
type SimpleMap<K, V> = { [K]: V }
type Set<T> = LuauPolyfill.Set<T>

local ReactTypes = require(Packages.Shared)
-- ROBLOX deviation: ReactElement is defined at the top level of Shared along
-- with the rest of the ReactTypes
type Source = ReactTypes.Source
type RefObject = ReactTypes.RefObject
type ReactContext<T> = ReactTypes.ReactContext<T>
type MutableSourceVersion = ReactTypes.MutableSourceVersion
type MutableSource<Source> = ReactTypes.MutableSource<Source>
type MutableSourceSubscribeFn<Source, Snapshot> = ReactTypes.MutableSourceSubscribeFn<
	Source,
	Snapshot
>
type MutableSourceGetSnapshotFn<Source, Snapshot> = ReactTypes.MutableSourceGetSnapshotFn<
	Source,
	Snapshot
>

-- ROBLOX deviation START: These are 'mixed' by default, and specialized by the renderer, need complicated dynamic resolution to do this properly
-- local ReactFiberHostConfig = require(script.Parent.ReactFiberHostConfig)
-- type SuspenseInstance = ReactFiberHostConfig.SuspenseInstance
type SuspenseInstance = any
-- ROBLOX deviation END
local ReactWorkTags = require(script.Parent.ReactWorkTags)
type WorkTag = ReactWorkTags.WorkTag
local ReactTypeOfMode = require(script.Parent.ReactTypeOfMode)
type TypeOfMode = ReactTypeOfMode.TypeOfMode
local ReactFiberFlags = require(script.Parent.ReactFiberFlags)
type Flags = ReactFiberFlags.Flags
-- deviation: FiberLane types are defined and exported from here to avoid
-- cyclical requires
export type LanePriority = number
export type Lanes = number
export type Lane = number
export type LaneMap<T> = { [number]: T }

-- ROBLOX deviation: Update<>, SharedQueue<>, UpdateQueue<> transplanted from ReactUpdateQueue for use by createReactNoop
export type Update<State> = {
	-- TODO: Temporary field. Will remove this by storing a map of
	-- transition -> event time on the root.
	eventTime: number,
	lane: Lane,

	-- ROBLOX FIXME Luau: revert when luau supports singleton integers
	-- tag: 0 | 1 | 2 | 3,
	tag: number,
	payload: any,
	callback: (() -> ...any)?,

	next: Update<State>?,
}

export type SharedQueue<State> = {
	pending: Update<State>?,
}

export type UpdateQueue<State> = {
	baseState: State,
	firstBaseUpdate: Update<State>?,
	lastBaseUpdate: Update<State>?,
	shared: SharedQueue<State>,
	effects: Array<Update<State>>?,
}

export type HookType =
	"useState"
	| "useReducer"
	| "useContext"
	| "useRef"
	-- ROBLOX deviation: Bindings are a feature unique to Roact
	| "useBinding"
	| "useEffect"
	| "useLayoutEffect"
	| "useCallback"
	| "useMemo"
	| "useImperativeHandle"
	| "useDebugValue"
	| "useDeferredValue"
	| "useTransition"
	| "useMutableSource"
	| "useOpaqueIdentifier"
local ReactRootTags = require(script.Parent.ReactRootTags)
type RootTag = ReactRootTags.RootTag
-- ROBLOX deviation: we can't import types for dynamic imports like HostConfig files
-- type TimeoutHandle = ReactFiberHostConfig.TimeoutHandle;
-- type NoTimeout = ReactFiberHostConfig.NoTimeout;
type TimeoutHandle = any
type NoTimeout = any
-- ROBLOX deviation: type forwarded to top-level export
local Shared = require(Packages.Shared)
type Wakeable = Shared.Wakeable
-- ROBLOX deviation: Interaction type forwarded to top-level export
local Scheduler = require(Packages.Scheduler)
type Interaction = Scheduler.Interaction

-- ROBLOX deciation: Luau doesn't support type literals:  99 | 98 | 97 | 96 | 95 | 90
export type ReactPriorityLevel = number

export type ContextDependency<T> = {
	context: ReactContext<T>,
	observedBits: number,
	-- ROBLOX TODO: upstream only parameterizes this type with `mixed`, so avoid Luau recursive type constraint. upstream this change later.
	next: ContextDependency<T> | nil,
	-- ROBLOX deviation START: don't allow for extension unless we have to
	-- ...
	-- ROBLOX deviation END
}

export type Dependencies = {
	lanes: Lanes,
	firstContext: ContextDependency<any> | nil,
	-- ROBLOX deviation START: don't allow for extension unless we have to
	-- ...
	-- ROBLOX deviation END
}

-- ROBLOX deviation: Roact stable keys - slightly widen the type definition of a
-- stable key so that it's likely to work with existing Roact code. Includes
-- numbers for mixed/sparse tables
export type RoactStableKey = string | number

-- A Fiber is work on a Component that needs to be done or was done. There can
-- be more than one per component.
export type Fiber = {
	-- These first fields are conceptually members of an Instance. This used to
	-- be split into a separate type and intersected with the other Fiber fields,
	-- but until Flow fixes its intersection bugs, we've merged them into a
	-- single type.

	-- An Instance is shared between all versions of a component. We can easily
	-- break this out into a separate object to avoid copying so much to the
	-- alternate versions of the tree. We put this on a single object for now to
	-- minimize the number of objects created during the initial render.

	-- Tag identifying the type of fiber.
	tag: WorkTag,

	-- ROBLOX deviation: Use a slightly more permissive key type to allow for
	-- sparse arrays, which will still be distinct from actual arrays.
	-- Unique identifier of this child.
	key: RoactStableKey?,

	-- The value of element.type which is used to preserve the identity during
	-- reconciliation of this child.
	elementType: any,

	-- The resolved function/class/ associated with this fiber.
	type: any,

	-- The local state associated with this fiber.
	stateNode: any,

	-- Conceptual aliases
	-- parent : Instance -> return The parent happens to be the same as the
	-- return fiber since we've merged the fiber and instance.

	-- Remaining fields belong to Fiber

	-- The Fiber to return to after finishing processing this one.
	-- This is effectively the parent, but there can be multiple parents (two)
	-- so this is only the parent of the thing we're currently processing.
	-- It is conceptually the same as the return address of a stack frame.
	return_: Fiber | nil,

	-- Singly Linked List Tree Structure.
	child: Fiber?,
	sibling: Fiber?,
	index: number,

	-- The ref last used to attach this node.
	-- I'll avoid adding an owner field for prod and model that as functions.
	-- ROBLOX deviation: Lua doesn't allow fields on functions
	-- ref: (((any) -> ()) & {_stringRef: string?, [string]: any}) | RefObject,
	ref: nil | ((handle: any) -> ()) | { _stringRef: string?, [string]: any } | RefObject,

	-- Input is the data coming into process this fiber. Arguments. Props.
	pendingProps: any, -- This type will be more specific once we overload the tag.
	memoizedProps: any, -- The props used to create the output.

	-- A queue of state updates and callbacks.
	updateQueue: any,

	-- The state used to create the output
	memoizedState: any,

	-- Dependencies (contexts, events) for this fiber, if it has any
	dependencies: Dependencies?,

	-- Bitfield that describes properties about the fiber and its subtree. E.g.
	-- the ConcurrentMode flag indicates whether the subtree should be async-by-
	-- default. When a fiber is created, it inherits the mode of its
	-- parent. Additional flags can be set at creation time, but after that the
	-- value should remain unchanged throughout the fiber's lifetime, particularly
	-- before its child fibers are created.
	mode: TypeOfMode,

	-- Effect
	flags: Flags,
	subtreeFlags: Flags,
	deletions: Array<Fiber>?,

	-- Singly linked list fast path to the next fiber with side-effects.
	nextEffect: Fiber?,

	-- The first and last fiber with side-effect within this subtree. This allows
	-- us to reuse a slice of the linked list when we reuse the work done within
	-- this fiber.
	firstEffect: Fiber?,
	lastEffect: Fiber?,

	lanes: Lanes,
	childLanes: Lanes,

	-- This is a pooled version of a Fiber. Every fiber that gets updated will
	-- eventually have a pair. There are cases when we can clean up pairs to save
	-- memory if we need to.
	alternate: Fiber?,

	-- Time spent rendering this Fiber and its descendants for the current update.
	-- This tells us how well the tree makes use of sCU for memoization.
	-- It is reset to 0 each time we render and only updated when we don't bailout.
	-- This field is only set when the enableProfilerTimer flag is enabled.
	actualDuration: number?,

	-- If the Fiber is currently active in the "render" phase,
	-- This marks the time at which the work began.
	-- This field is only set when the enableProfilerTimer flag is enabled.
	actualStartTime: number?,

	-- Duration of the most recent render time for this Fiber.
	-- This value is not updated when we bailout for memoization purposes.
	-- This field is only set when the enableProfilerTimer flag is enabled.
	selfBaseDuration: number?,

	-- Sum of base times for all descendants of this Fiber.
	-- This value bubbles up during the "complete" phase.
	-- This field is only set when the enableProfilerTimer flag is enabled.
	treeBaseDuration: number?,

	-- Conceptual aliases
	-- workInProgress : Fiber ->  alternate The alternate used for reuse happens
	-- to be the same as work in progress.
	-- _G.__DEV__ only
	_debugID: number?,
	_debugSource: Source?,
	_debugOwner: Fiber?,
	_debugIsCurrentlyTiming: boolean?,
	_debugNeedsRemount: boolean?,

	-- Used to verify that the order of hooks does not change between renders.
	_debugHookTypes: Array<HookType>?,
}

export type SuspenseHydrationCallbacks = {
	onHydrated: ((SuspenseInstance) -> ())?,
	onDeleted: ((SuspenseInstance) -> ())?,
	-- ROBLOX deviation START: don't allow for extension unless we have to
	-- ...
	-- ROBLOX deviation END
}

-- deviation: Instead of combining all these props after the fact, we define
-- them all in one to allow Luau's syntax

-- Exported FiberRoot type includes all properties,
-- To avoid requiring potentially error-prone :any casts throughout the project.
-- Profiling properties are only safe to access in profiling builds (when enableSchedulerTracing is true).
-- The types are defined separately within this file to ensure they stay in sync.
-- (We don't have to use an inline :any cast when enableSchedulerTracing is disabled.)
export type FiberRoot = {
	-- ...BaseFiberRootProperties,
	-- The type of root (legacy, batched, concurrent, etc.)
	tag: RootTag,

	-- Any additional information from the host associated with this root.
	containerInfo: any,
	-- Used only by persistent updates.
	pendingChildren: any,
	-- The currently active root fiber. This is the mutable root of the tree.
	current: Fiber,

	-- ROBLOX deviation START: we use a lightweight unordered set for performance
	pingCache: SimpleMap<
		Wakeable,
		(SimpleSet<any> | SimpleMap<Wakeable, SimpleSet<any>>)
	> | nil,
	-- ROBLOX deviation END

	-- A finished work-in-progress HostRoot that's ready to be committed.
	finishedWork: Fiber?,
	-- Timeout handle returned by setTimeout. Used to cancel a pending timeout, if
	-- it's superseded by a new one.
	timeoutHandle: TimeoutHandle | NoTimeout,
	-- Top context object, used by renderSubtreeIntoContainer
	context: Object?,
	pendingContext: Object?,
	-- Determines if we should attempt to hydrate on the initial mount
	hydrate: boolean,

	-- Used by useMutableSource hook to avoid tearing during hydration.
	mutableSourceEagerHydrationData: Array<MutableSource<any> | MutableSourceVersion>?,

	-- Node returned by Scheduler.scheduleCallback. Represents the next rendering
	-- task that the root will work on.
	callbackNode: any,
	callbackPriority: LanePriority,
	eventTimes: LaneMap<number>,
	expirationTimes: LaneMap<number>,

	pendingLanes: Lanes,
	suspendedLanes: Lanes,
	pingedLanes: Lanes,
	expiredLanes: Lanes,
	mutableReadLanes: Lanes,

	finishedLanes: Lanes,

	entangledLanes: Lanes,
	entanglements: LaneMap<Lanes>,

	-- ...ProfilingOnlyFiberRootProperties,
	-- The following attributes are only used by interaction tracing builds.
	-- They enable interactions to be associated with their async work,
	-- And expose interaction metadata to the React DevTools Profiler plugin.
	-- Note that these attributes are only defined when the enableSchedulerTracing flag is enabled.
	interactionThreadID: number,
	memoizedInteractions: Set<Interaction>,
	pendingInteractionMap: Map<Lane | Lanes, Set<Interaction>>,

	-- ...SuspenseCallbackOnlyFiberRootProperties,
	-- The follow fields are only used by enableSuspenseCallback for hydration.
	hydrationCallbacks: SuspenseHydrationCallbacks?,

	-- ROBLOX deviation START: don't allow for extension unless we have to
	-- ...
	-- ROBLOX deviation END
}

type BasicStateAction<S> = ((S) -> S) | S
type Dispatch<A> = (A) -> ()

-- ROBLOX deviation: Dispatcher is defined in Shared to avoid circular deps
export type Dispatcher = Shared.Dispatcher

-- deviation: Return something so that the module system is happy
return {}
