local Compiler = {}

local function CompileExpression(Node, Bytecode)
	if Node.Type == "NUMBER" then
		table.insert(Bytecode, { op = "LOAD_CONST", arg = Node.Value })
	elseif Node.Type == "VAR" then
		table.insert(Bytecode, { op = "LOAD_VAR", Name = Node.Name })
	elseif Node.op then
		-- Binary operation (PLUS, MINUS, MULT, DIV)
		CompileExpression(Node.Left, Bytecode)
		CompileExpression(Node.Right, Bytecode)

		if Node.op == "PLUS" then
			table.insert(Bytecode, { op = "ADD" })
		elseif Node.op == "MINUS" then
			table.insert(Bytecode, { op = "SUB" })
		elseif Node.op == "MULT" then
			table.insert(Bytecode, { op = "MULT" })
		elseif Node.op == "DIV" then
			table.insert(Bytecode, { op = "DIV" })
		else
			error("Unknown operation: " .. tostring(Node.op))
		end
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
