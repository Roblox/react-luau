#!/bin/bash

set -x

rotrieve install

echo "Remove .robloxrc from dependencies"
find Packages/_Index -name "*.robloxrc" | xargs rm -f

echo "Run static analysis"
roblox-cli analyze --project tests.project.json
selene --version
selene --config selene.toml modules/ WorkspaceStatic/
stylua --version
stylua -c modules bin WorkspaceStatic

echo "Run tests in DEV"
robloxdev-cli run --load.model tests.project.json \
  --run bin/spec.lua \
  --fastFlags.allOnLuau --fastFlags.overrides UseDateTimeType3=true EnableLoadModule=true DebugDisableOptimizedBytecode=true EnableDelayedTaskMethods=true MaxDeferReentrancyDepth=65 \
  --load.asRobloxScript --headlessRenderer 1 --virtualInput 1 --fs.readwrite=$PWD --lua.globals=__COMPAT_WARNINGS__=true \
  --lua.globals=UPDATESNAPSHOT=false --lua.globals=CI=true --lua.globals=__ROACT_17_MOCK_SCHEDULER__=true \
  --lua.globals=__DEV__=true

echo "Run tests in release"
robloxdev-cli run --load.model tests.project.json \
  --run bin/spec.lua \
  --fastFlags.allOnLuau --fastFlags.overrides UseDateTimeType3=true EnableLoadModule=true DebugDisableOptimizedBytecode=true EnableDelayedTaskMethods=true MaxDeferReentrancyDepth=65 \
  --load.asRobloxScript --headlessRenderer 1 --virtualInput 1 --fs.readwrite=$PWD \
  --lua.globals=UPDATESNAPSHOT=false --lua.globals=CI=true --lua.globals=__ROACT_17_MOCK_SCHEDULER__=true
