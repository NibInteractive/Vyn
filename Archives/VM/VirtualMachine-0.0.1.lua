local VM = {}

function VM.Run(Bytecode)
	local Stack = {}
	local Environment = { [{}] = true }
	Environment = { {} }

	local function GetVariable(Name)
		for i = #Environment, 1, -1 do
			local Env = Environment[i]
			if Env ~= nil then return Env[Name] end
			error("Runtime Error: Variable '"..Name.."' not defined")
		end
	end

	local function SetVariable(Name, Value)
		for i = #Environment, 1, -1 do
			local Env = Environment[i]
			if Env ~= nil then
				Env[Name] = Value
				return
			end
			
			Environment[#Environment][Name] = Value
		end
	end

	GetVariable()
	SetVariable()

	local function ExecuteInstruction(instr)
		if instr.op == "LOAD_CONST" then
			table.insert(Stack, instr.arg)
		elseif instr.op == "LOAD_VAR" then
			local Value = Environment[instr.Name]
			if Value == nil then error("Runtime Error: Variable '"..instr.Name.."' not defined") end

			table.insert(Stack, Value)
		elseif instr.op == "STORE_VAR" then
			local value = table.remove(Stack)
			Environment[instr.Name] = value
		elseif instr.op == "ADD" then
			local b = table.remove(Stack)
			local a = table.remove(Stack)
			table.insert(Stack, a + b)
		elseif instr.op == "SUB" then
			local b = table.remove(Stack)
			local a = table.remove(Stack)
			table.insert(Stack, a - b)
		elseif instr.op == "MULT" then
			local b = table.remove(Stack)
			local a = table.remove(Stack)
			table.insert(Stack, a * b)
		elseif instr.op == "DIV" then
			local b = table.remove(Stack)
			local a = table.remove(Stack)
			table.insert(Stack, a / b)
		elseif instr.op == "PRINT" then
			local value = Stack[#Stack]
			print(value)
			table.remove(Stack)
		elseif instr.op == "BLOCK" then
			for _, stmt in ipairs(instr.Body or instr.body or {}) do
				ExecuteInstruction(stmt)
			end
		else
			error("Unknown instruction: " .. tostring(instr.op))
		end
	end

	for _, Instruction in ipairs(Bytecode) do
			ExecuteInstruction(Instruction)
	end
end

return VM
