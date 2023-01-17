--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/8e5adfbd7e605bda9c5e96c10e015b3dc0df688e/packages/react-dom/src/client/ReactDOMComponent.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Packages = script.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Object = LuauPolyfill.Object

local RobloxComponentProps = require(script.Parent.roblox.RobloxComponentProps)

local ReactRobloxHostTypes = require(script.Parent["ReactRobloxHostTypes.roblox"])
type HostInstance = ReactRobloxHostTypes.HostInstance

-- deviation: Essentially a placeholder for dom-specific logic, taking the place
-- of ReactDOMComponent. Most of the logic will differ pretty dramatically

type Array<T> = { [number]: T }
type Object = { [any]: any }

local exports: { [string]: any } = {}

exports.setInitialProperties = RobloxComponentProps.setInitialProperties

-- Calculate the diff between the two objects.
local function diffProperties(
	domElement: HostInstance,
	tag: string,
	lastRawProps: Object,
	nextRawProps: Object,
	rootContainerElement: HostInstance
): (nil | Array<any>)
	-- if _G.__DEV__ then
	--   validatePropertiesInDevelopment(tag, nextRawProps)
	-- end

	-- ROBLOX FIXME: Type refinement
	-- local updatePayload: nil | Array<any> = nil
	local updatePayload = nil

	local lastProps = lastRawProps
	local nextProps = nextRawProps
	-- local lastProps: Object
	-- local nextProps: Object
	-- switch (tag) {
	--   case 'input':
	--     lastProps = ReactDOMInputGetHostProps(domElement, lastRawProps);
	--     nextProps = ReactDOMInputGetHostProps(domElement, nextRawProps);
	--     updatePayload = [];
	--     break;
	--   case 'option':
	--     lastProps = ReactDOMOptionGetHostProps(domElement, lastRawProps);
	--     nextProps = ReactDOMOptionGetHostProps(domElement, nextRawProps);
	--     updatePayload = [];
	--     break;
	--   case 'select':
	--     lastProps = ReactDOMSelectGetHostProps(domElement, lastRawProps);
	--     nextProps = ReactDOMSelectGetHostProps(domElement, nextRawProps);
	--     updatePayload = [];
	--     break;
	--   case 'textarea':
	--     lastProps = ReactDOMTextareaGetHostProps(domElement, lastRawProps);
	--     nextProps = ReactDOMTextareaGetHostProps(domElement, nextRawProps);
	--     updatePayload = [];
	--     break;
	--   default:
	--     lastProps = lastRawProps;
	--     nextProps = nextRawProps;
	--     if (
	--       typeof lastProps.onClick !== 'function' &&
	--       typeof nextProps.onClick === 'function'
	--     ) {
	--       // TODO: This cast may not be sound for SVG, MathML or custom elements.
	--       trapClickOnNonInteractiveElement(((domElement: any): HTMLElement));
	--     }
	--     break;
	-- }

	-- assertValidProps(tag, nextProps);

	-- let propKey;
	-- let styleName;
	-- let styleUpdates = null;
	for propKey, _ in lastProps do
		if nextProps[propKey] ~= nil then
			continue
		end
		-- if (propKey === STYLE) {
		--   const lastStyle = lastProps[propKey];
		--   for (styleName in lastStyle) {
		--     if (lastStyle.hasOwnProperty(styleName)) {
		--       if (!styleUpdates) {
		--         styleUpdates = {};
		--       }
		--       styleUpdates[styleName] = '';
		--     }
		--   }
		-- } else if (propKey === DANGEROUSLY_SET_INNER_HTML || propKey === CHILDREN) {
		--   // Noop. This is handled by the clear text mechanism.
		-- } else if (
		--   propKey === SUPPRESS_CONTENT_EDITABLE_WARNING ||
		--   propKey === SUPPRESS_HYDRATION_WARNING
		-- ) {
		--   // Noop
		-- } else if (propKey === AUTOFOCUS) {
		--   // Noop. It doesn't work on updates anyway.
		-- } else if (registrationNameDependencies.hasOwnProperty(propKey)) {
		--   // This is a special case. If any listener updates we need to ensure
		--   // that the "current" fiber pointer gets updated so we need a commit
		--   // to update this element.
		--   if (!updatePayload) {
		--     updatePayload = [];
		--   }
		-- } else {
		-- For all other deleted properties we add it to the queue. We use
		-- the allowed property list in the commit phase instead.
		-- ROBLOX performance: prealloc table size 2 for these 2 items at least
		updatePayload = updatePayload or table.create(2)
		table.insert(updatePayload, propKey)
		table.insert(updatePayload, Object.None)
		-- }
	end
	for propKey, nextProp in nextProps do
		local lastProp = if lastProps ~= nil then lastProps[propKey] else nil
		if nextProp == lastProp then
			continue
		end
		-- if (propKey === STYLE) {
		--   if (__DEV__) {
		--     if (nextProp) {
		--       // Freeze the next style object so that we can assume it won't be
		--       // mutated. We have already warned for this in the past.
		--       Object.freeze(nextProp);
		--     }
		--   }
		--   if (lastProp) {
		--     // Unset styles on `lastProp` but not on `nextProp`.
		--     for (styleName in lastProp) {
		--       if (
		--         lastProp.hasOwnProperty(styleName) &&
		--         (!nextProp || !nextProp.hasOwnProperty(styleName))
		--       ) {
		--         if (!styleUpdates) {
		--           styleUpdates = {};
		--         }
		--         styleUpdates[styleName] = '';
		--       }
		--     }
		--     // Update styles that changed since `lastProp`.
		--     for (styleName in nextProp) {
		--       if (
		--         nextProp.hasOwnProperty(styleName) &&
		--         lastProp[styleName] !== nextProp[styleName]
		--       ) {
		--         if (!styleUpdates) {
		--           styleUpdates = {};
		--         }
		--         styleUpdates[styleName] = nextProp[styleName];
		--       }
		--     }
		--   } else {
		--     // Relies on `updateStylesByID` not mutating `styleUpdates`.
		--     if (!styleUpdates) {
		--       if (!updatePayload) {
		--         updatePayload = [];
		--       }
		--       updatePayload.push(propKey, styleUpdates);
		--     }
		--     styleUpdates = nextProp;
		--   }
		-- } else if (propKey === DANGEROUSLY_SET_INNER_HTML) {
		--   const nextHtml = nextProp ? nextProp[HTML] : undefined;
		--   const lastHtml = lastProp ? lastProp[HTML] : undefined;
		--   if (nextHtml != null) {
		--     if (lastHtml !== nextHtml) {
		--       (updatePayload = updatePayload || []).push(propKey, nextHtml);
		--     }
		--   } else {
		--     // TODO: It might be too late to clear this if we have children
		--     // inserted already.
		--   }
		-- } else if (propKey === CHILDREN) {
		--   if (typeof nextProp === 'string' || typeof nextProp === 'number') {
		--     (updatePayload = updatePayload || []).push(propKey, '' + nextProp);
		--   }
		-- } else if (
		--   propKey === SUPPRESS_CONTENT_EDITABLE_WARNING ||
		--   propKey === SUPPRESS_HYDRATION_WARNING
		-- ) {
		--   // Noop
		-- } else if (registrationNameDependencies.hasOwnProperty(propKey)) {
		--   if (nextProp != null) {
		--     // We eagerly listen to this even though we haven't committed yet.
		--     if (__DEV__ && typeof nextProp !== 'function') {
		--       warnForInvalidEventListener(propKey, nextProp);
		--     }
		--     if (!enableEagerRootListeners) {
		--       ensureListeningTo(rootContainerElement, propKey, domElement);
		--     } else if (propKey === 'onScroll') {
		--       listenToNonDelegatedEvent('scroll', domElement);
		--     }
		--   }
		--   if (!updatePayload && lastProp !== nextProp) {
		--     // This is a special case. If any listener updates we need to ensure
		--     // that the "current" props pointer gets updated so we need a commit
		--     // to update this element.
		--     updatePayload = [];
		--   }
		-- } else if (
		--   typeof nextProp === 'object' &&
		--   nextProp !== null &&
		--   nextProp.$$typeof === REACT_OPAQUE_ID_TYPE
		-- ) {
		--   // If we encounter useOpaqueReference's opaque object, this means we are hydrating.
		--   // In this case, call the opaque object's toString function which generates a new client
		--   // ID so client and server IDs match and throws to rerender.
		--   nextProp.toString();
		-- } else {
		-- For any other property we always add it to the queue and then we
		-- filter it out using the allowed property list during the commit.
		-- ROBLOX performance: prealloc table size 2 for these 2 items at least
		-- ROBLOX performance TODO: don't create a table here, return multiple values!
		updatePayload = updatePayload or table.create(2)
		table.insert(updatePayload, propKey)
		table.insert(updatePayload, nextProp)
		-- }
	end
	-- if (styleUpdates) {
	--   if (__DEV__) {
	--     validateShorthandPropertyCollisionInDev(styleUpdates, nextProps[STYLE]);
	--   }
	--   (updatePayload = updatePayload || []).push(STYLE, styleUpdates);
	-- }
	return updatePayload
end
exports.diffProperties = diffProperties
exports.updateProperties = RobloxComponentProps.updateProperties
exports.cleanupHostComponent = RobloxComponentProps.cleanupHostComponent

return exports
