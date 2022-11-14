#!/bin/bash

set -x

rotrieve install

echo "Remove .robloxrc from dependencies"
find Packages/_Index -name "*.robloxrc" | xargs rm -f

roblox-cli analyze tests.project.json
selene --version
selene --config selene.toml modules/
stylua --version
stylua -c modules bin
echo "Run tests in DEV"
roblox-cli run --load.model tests.project.json --run bin/spec.lua --fastFlags.overrides EnableLoadModule=true DebugDisableOptimizedBytecode=true --fastFlags.allOnLuau --lua.globals=__DEV__=true --lua.globals=__COMPAT_WARNINGS__=true
echo "Run tests in release"
roblox-cli run --load.model tests.project.json --run bin/spec.lua --fastFlags.overrides EnableLoadModule=true DebugDisableOptimizedBytecode=true --fastFlags.allOnLuau
