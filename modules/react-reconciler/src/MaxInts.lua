--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/c5d2fc7127654e43de59fff865b74765a103c4a5/packages/react-reconciler/src/MaxInts.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

-- // Max 31 bit integer. The max integer size in V8 for 32-bit systems.
-- // Math.pow(2, 30) - 1
-- // 0b111111111111111111111111111111
return { MAX_SIGNED_31_BIT_INT = 1073741823 }
