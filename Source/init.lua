-- // Services
local Players = game:GetService("Players")

-- // Dependencies
local Signal = require(script.Parent.Signal)

-- // Constants
local DEFAULT_CHAT_COMMANDS_PREFIX = "/"
local DEFAULT_CHAT_COMMANDS_SEPARATOR = ","
local DEFAULT_CHAT_COMMANDS_BIND = "&&"

local WHITESPACE_CHAR = "\32"

-- // Module
local ChatCommands = { }

ChatCommands.Bind = DEFAULT_CHAT_COMMANDS_BIND
ChatCommands.Separator = DEFAULT_CHAT_COMMANDS_SEPARATOR
ChatCommands.Prefix = DEFAULT_CHAT_COMMANDS_PREFIX

ChatCommands.Internal = { }
ChatCommands.Interface = { }
ChatCommands.Connections = { }

ChatCommands.Interface.Command = require(script.Command)

ChatCommands.Interface.CommandExecuted = Signal.new()

function ChatCommands.Internal:TrimWhitespace(object)
	while string.sub(object, 1, 1) == WHITESPACE_CHAR do
		object = string.sub(object, 2, #object)
	end

	while string.sub(object, -1, -1) == WHITESPACE_CHAR do
		object = string.sub(object, -#object, #object - 1)
	end

	return object
end

function ChatCommands.Internal:SplitMessageSource(message)
	local chainedCommands = string.split(message, ChatCommands.Bind)

	for command_index, command in chainedCommands do
		chainedCommands[command_index] = ChatCommands.Internal:TrimWhitespace(command)
	end

	for index, value in chainedCommands do
		if string.sub(value, 1, 1) ~= ChatCommands.Prefix then
			continue
		end

		local strippedCommand = string.sub(value, 2, #value)
		local commandSplit = string.split(strippedCommand, WHITESPACE_CHAR)

		local commandName = table.remove(commandSplit, 1)
		local commandArgs = string.split(table.concat(commandSplit, WHITESPACE_CHAR), ChatCommands.Separator)

		for argument_index, argument in commandArgs do
			commandArgs[argument_index] = ChatCommands.Internal:TrimWhitespace(argument)
		end

		chainedCommands[index] = { commandName, commandArgs }
	end

	return chainedCommands
end

function ChatCommands.Internal:OnMessageRecieved(player, message)
	local chainedCommands = ChatCommands.Internal:SplitMessageSource(message)

	for _, chatMessageInformation in chainedCommands do
		local commandName = chatMessageInformation[1]
		local commandArgs = chatMessageInformation[2]

		local commandObject = ChatCommands.Interface.Command.get(commandName)

		assert(commandObject ~= nil, `Failed to find the {commandName} command!`)

		if ChatCommands.Validation then
			if not ChatCommands.Validation(player, commandObject) then
				continue
			end
		end

		commandObject:Execute(player, table.unpack(commandArgs))

		ChatCommands.Interface.CommandExecuted:Fire(player, commandName, commandArgs)
	end
end

function ChatCommands.Internal:OnPlayerAdded(player)
	ChatCommands.Connections[player] = player.Chatted:Connect(function(message)
		ChatCommands.Internal:OnMessageRecieved(player, message)
	end)
end

function ChatCommands.Interface:SetValidatorCallback(callbackFn)
	ChatCommands.Validation = callbackFn
end

function ChatCommands.Interface:SetBind(newBind)
	ChatCommands.Bind = newBind
end

function ChatCommands.Interface:SetSeperator(newSeparator)
	ChatCommands.Separator = newSeparator
end

function ChatCommands.Interface:SetPrefix(newPrefix)
	ChatCommands.Prefix = newPrefix
end

function ChatCommands:Init()
	for _, player in Players:GetPlayers() do
		ChatCommands.Internal:OnPlayerAdded(player)
	end

	Players.PlayerAdded:Connect(function(player)
		ChatCommands.Internal:OnPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		if not ChatCommands.Connections[player] then
			return
		end

		ChatCommands.Connections[player]:Disconnect()
		ChatCommands.Connections[player] = nil
	end)

	return ChatCommands.Interface
end

return ChatCommands:Init()