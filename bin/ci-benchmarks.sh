#!/bin/bash

set -x

rotrieve install
rojo build tests.project.json --output model.rbxm

echo "Remove .robloxrc from dependencies"
find Packages/_Index -name "*.robloxrc" | xargs rm -f

echo "Run static analysis"
roblox-cli analyze tests.project.json
selene --version
selene --config selene.toml modules/
stylua --version
stylua -c modules -g "*[a-bdh-km-oquvyz].lua"

echo "Run benchmarks"
robloxdev-cli run --load.model model.rbxm --run bin/run-first-render-benchmark.lua --fastFlags.allOnLuau --fastFlags.overrides EnableLoadModule=true EnableDelayedTaskMethods=true --headlessRenderer 1
robloxdev-cli run --load.model model.rbxm --run bin/run-frame-rate-benchmark.lua --fastFlags.allOnLuau --fastFlags.overrides EnableLoadModule=true EnableDelayedTaskMethods=true --headlessRenderer 1
robloxdev-cli run --load.model model.rbxm --run bin/run-deep-tree-benchmark.lua --fastFlags.allOnLuau --fastFlags.overrides EnableLoadModule=true EnableDelayedTaskMethods=true --headlessRenderer 1
robloxdev-cli run --load.model model.rbxm --run bin/run-wide-tree-benchmark.lua --fastFlags.allOnLuau --fastFlags.overrides EnableLoadModule=true EnableDelayedTaskMethods=true --headlessRenderer 1
robloxdev-cli run --load.model model.rbxm --run bin/run-sierpinski-triangle-benchmark.lua --fastFlags.allOnLuau --fastFlags.overrides EnableLoadModule=true EnableDelayedTaskMethods=true --headlessRenderer 1
