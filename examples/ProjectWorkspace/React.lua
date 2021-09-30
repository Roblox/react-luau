local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = ReplicatedStorage.Packages._Workspace

-- FIXME: This is a bit hacky; should rotriever provide a smoother way to access
-- local workspace members, even if they don't see use?
return require(Workspace.React.React)
