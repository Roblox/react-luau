--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/702fad4b1b48ac8f626ed3f35e8f86f5ea728084/packages/shared/invokeGuardedCallbackImpl.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]
-- local invariant = require(script.Parent.invariant)
local describeError = require(script.Parent["ErrorHandling.roblox"]).describeError

-- deviation: with flow types stripped, it's easier to use varargs directly
local function invokeGuardedCallbackProd(reporter, name, func, context, ...)
	-- local funcArgs = Array.prototype.slice.call(arguments, 3)

	-- ROBLOX deviation: YOLO flag for disabling pcall
	local ok, result
	if not _G.__YOLO__ then
		-- deviation: Since functions in lua _explicitly_ accept 'self' as a
		-- first argument when they use it, it becomes incorrect for us to call
		-- a function with a nil "context", where context in this case is
		-- analogous to the implicit `self` that we get with a `:` call
		if context == nil then
			ok, result = xpcall(func, describeError, ...)
		else
			ok, result = xpcall(func, describeError, context, ...)
		end
	else
		ok = true
		if context == nil then
			func(...)
		else
			func(context, ...)
		end
	end

	if not ok then
		-- deviation: functions have no notion of "this"/"self", so we expect
		-- the first argument to be the reporter itself, in conjunction with
		-- deviations in `ReactErrorUtils`
		reporter.onError(result)
	end
end

local invokeGuardedCallbackImpl = invokeGuardedCallbackProd

