--!strict
-- ROBLOX deviation: Initializes the reconciler with this package's host
-- config and returns the resulting module

local Packages = script.Parent.Parent
local initializeReconciler = require(Packages.ReactReconciler)

local ReactRobloxHostConfig = require(script.Parent.client.ReactRobloxHostConfig)

return initializeReconciler(ReactRobloxHostConfig)
