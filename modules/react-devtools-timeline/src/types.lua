-- ROBLOX upstream: https://github.com/facebook/react/blob/v19.1.1/packages/react-devtools-timeline/src/types.js

type null = nil
type RegExp = any
type Image = any

-- deviation: inline ScrollState import here
export type ScrollState = {
	offset: number,
	length: number,
}

export type ErrorStackFrame = {
	fileName: string,
	lineNumber: number,
	columnNumber: number,
}

export type Milliseconds = number

export type ReactLane = number

export type NativeEvent = {
	depth: number,
	duration: Milliseconds,
	timestamp: Milliseconds,
	type: string,
	warning: string | null,
}

type BaseReactEvent = {
	componentName: string?,
	timestamp: Milliseconds,
	warning: string | null,
}

type BaseReactScheduleEvent = BaseReactEvent & {
	lanes: { ReactLane },
}
export type ReactScheduleRenderEvent = BaseReactScheduleEvent & {
	type: "schedule-render",
}
export type ReactScheduleStateUpdateEvent = BaseReactScheduleEvent & {
	componentStack: string?,
	type: "schedule-state-update",
}
export type ReactScheduleForceUpdateEvent = BaseReactScheduleEvent & {
	type: "schedule-force-update",
}

export type Phase = "mount" | "update"

export type SuspenseEvent = BaseReactEvent & {
	depth: number,
	duration: number | null,
	id: string,
	phase: Phase | null,
	promiseName: string | null,
	resolution: "rejected" | "resolved" | "unresolved",
	type: "suspense",
}

export type ThrownError = {
	componentName: string?,
	message: string,
	phase: Phase,
	timestamp: Milliseconds,
	type: "thrown-error",
}

export type SchedulingEvent =
	ReactScheduleRenderEvent
	| ReactScheduleStateUpdateEvent
	| ReactScheduleForceUpdateEvent
export type SchedulingEventType =
	"schedule-render"
	| "schedule-state-update"
	| "schedule-force-update"

export type ReactMeasureType =
	"commit"
	-- render-idle: A measure spanning the time when a render starts, through all
	-- yields and restarts, and ends when commit stops OR render is cancelled.
	| "render-idle"
	| "render"
	| "layout-effects"
	| "passive-effects"

export type BatchUID = number

export type ReactMeasure = {
	type: ReactMeasureType,
	lanes: { ReactLane },
	timestamp: Milliseconds,
	duration: Milliseconds,
	batchUID: BatchUID,
	depth: number,
}

export type NetworkMeasure = {
	depth: number,
	finishTimestamp: Milliseconds,
	firstReceivedDataTimestamp: Milliseconds,
	lastReceivedDataTimestamp: Milliseconds,
	priority: string,
	receiveResponseTimestamp: Milliseconds,
	requestId: string,
	requestMethod: string,
	sendRequestTimestamp: Milliseconds,
	url: string,
}

export type ReactComponentMeasureType =
	"render"
	| "layout-effect-mount"
	| "layout-effect-unmount"
	| "passive-effect-mount"
	| "passive-effect-unmount"

export type ReactComponentMeasure = {
	componentName: string,
	duration: Milliseconds,
	timestamp: Milliseconds,
	type: ReactComponentMeasureType,
	warning: string | null,
}

--[[
    A flamechart stack frame belonging to a stack trace.
]]
export type FlamechartStackFrame = {
	name: string,
	timestamp: Milliseconds,
	duration: Milliseconds,
	scriptUrl: string?,
	locationLine: number?,
	locationColumn: number?,
}

export type UserTimingMark = {
	name: string,
	timestamp: Milliseconds,
}

export type Snapshot = {
	height: number,
	image: Image | null,
	imageSource: string,
	timestamp: Milliseconds,
	width: number,
}

--[[
    A "layer" of stack frames in the profiler UI, i.e. all stack frames of the
    same depth across all stack traces. Displayed as a flamechart row in the UI.
]]
export type FlamechartStackLayer = { FlamechartStackFrame }

export type Flamechart = { FlamechartStackLayer }

export type HorizontalScrollStateChangeCallback = (scrollState: ScrollState) -> ()
export type SearchRegExpStateChangeCallback = (searchRegExp: RegExp | null) -> ()

return nil