if _G.__DEV__ then
	-- In DEV mode, we swap out invokeGuardedCallback for a special version
	-- that plays more nicely with the browser's DevTools. The idea is to preserve
	-- "Pause on exceptions" behavior. Because React wraps all user-provided
	-- functions in invokeGuardedCallback, and the production version of
	-- invokeGuardedCallback uses a try-catch, all user exceptions are treated
	-- like caught exceptions, and the DevTools won't pause unless the developer
	-- takes the extra step of enabling pause on caught exceptions. This is
	-- unintuitive, though, because even though React has caught the error, from
	-- the developer's perspective, the error is uncaught.
	--
	-- To preserve the expected "Pause on exceptions" behavior, we don't use a
	-- try-catch in DEV. Instead, we synchronously dispatch a fake event to a fake
	-- DOM node, and call the user-provided callback from inside an event handler
	-- for that fake event. If the callback throws, the error is "captured" using
	-- a global event handler. But because the error happens in a different
	-- event loop context, it does not interrupt the normal program flow.
	-- Effectively, this gives us try-catch behavior without actually using
	-- try-catch. Neat!
	-- Check that the browser supports the APIs we need to implement our special
	-- DEV version of invokeGuardedCallback

	-- deviation: `window` is not defined in our environment
	-- deviation: FIXME: should we define our own impl for invokeGuardedCallbackDev?
	--[[
	if typeof window ~= 'undefined' and typeof window.dispatchEvent == 'function' and typeof document ~= 'undefined' and typeof document.createEvent == 'function' then
		local fakeNode = document.createElement('react')

		invokeGuardedCallbackImpl = function invokeGuardedCallbackDev(name, func, context, a, b, c, d, e, f) {
			-- If document doesn't exist we know for sure we will crash in this method
			-- when we call document.createEvent(). However this can cause confusing
			-- errors: https://github.com/facebookincubator/create-react-app/issues/3482
			-- So we preemptively throw with a better message instead.
			invariant(typeof document ~= 'undefined', 'The `document` global was defined when React was initialized, but is not ' + 'defined anymore. This can happen in a test environment if a component ' + 'schedules an update from an asynchronous callback, but the test has already ' + 'finished running. To solve this, you can either unmount the component at ' + 'the end of your test (and ensure that any asynchronous operations get ' + 'canceled in `componentWillUnmount`), or you can change the test itself ' + 'to be asynchronous.')
			local evt = document.createEvent('Event')
			local didCall = false; -- Keeps track of whether the user-provided callback threw an error. We
			-- set this to true at the beginning, then set it to false right after
			-- calling the function. If the function errors, `didError` will never be
			-- set to false. This strategy works even if the browser is flaky and
			-- fails to call our global error handler, because it doesn't rely on
			-- the error event at all.

			local didError = true; -- Keeps track of the value of window.event so that we can reset it
			-- during the callback to local user code access window.event in the
			-- browsers that support it.

			local windowEvent = window.event; -- Keeps track of the descriptor of window.event to restore it after event
			-- dispatching: https://github.com/facebook/react/issues/13688

			local windowEventDescriptor = Object.getOwnPropertyDescriptor(window, 'event')

			function restoreAfterDispatch() {
				-- We immediately remove the callback from event listeners so that
				-- nested `invokeGuardedCallback` calls do not clash. Otherwise, a
				-- nested call would trigger the fake event handlers of any call higher
				-- in the stack.
				fakeNode.removeEventListener(evtType, callCallback, false); -- We check for window.hasOwnProperty('event') to prevent the
				-- window.event assignment in both IE <= 10 as they throw an error
				-- "Member not found" in strict mode, and in Firefox which does not
				-- support window.event.

				if typeof window.event ~= 'undefined' and window.hasOwnProperty('event') then
					window.event = windowEvent
				}
			} -- Create an event handler for our fake event. We will synchronously
			-- dispatch our fake event using `dispatchEvent`. Inside the handler, we
			-- call the user-provided callback.


			local funcArgs = Array.prototype.slice.call(arguments, 3)

			function callCallback() {
				didCall = true
				restoreAfterDispatch()
				func.apply(context, funcArgs)
				didError = false
			} -- Create a global error event handler. We use this to capture the value
			-- that was thrown. It's possible that this error handler will fire more
			-- than once; for example, if non-React code also calls `dispatchEvent`
			-- and a handler for that event throws. We should be resilient to most of
			-- those cases. Even if our error event handler fires more than once, the
			-- last error event is always used. If the callback actually does error,
			-- we know that the last error event is the correct one, because it's not
			-- possible for anything else to have happened in between our callback
			-- erroring and the code that follows the `dispatchEvent` call below. If
			-- the callback doesn't error, but the error event was fired, we know to
			-- ignore it because `didError` will be false, as described above.


			local error; -- Use this to track whether the error event is ever called.

			local didSetError = false
			local isCrossOriginError = false

			function handleWindowError(event) {
				error = event.error
				didSetError = true

				if error == nil and event.colno == 0 and event.lineno == 0 then
					isCrossOriginError = true
				}

				if event.defaultPrevented then
					-- Some other error handler has prevented default.
					-- Browsers silence the error report if this happens.
					-- We'll remember this to later decide whether to log it or not.
					if error ~= nil and typeof error == 'object' then
						try {
							error._suppressLogging = true
						} catch (inner) {-- Ignore.
						}
					}
				}
			} -- Create a fake event type.


			local evtType = `react-${function () {
				if name then
					return name
				}

				return 'invokeguardedcallback'
			}()}`; -- Attach our event handlers

			window.addEventListener('error', handleWindowError)
			fakeNode.addEventListener(evtType, callCallback, false); -- Synchronously dispatch our fake event. If the user-provided function
			-- errors, it will trigger our global error handler.

			evt.initEvent(evtType, false, false)
			fakeNode.dispatchEvent(evt)

			if windowEventDescriptor then
				Object.defineProperty(window, 'event', windowEventDescriptor)
			}

			if didCall and didError then
				if !didSetError then
					-- The callback errored, but the error event never fired.
					error = new Error('An error was thrown inside one of your components, but React ' + "doesn't know what it was. This is likely due to browser " + 'flakiness. React does its best to preserve the "Pause on ' + 'exceptions" behavior of the DevTools, which requires some ' + "DEV-mode only tricks. It's possible that these don't work in " + 'your browser. Try triggering the error in production mode, ' + 'or switching to a modern browser. If you suspect that this is ' + 'actually an issue with React, please file an issue.')
				} else if isCrossOriginError then
					error = new Error("A cross-origin error was thrown. React doesn't have access to " + 'the actual error object in development. ' + 'See https://reactjs.org/link/crossorigin-error for more information.')
				}

				this.onError(error)
			} -- Remove our event listeners


			window.removeEventListener('error', handleWindowError)

			if !didCall then
				-- Something went really wrong, and our event was not dispatched.
				-- https://github.com/facebook/react/issues/16734
				-- https://github.com/facebook/react/issues/16585
				-- Fall back to the production implementation.
				restoreAfterDispatch()
				return invokeGuardedCallbackProd.apply(this, arguments)
			}
		}
	}
]]
end

return invokeGuardedCallbackImpl
