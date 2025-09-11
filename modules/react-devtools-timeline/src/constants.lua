-- ROBLOX upstream: https://github.com/facebook/react/blob/v19.1.1/packages/react-devtools-timeline/src/constants.js

local Constants = {}

local REACT_TOTAL_NUM_LANES = 31
Constants.REACT_TOTAL_NUM_LANES = REACT_TOTAL_NUM_LANES

-- Increment this number any time a backwards breaking change is made to the profiler metadata.
local SCHEDULING_PROFILER_VERSION = 1
Constants.SCHEDULING_PROFILER_VERSION = SCHEDULING_PROFILER_VERSION

return table.freeze(Constants)
