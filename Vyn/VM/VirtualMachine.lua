local VM = {}

function VM.Run(Bytecode)
	local Stack = {}
	local Environment = { { Variables = {}, Privates = {} } }

	local function PushEnvironment()
        table.insert(Environment, { Variables = {}, Privates = {} })
    end

    local function PopEnvironment()
		local CurrentEnvironment = Environment[#Environment]
		CurrentEnvironment.Privates = {}
		
		for i = #Environment - 1, 1, -1 do
			for Name in pairs(Environment[i].Privates) do
				Environment[i].Privates[Name] = nil
			end
		end

        table.remove(Environment)
    end

	local function GetVariable(Name)
		for i = #Environment, 1, -1 do
			local ENV = Environment[i]

			if ENV.Variables[Name] ~= nil then
				return ENV.Variables[Name]
			end

			if ENV.Privates[Name] ~= nil then
				if i == #Environment then
					return ENV.Privates[Name]
				else
					break
				end
			end
		end

		error("Runtime Error: Variable '"..Name.."' not defined")
	end

	local function SetVariable(Name, Value)
		for i = #Environment, 1, -1 do
			local ENV = Environment[i]

			if ENV.Variables[Name] ~= nil then
				ENV.Variables[Name] = Value
				return
			end

			if ENV.Privates[Name] ~= nil and i == #Environment then
				ENV.Privates[Name] = Value
				return
			end
		end

		Environment[#Environment].Variables[Name] = Value
	end

	local function DeclareVariable(Name, Value, Scope)
        local ENV = Environment[#Environment]

		if Scope == "PRIVATE" then
			ENV.Privates[Name] = Value
		elseif Scope == "LOCAL" then
			ENV.Variables[Name] = Value

			--[[for i = #Environment, 1, -1 do
				local Target = Environment[i]

				if Target then
					Target.Variables[Name] = Value
					return
				end
			end]]
		else
			Environment[1].Variables[Name] = Value
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
            PushEnvironment()
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

