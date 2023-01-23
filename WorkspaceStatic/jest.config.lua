local Workspace = script.Parent

-- In case we need to specify a custom testSetupFile for a project, we need to do that in in a separate jest.config.lua file that's in the project's root folder.
-- Therefore we specify the project here and provide it to the "projects" field in this config file.
-- We also need to add the project to the "testPathIgnorePatterns" field so that Jest doesn't try to run the project's tests again.
local projectsWithCustomJestConfig = {
	Workspace.ReactDevtoolsShared.ReactDevtoolsShared,
}
local testPathIgnorePatterns = {}
local allProjects = { Workspace }

for _, project in projectsWithCustomJestConfig do
	table.insert(testPathIgnorePatterns, project)
	table.insert(allProjects, project)
end

return {
	setupFilesAfterEnv = { Workspace.jest.testSetupFile },
	projects = allProjects,
	testMatch = {
		"**/__tests__/*.(spec|test)",
	},
	testPathIgnorePatterns = testPathIgnorePatterns,
}
