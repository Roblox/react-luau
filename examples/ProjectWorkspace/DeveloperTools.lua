local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- FIXME: This is a bit hacky; should rotriever provide a smoother way to access
-- dev dependencies?
-- return require(ReplicatedStorage.Packages._Index["DeveloperTools"]["developer-tools"])
return require(ReplicatedStorage.Packages._Index["DeveloperTools"]["DeveloperTools"])
