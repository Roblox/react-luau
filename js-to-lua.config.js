module.exports = {
    lastSync: {
        ref: "12adaffef7105e2714f82651ea51936c563fe15c",
        conversionToolVersion: "ffc56d3952bd9ce9ccecc900f6632b0a1c08f222"
    },
    upstream: {
        owner: "facebook",
        repo: "react",
        primaryBranch: "main"
    },
    downstream: {
        owner: "roblox",
        repo: "roact-alignment",
        primaryBranch: "master",
        patterns: [
            "**/*.lua"
        ],
        ignorePatterns: [
            "Packages/**/*"
        ]
    },
    renameFiles: [
        [
            (filename) => filename.includes("packages/"),
            (filename) => filename.replace("packages/", "modules/")

        ],
        [
            (filename) => filename.includes("modules/shared") && !filename.includes("modules/shared/src"),
            (filename) => filename.replace("modules/shared", "modules/shared/src")

        ],
        [
            (filename) => filename.includes("modules/react/src/ReactSharedInternals.lua"),
            (filename) => filename.replace("modules/react/src/ReactSharedInternals.lua", "modules/shared/src/ReactSharedInternals/init.lua")
        ],
        [
            (filename) => filename.includes("modules/react/src/ReactCurrentDispatcher.lua") || filename.includes("modules/react/src/ReactCurrentBatchConfig.lua") || filename.includes("modules/react/src/ReactCurrentActQueue.lua") || filename.includes("modules/react/src/ReactCurrentOwner.lua") || filename.includes("modules/react/src/ReactDebugCurrentFrame.lua"),
            (filename) => filename.replace("modules/react/src/", "modules/shared/src/ReactSharedInternals/")
        ],
        [
            (filename) => filename.includes("modules/react-reconciler/src/ReactFiberHostConfigWithNoHydration.lua"),
            (filename) => filename.replace("modules/react-reconciler/src/ReactFiberHostConfigWithNoHydration.lua", "modules/shared/src/ReactFiberHostConfig/WithNoHydration.lua")
        ],
        [
            (filename) => filename.includes("modules/react-reconciler/src/ReactFiberHostConfigWithNoPersistence.lua"),
            (filename) => filename.replace("modules/react-reconciler/src/ReactFiberHostConfigWithNoPersistence.lua", "modules/shared/src/ReactFiberHostConfig/WithNoPersistence.lua")
        ],
        [
            (filename) => filename.includes("modules/react-reconciler/src/ReactFiberHostConfigWithNoTestSelectors.lua"),
            (filename) => filename.replace("modules/react-reconciler/src/ReactFiberHostConfigWithNoTestSelectors.lua", "modules/shared/src/ReactFiberHostConfig/WithNoTestSelectors.lua")
        ],
        [
            (filename) => filename.includes("__tests__/") && !filename.includes("src/__tests__/") && !filename.includes("PropMarkers/__tests__/") && !filename.includes("client/__tests__/"),
            (filename) => filename.replace("__tests__/", "src/__tests__/")
        ],
        [
            (filename) => filename.endsWith("-test.lua"),
            (filename) => filename.replace("-test.lua", ".spec.lua")

        ],
        [
            (filename) => filename.endsWith("-test.internal.lua"),
            (filename) => filename.replace("-test.internal.lua", "-internal.spec.lua")

        ],
        [
            (filename) => filename.includes("scripts/jest/matchers"),
            (filename) => filename.replace("scripts/jest/matchers", "WorkspaceStatic/jest/matchers")
        ],
        [
            (filename) => filename.endsWith("fixtures/legacy-jsx-runtimes/setupTests.lua"),
            (filename) => filename.replace("fixtures/legacy-jsx-runtimes/setupTests.lua", "WorkspaceStatic/jest/matchers/createConsoleMatcher.lua")
        ],
    ],
}
