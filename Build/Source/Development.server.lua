local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChatCommands = require(ReplicatedStorage.Packages.ChatCommands)

ChatCommands.Command.new("Test", function(player, ...)
	warn(player, ...)
end)
	:SetDescription("Test Command!")
	:AddAlias("A")