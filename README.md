# ChatCommands

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChatCommands = require(ReplicatedStorage.Packages.ChatCommands)

ChatCommands.Command.new("Test", function(player, ...)
	warn("TestCommand Executed by:", player, "with arguments:", ...)
end)
	:SetDescription("Test Command!")
	:AddAlias("A")
```