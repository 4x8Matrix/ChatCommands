-- // External Imports
local Signal = require(script.Parent.Parent.Signal)

-- // Module
local Command = { }

Command.Type = "Command"

Command.Interface = { }
Command.Instances = { }
Command.Aliases = { }
Command.Prototype = { }

Command.Interface.CommandAdded = Signal.new()
Command.Interface.CommandRemoved = Signal.new()

-- // Prototype functions
function Command.Prototype:SetDescription(description)
	self._description = description

	return self
end

function Command.Prototype:AddArgument(argument)
	table.insert(self._arguments, argument)

	return self
end

function Command.Prototype:RemoveArgument(argument)
	local argumentIndex = table.find(self._arguments, argument)

	if argumentIndex then
		table.remove(self._arguments, argumentIndex)
	end

	return self
end

function Command.Prototype:AddAlias(alias)
	alias = string.lower(alias)

	Command.Aliases[alias] = self
	table.insert(self._aliases, alias)

	return self
end

function Command.Prototype:RemoveAlias(alias)
	alias = string.lower(alias)

	Command.Aliases[alias] = nil

	local aliasIndex = table.find(self._aliases, alias)

	if aliasIndex then
		table.remove(self._aliases, alias)
	end

	return self
end

function Command.Prototype:GetInformation()
	return {
		Description = self._description,
		Arguments = self._arguments,
		Command = self.command
	}
end

function Command.Prototype:Execute(...)
	return self._callbackFn(...)
end

function Command.Prototype:ToString()
	return `{Command.Type}<"{self.command}">`
end

function Command.Prototype:Destroy()
	for _, alias in self._aliases do
		Command.Aliases[alias] = nil
	end

	Command.Instances[self.command] = nil
	Command.Interface.CommandRemoved:Fire(self.command)
end

-- // Module functions
function Command.Interface.new(commandName, callbackFn)
	commandName = string.lower(commandName)

	local commandObject = setmetatable({
		command = commandName,

		_callbackFn = callbackFn,
		_arguments = { },
		_description = "",
		_aliases = { }
	}, {
		__index = Command.Prototype,
		__type = Command.Type,

		__tostring = function(object)
			return object:ToString()
		end
	})

	Command.Interface.CommandAdded:Fire(commandName)

	Command.Instances[commandName] = commandObject
	return Command.Instances[commandName]
end

function Command.Interface.get(commandName)
	commandName = string.lower(commandName)

	return Command.Instances[commandName] or Command.Aliases[commandName]
end

function Command.Interface.is(object)
	if not object or type(object) ~= "table" then
		return false
	end

	local metatable = getmetatable(object)

	return metatable and metatable.__type == Command.Type
end

return Command.Interface