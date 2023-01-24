-- ROBLOX note: no upstream
-- loosely based on https://github.com/facebook/react/blob/9abc2785cb070148d64fae81e523246b90b92016/scripts/jest/setupTests.js
-- in a way that we use this file to extend jestExpect with custom matchers

local Packages = script.Parent.Parent.TestRunner
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect

local InteractionTracingMatchers =
	require(script.Parent.matchers.interactionTracingMatchers)

jestExpect.extend(require(script.Parent.matchers.reactTestMatchers))
jestExpect.extend({
	toErrorDev = require(script.Parent.matchers.toErrorDev),
	toWarnDev = require(script.Parent.matchers.toWarnDev),
	toLogDev = require(script.Parent.matchers.toLogDev),
	toContainNoInteractions = InteractionTracingMatchers.toContainNoInteractions,
	toHaveBeenLastNotifiedOfInteraction = InteractionTracingMatchers.toHaveBeenLastNotifiedOfInteraction,
	toHaveBeenLastNotifiedOfWork = InteractionTracingMatchers.toHaveBeenLastNotifiedOfWork,
	toMatchInteraction = InteractionTracingMatchers.toMatchInteraction,
	toMatchInteractions = InteractionTracingMatchers.toMatchInteractions,
})

_G.jest = true
