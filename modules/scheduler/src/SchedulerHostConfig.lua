--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/00748c53e183952696157088a858352cc77b0010/packages/scheduler/src/SchedulerHostConfig.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
* @flow
]]

-- deviation: In React, this module throws an error and is expected to be
-- replaced via a bundler. In our case, we mock it explicitly when we need to
-- mock it, and return the "default" here
return require(script.Parent.forks["SchedulerHostConfig.default"])
