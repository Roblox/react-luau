-- ROBLOX note: upstream doesn't have a root index.js, we may want to contribute a proper contract upstream
return {
	backend = require(script.backend),
	bridge = require(script.bridge),
	devtools = require(script.devtools),
	hydration = require(script.hydration),
	hook = require(script.hook),
	utils = require(script.utils),
}
