-- VM.lua
local VM = {}

function VM.Run(Bytecode)
	local Stack = {}
	local Environment = { { Type = "GLOBAL", Variables = {} } }

	local function PushEnvironment(EnvironmentType)
        table.insert(Environment, { Type = EnvironmentType, Variables = {} })
    end

    local function PopEnvironment()
        table.remove(Environment)
    end

	local function GetVariable(Name)
		for i = #Environment, 1, -1 do
			local ENV = Environment[i]

			if ENV.Variables[Name] ~= nil then
				return ENV.Variables[Name]
			end
		end

		error("Runtime Error: Variable '"..Name.."' not defined")
	end

	local function SetVariable(Name, Value, Scope)
		for i = #Environment, 1, -1 do
			local ENV = Environment[i]

			if ENV.Variables[Name] ~= nil then
				ENV.Variables[Name] = Value
				return
			end
		end

		Environment[#Environment].Variables[Name] = Value
	end

	local function DeclareVariable(Name, Value, Scope)
		if Scope == "PRIVATE" then
			Environment[#Environment].Variables[Name] = Value
			return
		elseif Scope == "LOCAL" then
			for i = #Environment, 1, -1 do
				local ENV = Environment[i]

                if ENV.Type ~= "PRIVATE" then
                    ENV.Variables[Name] = Value
                    return
                end

				-- Global Fallback --
				Environment[1].Variables[Name] = Value
            	return
            end
		else
			Environment[#Environment].Variables[Name] = Value
			return
		end
	end

	local function ExecuteInstruction(instr)
		if instr.op == "LOAD_CONST" then
			table.insert(Stack, instr.arg)
		elseif instr.op == "LOAD_VAR" then
			table.insert(Stack, GetVariable(instr.Name))
		elseif instr.op == "STORE_VAR" then
			local Value = table.remove(Stack)
			SetVariable(instr.Name, Value)
		elseif instr.op == "DECLARE_VAR" then
			local Value = table.remove(Stack)
			DeclareVariable(instr.Name, Value, instr.Scope)
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
			local Value = Stack[#Stack]
			print(Value)
			table.remove(Stack)
		elseif instr.op == "BLOCK_START" then
            PushEnvironment("PRIVATE")
        elseif instr.op == "BLOCK_END" then
            PopEnvironment()
		else
			error("Unknown instruction: " .. tostring(instr.op))
		end
	end

	for _, Instruction in ipairs(Bytecode) do
		ExecuteInstruction(Instruction)
	end
end

return VM
