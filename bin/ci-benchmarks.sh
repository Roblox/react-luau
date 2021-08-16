#!/bin/bash

set -x

rotrieve install
rojo build tests.project.json --output model.rbxmx

echo "Remove .robloxrc from dependencies"
find Packages/_Index -name "*.robloxrc" | xargs rm -f

echo "Run static analysis"
roblox-cli analyze tests.project.json
selene --version
selene --config selene.toml modules/
stylua --version
stylua -c modules -g "*[a-bdh-km-oquvyz].lua"

echo "Run benchmarks"
roblox-cli run --load.model model.rbxmx --run bin/run-first-render-benchmark.lua --fastFlags.overrides EnableLoadModule=true --fastFlags.allOnLuau --headlessRenderer 1
roblox-cli run --load.model model.rbxmx --run bin/run-frame-rate-benchmark.lua --fastFlags.overrides EnableLoadModule=true --fastFlags.allOnLuau --headlessRenderer 1
roblox-cli run --load.model model.rbxmx --run bin/run-deep-tree-benchmark.lua --fastFlags.overrides EnableLoadModule=true --fastFlags.allOnLuau --headlessRenderer 1
roblox-cli run --load.model model.rbxmx --run bin/run-wide-tree-benchmark.lua --fastFlags.overrides EnableLoadModule=true --fastFlags.allOnLuau --headlessRenderer 1
roblox-cli run --load.model model.rbxmx --run bin/run-sierpinski-triangle-benchmark.lua --fastFlags.overrides EnableLoadModule=true --fastFlags.allOnLuau --headlessRenderer 1
