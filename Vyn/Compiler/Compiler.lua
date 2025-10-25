local Logger = require("Vyn.utils.Logger")

local Compiler = {}

local Ops = {
	PLUS = "ADD",
	MINUS = "SUB",
	MULT = "MULT",
	DIV = "DIV",
	GT = "COMPARE_GT",
	LT = "COMPARE_LT",
	GTEQ = "COMPARE_GTEQ",
	LTEQ = "COMPARE_LTEQ",
	EQ = "COMPARE_EQ",
	NEQ = "COMPARE_NEQ",
}

local function CompileExpression(Node, Bytecode)
	if not Node then Logger.Error("Compiler", "CompileExpression: nil node") end

	if Node.Type == "NUMBER" then
		table.insert(Bytecode, { op = "LOAD_CONST", arg = Node.Value })
	elseif Node.Type == "VAR" then
		table.insert(Bytecode, { op = "LOAD_VAR", Name = Node.Name })
	elseif Node.Type == "CALL" then
		for _, Argument in ipairs(Node.args or {}) do
			CompileExpression(Argument, Bytecode)
		end

		table.insert(Bytecode, { op = "CALL_FUNCTION", Name = Node.Name, ArgCount = # (Node.args or {}) })
	elseif Node.op then
		-- Binary operation (PLUS, MINUS, MULT, DIV)
		CompileExpression(Node.Left, Bytecode)
		CompileExpression(Node.Right, Bytecode)

		table.insert(Bytecode, { op = Ops[Node.op] or error("Unknown operation: " .. tostring(Node.op)) })
	else
		error("Unknown Node Type in compilation")
	end
end

local function CompileStatement(Node, Bytecode)
	if Node.op == "PRINT" then
		CompileExpression(Node.args[1], Bytecode)
		table.insert(Bytecode, { op = "PRINT" })
	elseif Node.op == "ASSIGN" then
		CompileExpression(Node.Value, Bytecode)
		table.insert(Bytecode, { op = "STORE_VAR", Name = Node.Name })
	elseif Node.op == "DECLARE" then
		CompileExpression(Node.Value, Bytecode)
		table.insert(Bytecode, { op = "DECLARE_VAR", Name = Node.Name, Scope = Node.Scope })
	elseif Node.op == "BLOCK" then
		table.insert(Bytecode, { op = "BLOCK_START" })

        for _, stmt in ipairs(Node.Body) do
            CompileStatement(stmt, Bytecode)
        end
		
        table.insert(Bytecode, { op = "BLOCK_END" })
	elseif Node.op == "IF" then
		CompileExpression(Node.Condition, Bytecode)
		
    	local JumpOverIfChainIndex = nil
    	local JumpIfFalseIndex = #Bytecode + 1
        table.insert(Bytecode, { op = "JUMP_IF_FALSE", Target = nil }) -- Todo: Fix later

        for _, stmt in ipairs(Node.Body) do
            CompileStatement(stmt, Bytecode)
        end

		if Node.ElseBody and #Node.ElseBody > 0 then
			JumpOverIfChainIndex = #Bytecode + 1
			table.insert(Bytecode, { op = "JUMP", Target = nil })
		end

    	Bytecode[JumpIfFalseIndex].Target = #Bytecode + 1

		if Node.ElseBody and #Node.ElseBody > 0 then
			for _, ElseNode in ipairs(Node.ElseBody) do
				if ElseNode.op == "IF" then
					CompileStatement(ElseNode, Bytecode)
				else
					CompileStatement(ElseNode, Bytecode)
				end
			end
			
			Bytecode[JumpOverIfChainIndex].Target = #Bytecode + 1
		end
	elseif Node.op == "FUNCTION" then
		local FunctionBytecode = {}

		for _, stmt in ipairs(Node.Body) do
			CompileStatement(stmt, FunctionBytecode)
		end
		
		table.insert(FunctionBytecode, { op = "RETURN" })
		table.insert(Bytecode, { op = "FUNCTION_DECL", Name = Node.Name, Params = Node.Params, Body = FunctionBytecode })
	elseif Node.op == "RETURN" then
		if Node.Value then
			CompileExpression(Node.Value, Bytecode)
		else
			table.insert(Bytecode, { op = "LOAD_CONST", arg = nil })
		end

		table.insert(Bytecode, { op = "RETURN"})
	else
		error("Unknown statement: "..tostring(Node.op))
	end
end

-- Convert AST to Bytecode
function Compiler.Compile(AST)
	local Bytecode = {}
	
	for _, Node in ipairs(AST) do
		CompileStatement(Node, Bytecode)
	end

	return Bytecode
end

return Compiler
