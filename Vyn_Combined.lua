package.preload["Vyn.Runner"] = function() local Lexer = require("Vyn.Lexer.Lexer")
local Parser = require("Vyn.Parser.Parser")
local Compiler = require("Vyn.Compiler.Compiler")
local VM = require("Vyn.VM.VirtualMachine")

local Runner = {}

-- Colored Output helpers
local Colors = {
	Reset = "\27[0m",
	Red = "\27[31m",
	Green = "\27[32m",
	Yellow = "\27[33m",
	Cyan = "\27[36m",
}

local function ColorPrint(Text, Color)
	print(Color .. Text .. Colors.Reset)
end

-- cross-platform Sleep
local function Sleep(sec)
	if package.config:sub(1, 1) == "\\" then
		os.execute("ping -n " .. tonumber(sec + 1) .. " 127.0.0.1 > NUL")
	else
		os.execute("Sleep " .. sec)
	end
end

-- cross-platform list directory
local function ListDirectory(Path)
	local Files = {}
	local Command
	if package.config:sub(1, 1) == "\\" then
		Command = 'dir "' .. Path .. '" /b'
	else
		Command = 'ls -1 "' .. Path .. '"'
	end
	local p = io.popen(Command)
	if not p then return Files end
	for File in p:lines() do
		table.insert(Files, File)
	end
	p:close()
	return Files
end

-- get last modified time (best effort)
local function GetModTime(Path)
	local Command

	if package.config:sub(1, 1) == "\\" then
		Command = 'for %I in ("' .. Path .. '") do @echo %~tI'
	else
		Command = 'stat -c %Y "' .. Path .. '" 2>/dev/null'
	end

	local p = io.popen(Command)
	if not p then return 0 end

	local Output = p:read("*a")
	p:close()

	return tonumber(Output) or os.time()
end

function Runner.RunSource(Source, Name, Verbose)
	local ok, err = pcall(function()
		local tokens = Lexer.Tokenize(Source)

		if Verbose then
			ColorPrint("Tokens:", Colors.Cyan)

			for _, t in ipairs(tokens) do
				print(t.Type, t.Value)
			end
		end

		local AST = Parser.Parse(tokens)

		if Verbose then
			ColorPrint("AST:", Colors.Cyan)
			for _, node in ipairs(AST) do
				print(node.op, node.args and node.args[1].Value or "")
			end
		end

		local Bytecode = Compiler.Compile(AST)

		if Verbose then
			ColorPrint("Bytecode:", Colors.Cyan)
			for _, instr in ipairs(Bytecode) do
				print(instr.op, instr.arg or instr.Name or "")
			end
		end

		VM.Run(Bytecode)
	end)

	if not ok then
		ColorPrint(("Error in '%s': %s"):format(Name or "<unknown>", err), Colors.Red)
	else
		ColorPrint(("Finished running: %s"):format(Name or "<unknown>"), Colors.Green)
	end
end

function Runner.RunFile(Path, Verbose)
	local f = io.open(Path, "r")
	assert(f, "Cannot open File: " .. Path)
	local Source = f:read("*a")
	f:close()

	Runner.RunSource(Source, Path, Verbose)
end

function Runner.RunFolder(Folder, Verbose)
	local Files = ListDirectory(Folder)
	for _, File in ipairs(Files) do
		if File:match("%.vyn$") then
			local Path = Folder .. "/" .. File
			ColorPrint("Running: " .. Path, Colors.Yellow)
			Runner.RunFile(Path, Verbose)
		end
	end
end

function Runner.repl(Verbose)
	ColorPrint("Vyn REPL (type 'exit' to quit)", Colors.Cyan)

	while true do
		io.write("> ")
		local Line = io.read()
		if not Line or Line:lower() == "exit" then break end

		Runner.RunSource(Line, "<REPL>", Verbose)
	end
end

function Runner.WatchFile(Path, Verbose)
	local LastModified = GetModTime(Path)
	ColorPrint("Watching File: " .. Path, Colors.Yellow)

	while true do
		local Current = GetModTime(Path)

		if Current ~= LastModified then
			LastModified = Current
			ColorPrint("Detected change, re-running: " .. Path, Colors.Cyan)
			Runner.RunFile(Path, Verbose)
		end

		Sleep(0.5)
	end
end

function Runner.watchFolder(Folder, Verbose)
	local LastMods = {}
	local Files = ListDirectory(Folder)

	for _, File in ipairs(Files) do
		if File:match("%.vyn$") then
			local Path = Folder .. "/" .. File
			LastMods[Path] = GetModTime(Path)
		end
	end

	ColorPrint("Watching Folder: " .. Folder, Colors.Yellow)

	while true do
		local NowFiles = ListDirectory(Folder)

		for _, File in ipairs(NowFiles) do
			if File:match("%.vyn$") then
				local Path = Folder .. "/" .. File
				local ModTime = GetModTime(Path)

				if not LastMods[Path] or ModTime ~= LastMods[Path] then
					LastMods[Path] = ModTime
					ColorPrint("Detected change, re-running: " .. Path, Colors.Cyan)
					Runner.RunFile(Path, Verbose)
				end
			end
		end

		Sleep(0.5)
	end
end
function Runner.CheckSyntax(Path)
	local f = io.open(Path, "r")
	assert(f, "Cannot open File: " .. Path)
	local Source = f:read("*a")
	f:close()

	local ok, err = pcall(function()
		local Tokens = Lexer.Tokenize(Source)
		Parser.Parse(Tokens)
	end)

	if ok then
		ColorPrint("Syntax OK: " .. Path, Colors.Green)
	else
		ColorPrint("Syntax Error: " .. err, Colors.Red)
	end
end

function Runner.DebugTokens(Path)
	local f = io.open(Path, "r")
	assert(f, "Cannot open File: " .. Path)
	local Source = f:read("*a")
	f:close()

	local Tokens = Lexer.Tokenize(Source)
	for _, t in ipairs(Tokens) do
		print(t.Type, t.Value)
	end
end

function Runner.PrintAST(Path)
	local f = io.open(Path, "r")
	assert(f, "Cannot open File: " .. Path)
	local Source = f:read("*a")
	f:close()

	local Tokens = Lexer.Tokenize(Source)
	local AST = Parser.Parse(Tokens)
	for i, Node in ipairs(AST) do
		print(i, Node.op, Node.args and Node.args[1] and Node.args[1].Value or "")
	end
end

function Runner.Build(Path, Output)
	ColorPrint("Building: " .. Path, Colors.Yellow)
	local f = io.open(Path, "r")
	assert(f, "Cannot open File: " .. Path)
	local Source = f:read("*a")
	f:close()

	local Tokens = Lexer.Tokenize(Source)
	local AST = Parser.Parse(Tokens)
	local Bytecode = Compiler.Compile(AST)

	local Out = io.open(Output, "wb")
	assert(Out, "Cannot create output: " .. Output)
	Out:write(table.concat(Bytecode, "\n"))
	Out:close()

	ColorPrint("Build Complete → " .. Output, Colors.Green)
end

function Runner.CompileTo(Path, Output)
	ColorPrint("Compiling to Bytecode: " .. Path, Colors.Yellow)
	Runner.Build(Path, Output)
end

function Runner.InitProject(Folder)
	os.execute('mkdir "' .. Folder .. '"')
	local Main = io.open(Folder .. "/main.vyn", "w")
	Main:write("-- Entry point for Vyn project\nprint('Hello, Vyn!')\n")
	Main:close()
	ColorPrint("Initialized Vyn Project in: " .. Folder, Colors.Green)
end

function Runner.ManageConfig(Key, Value)
	local ConfigFile = "vynconfig.json"
	local Config = {}
	local f = io.open(ConfigFile, "r")

	if f then
		local Content = f:read("*a")
		f:close()
		
		local ok, Data = pcall(function() return require("libs.dkjson").decode(Content) end)
		if ok and Data then Config = Data end
	end

	if Key and Value then
		Config[Key] = Value
		local f = io.open(ConfigFile, "w")
		f:write(require("libs.dkjson").encode(Config, { indent = true }))
		f:close()
		
		ColorPrint("Updated Config: " .. Key .. " = " .. Value, Colors.Green)
	else
		ColorPrint("Current Config:", Colors.Cyan)
		for k, v in pairs(Config) do
			print(k, "=", v)
		end
	end
end

function Runner.Benchmark(Path)
	local Start = os.clock()
	Runner.RunFile(Path)
	local Elapsed = os.clock() - Start
	ColorPrint(("Benchmark: %.4f seconds"):format(Elapsed), Colors.Yellow)
end

function Runner.ProfileScript(Path)
	ColorPrint("Profiling Script: " .. Path, Colors.Yellow)
	local Start = os.clock()
	Runner.RunFile(Path)
	local End = os.clock()
	ColorPrint(("Execution Time: %.4f seconds"):format(End - Start), Colors.Green)
end

function Runner.InstallPackage(Name)
	ColorPrint("Installing Package: " .. Name, Colors.Yellow)
	os.execute("mkdir -p packages && echo 'placeholder for " .. Name .. "' > packages/" .. Name .. ".vynpkg")
	ColorPrint("Package Installed: " .. Name, Colors.Green)
end

function Runner.RemovePackage(Name)
	ColorPrint("Removing Package: " .. Name, Colors.Yellow)
	os.remove("packages/" .. Name .. ".vynpkg")
	ColorPrint("Package Removed: " .. Name, Colors.Green)
end

function Runner.ListPackages()
	ColorPrint("Installed Packages:", Colors.Cyan)
	local Packages = ListDirectory("packages")
	for _, pkg in ipairs(Packages) do
		print("• " .. pkg)
	end
end

function Runner.ShowCredits()
	ColorPrint("Vyn Programming Language", Colors.Cyan)
	print("  Creator: Nib Interactive")
	print("  Core Devs: VynLang Contributors")
	print("  Special Thanks: Early Testers & Community ❤️")
end

function Runner.ShowAbout()
	print("Vyn Programming Language — built by Nib Interactive, 2025")
	print("Designed for accessibility, readability, and versatility.")
end

function Runner.ShowChangeLog()
	ColorPrint("Vyn Changelog:", Colors.Cyan)
	print("  v0.1.2 - Added CLI tools, function scopes, and REPL improvements")
	print("  v0.1.1 - Added math operations and variable types")
	print("  v0.1.0 - Initial release")
end

return Runner
 end
package.preload["Vyn.Compiler"] = function() local Compiler = {}

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
	elseif Node.op == "IF" then
		CompileExpression(Node.Condition, Bytecode)
		
    	local JumpIfFalseIndex = #Bytecode + 1
        table.insert(Bytecode, { op = "JUMP_IF_FALSE", Target = nil }) -- Todo: Fix later

        for _, stmt in ipairs(Node.Body) do
            CompileStatement(stmt, Bytecode)
        end

        if Node.ElseBody then
            local JumpOverElseIndex = #Bytecode + 1
            table.insert(Bytecode, { op = "JUMP", Target = nil })

			Bytecode[JumpIfFalseIndex].Target = #Bytecode + 1

            for _, stmt in ipairs(Node.ElseBody) do
                CompileStatement(stmt, Bytecode)
            end

            Bytecode[JumpOverElseIndex].Target = #Bytecode + 1
        else
            Bytecode[JumpIfFalseIndex].Target = #Bytecode + 1
        end
	elseif Node.op == "FUNCTION" then
		local FunctionBytecode = {}
		local OldBytecode = Bytecode
		Bytecode = FunctionBytecode

		for _, stmt in ipairs(Node.Body) do
			CompileStatement(stmt, Bytecode)
		end

		table.insert(Bytecode, { op = "RETURN" })

       	Bytecode = OldBytecode

       	table.insert(Bytecode, { op = "FUNCTION_DECL", Name = Node.Name, Params = Node.Params, Body = FunctionBytecode })
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
 end
package.preload["Vyn.Parser"] = function() local Parser = {}

local Precedence = {
	["PLUS"] = 1,
	["MINUS"] = 1,
	["MULT"] = 2,
	["DIV"] = 2,
    ["EXPO"] = 3, -- Exponentiation ^
    ["PRCNT"] = 3, -- Modulo %

    ["EQ"] = 0, -- ==
    ["NEQ"] = 0, -- !=
    ["GT"] = 0, -- >
    ["LT"] = 0, -- <
    ["GTEQ"] = 0, -- >=
    ["LTEQ"] = 0, -- <=

    ["AND"] = -1,
    ["OR"] = -2,

    ["ASSIGN"] = -3,
}

local function Consume(Tokens, i, ExpectedType)
    local _Token = Tokens[i]

    if not _Token or _Token.Type ~= ExpectedType then
        error("Parser Error: Expected "..ExpectedType.." at token "..(i or "?"))
    end

    return _Token, i+1
end

local function GetPrecedence(token)
	if not token then return 0 end

	return Precedence[token.Type] or 0
end

local function ParseBlock(Tokens, i, Style)
    local Body = {}

    if Style == "BRACE" then
        i = i + 1

        while Tokens[i] and Tokens[i].Type ~= "RBRACE" do
            local stmt
            stmt, i = ParseStatement(Tokens, i)

            table.insert(Body, stmt)
        end

        _, i = Consume(Tokens, i, "RBRACE")
    elseif Style == "COLON" then
        local BaseIndent = Tokens[i-1].Indent or 0
        i = i + 1

        while Tokens[i] and (Tokens[i].Indent or 0) > BaseIndent do
            local stmt
            stmt, i = ParseStatement(Tokens, i)

            table.insert(Body, stmt)
        end
    elseif Style == "THEN" then
        i = i + 1

        while Tokens[i] and Tokens[i].Type ~= "END" do
            local stmt
            stmt, i = ParseStatement(Tokens, i)

            table.insert(Body, stmt)
        end

        _, i = Consume(Tokens, i, "END")
    end

    return { op = "BLOCK", Body = Body }, i
end

local function ParseIf(Tokens, i)
    i = i + 1
    local Condition, NextIndex = ParseExpression(Tokens, i)
    i = NextIndex

    local Style

    if Tokens[i] then
        if Tokens[i].Type == "COLON" then
            Style = "COLON"
        elseif Tokens[i].Type == "THEN" then
            Style = "THEN"
        elseif Tokens[i].Type == "LBRACE" then
            Style = "BRACE"
        else
            error("Expected block start after if condition")
        end
    end

    local BlockNode
    BlockNode, i = ParseBlock(Tokens, i, Style)

    local Node = { op = "IF", Condition = Condition, Body = BlockNode.Body }

    if Tokens[i] and Tokens[i].Type == "ELSE" then
        i = i + 1
        local ElseStyle

        if Tokens[i] then
            if Tokens[i].Type == "COLON" then
                ElseStyle = "COLON"
            elseif Tokens[i].Type == "THEN" then
                ElseStyle = "THEN"
            elseif Tokens[i].Type == "LBRACE" then
                ElseStyle = "BRACE"
            else
                error("Expected block start after else")
            end
        end

        local ElseBlock
        ElseBlock, i = ParseBlock(Tokens, i, ElseStyle)
        Node.ElseBody = ElseBlock.Body
    end

    return Node, i
end

local function ParseFunction(Tokens, i)
    i = i + 1

    local Name

    if Tokens[i].Type == "IDENTIFIER" then
        Name = Tokens[i].Value
        i = i + 1
    end

    _, i = Consume(Tokens, i, "LPAREN")

    local Params = {}

    while Tokens[i] and Tokens[i].Type ~= "RPAREN" do
        if Tokens[i].Type == "IDENTIFIER" then
            table.insert(Params, Tokens[i].Value)
        end

        i = i + 1
    end

    _, i = Consume(Tokens, i, "RPAREN")

    local Style

    if Tokens[i].Type == "LBRACE" then
        Style = "BRACE"
    elseif Tokens[i].Type == "END" then
        Style = "THEN"
    elseif Tokens[i].Type == "COLON" then
        Style = "COLON"
    else
        Style = "BRACE"
    end

    local BlockNode
    BlockNode, i = ParseBlock(Tokens, i, Style)

    return { op = "FUNCTION", Name = Name, Params = Params, Body = BlockNode.Body }, i
end

function ParseStatement(Tokens, i)
    local _Token = Tokens[i]

    if _Token.Type == "LOCAL" or _Token.Type == "PRIVATE" then
        i = i + 1

        local Expression
        local DeclareType = _Token.Type
        local VariableNameToken = Tokens[i]
        if not VariableNameToken or VariableNameToken.Type ~= "IDENTIFIER" then
            error("Parser Error: Expected variable name after '" .. DeclareType .. "'")
        end

        local VariableName = VariableNameToken.Value

        i = i + 1
        _, i = Consume(Tokens, i, "ASSIGN")

        Expression, i = ParseExpression(Tokens, i, 0)

        return { op = "DECLARE", Scope = DeclareType, Name = VariableName, Value = Expression }, i
    elseif _Token.Type == "PRINT" then
        i = i + 1

        local Expression, NextIndex = ParseExpression(Tokens, i)
        i = NextIndex

        return { op = "PRINT", args = { Expression } }, i
    elseif _Token.Type == "IF" then
        return ParseIf(Tokens, i)
    elseif _Token.Type == "FUNCTION" then
        return ParseFunction(Tokens, i)
    elseif _Token.Type == "IDENTIFIER" and Tokens[i+1] and Tokens[i+1].Type == "ASSIGN" then
        local Name = _Token.Value
        local Expression

        i = i + 2

        Expression, i = ParseExpression(Tokens, i, 0)

        return { op = "ASSIGN", Name = Name, Value = Expression }, i
    elseif _Token.Type == "LBRACE" then
        local Node
        Node, i = ParsePrimary(Tokens, i)

        return Node, i
    else
        error("Parser Error: Unknown statement ".._Token.Type)
    end
end

function ParsePrimary(Tokens, i)
	local _Token = Tokens[i]

	if not _Token then
		error("Parser Error: Unexpected end of input while parsing primary")
	end

	if _Token.Type == "NUMBER" then
		return { Type = "NUMBER", Value = _Token.Value }, i + 1
	elseif _Token.Type == "IDENTIFIER" then
		return { Type = "VAR", Name = _Token.Value }, i + 1
	elseif _Token.Type == "LPAREN" then
		local Node

		Node, i = ParseExpression(Tokens, i + 1)
		_, i = Consume(Tokens, i, "RPAREN")
        
		return Node, i
    elseif _Token.Type == "LBRACE" then
        local Body = {}
        i = i + 1

        while Tokens[i] and Tokens[i].Type ~= "RBRACE" do
            local stmt
            
            stmt, i = ParseStatement(Tokens, i)
            table.insert(Body, stmt)
        end

        _, i = Consume(Tokens, i, "RBRACE")

        return { op = "BLOCK", Body = Body }, i
	else
		error("Parser Error: Unexpected token " .. _Token.Type)
	end
end

function ParseExpression(Tokens, i, MinimumPrecedence)
	MinimumPrecedence = MinimumPrecedence or 0
	local Left, NextIndex = ParsePrimary(Tokens, i)

	while true do
		local opToken = Tokens[NextIndex]
		if not opToken then break end

		local Right
		local Precedence = GetPrecedence(opToken)
		if Precedence < MinimumPrecedence or Precedence == 0 then break end

		NextIndex = NextIndex + 1
		Right, NextIndex = ParseExpression(Tokens, NextIndex, Precedence + 1)

		Left = {
			op = opToken.Type,
			Left = Left,
			Right = Right
		}
	end

	return Left, NextIndex
end

function Parser.Parse(Tokens)
    local Ast = {}
    local i = 1

    while i <= #Tokens do
        local Node

        Node, i = ParseStatement(Tokens, i)
        table.insert(Ast, Node)
    end
    
    return Ast
end

return Parser
 end
package.preload["Vyn.VM"] = function() local VM = {}

function VM.Run(Bytecode)
	local Stack = {}
	local Environment = { { Variables = {}, Privates = {} } }
	local Functions = {}
	local PC = 1

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
		elseif instr.op == "FUNCTION_DECL" then
			Functions[instr.Name] = { Params = instr.Params, Body = instr.Body }; return nil
		elseif instr.op == "CALL_FUNCTION" then
			local _FUNC = Functions[instr.Name]
			if not _FUNC then error("Runtime Error : '"..instr.Name.."' not found") end

			local Arguments = {}
			for i=1, #_FUNC.Params do
				table.insert(Arguments, 1, table.remove(Stack))
			end

			PushEnvironment()

			for i, Param in ipairs(_FUNC.Params) do
				DeclareVariable(Param, Arguments[i], "LOCAL")
			end

			VM.Run(_FUNC.Body)
			PopEnvironment()

			return nil
		elseif instr.op == "RETURN" then
			return "RETURN"
		elseif instr.op == "JUMP_IF_ELSE" then
			local Condition = table.remove(Stack)
			if not Condition then
				return instr.Target
			else
				return nil
			end
		elseif instr.op == "JUMP" then
			PC = instr.Target
			return
		else
			error("Unknown instruction: " .. tostring(instr.op))
		end
	end

	while PC <= #Bytecode do
        local Instruction = Bytecode[PC]
        local NewPC = ExecuteInstruction(Instruction)

        if NewPC == "RETURN" then break end
        if NewPC then
            PC = NewPC
        else
            PC = PC + 1
        end
    end

	--[[for _, Instruction in ipairs(Bytecode) do
		ExecuteInstruction(Instruction)
	end]]
end

return VM

 end

--[[
    Vyn CLI / Runner
    Author: Nib Interactive
    Version: v0.1.2
--]]

local Runner = require("Vyn.Runner")

local Arguments = {...}

-- helper for printing CLI sections with nice formatting
local function PrintHelp()
    print([[
Vyn Programming Language CLI
────────────────────────────
Usage:
  vyn → open REPL
  vyn run <file.vyn> [--verbose]
  vyn watch <file.vyn> [--verbose]
  vyn runfolder <folder> [--verbose]
  vyn build <file.vyn> [output]
  vyn compile <file.vyn> [output]
  vyn check <file.vyn>
  vyn tokenize <file.vyn>
  vyn ast <file.vyn>
  vyn init [folder]
  vyn config [key] [value]
  vyn bench <file.vyn>
  vyn profile <file.vyn>
  vyn pkg [install|remove|list] [name]
  vyn --version
  vyn --help
  vyn --about
  vyn --changelog
  vyn --credits

Commands:
  run           Run a specific Vyn file
  watch         Watch a file and rerun on changes
  runfolder     Run all .vyn files inside a folder
  build         Build/compile into an executable or bytecode
  compile       Compile to intermediate VM bytecode
  check         Syntax-check a file
  tokenize      Show lexer tokens for a file
  ast           Print the Abstract Syntax Tree
  init          Initialize a new Vyn project folder
  config        Manage CLI or runtime configuration
  bench         Benchmark script performance
  profile       Profile script runtime behavior
  pkg           Manage packages (install, remove, list)
  --help        Show this help message
  --version     Show version info
  --about       About the Vyn language
  --credits     Show contributor info
  --changelog   Show recent changes

Examples:
  vyn run main.vyn
  vyn build app.vyn dist/output.vyb
  vyn pkg install http
  vyn check src/test.vyn
  vyn watch demo.vyn --verbose
]])
end

if #Arguments == 0 then
    Runner.repl()
elseif Arguments[1] == "run" and Arguments[2] then
    Runner.RunFile(Arguments[2], Arguments[3] == "--verbose")
elseif Arguments[1] == "watch" and Arguments[2] then
    Runner.WatchFile(Arguments[2], Arguments[3] == "--verbose")
elseif Arguments[1] == "runfolder" and Arguments[2] then
    Runner.RunFolder(Arguments[2], Arguments[3] == "--verbose")
elseif Arguments[1] == "build" and Arguments[2] then
    Runner.Build(Arguments[2], Arguments[3] or "out.vyb")
elseif Arguments[1] == "compile" and Arguments[2] then
    Runner.CompileTo(Arguments[2], Arguments[3] or "out.vyc")
elseif Arguments[1] == "check" and Arguments[2] then
    Runner.CheckSyntax(Arguments[2])
elseif Arguments[1] == "tokenize" and Arguments[2] then
    Runner.DebugTokens(Arguments[2])
elseif Arguments[1] == "ast" and Arguments[2] then
    Runner.PrintAST(Arguments[2])
elseif Arguments[1] == "init" then
    Runner.InitProject(Arguments[2] or ".")
elseif Arguments[1] == "config" then
    Runner.ManageConfig(Arguments[2], Arguments[3])
elseif Arguments[1] == "bench" and Arguments[2] then
    Runner.Benchmark(Arguments[2])
elseif Arguments[1] == "profile" and Arguments[2] then
    Runner.ProfileScript(Arguments[2])
elseif Arguments[1] == "fmt" and Arguments[2] then
    Runner.FormatFile(Arguments[2])
elseif Arguments[1] == "lint" and Arguments[2] then
    Runner.LintFile(Arguments[2])
elseif Arguments[1] == "debug" and Arguments[2] then
    Runner.DebugRun(Arguments[2])
elseif Arguments[1] == "pkg" then
    local Action = Arguments[2]
    if Action == "install" and Arguments[3] then
        Runner.InstallPackage(Arguments[3])
    elseif Action == "remove" and Arguments[3] then
        Runner.RemovePackage(Arguments[3])
    elseif Action == "list" then
        Runner.ListPackages()
    else
        print("Usage: vyn pkg [install|remove|list] <name>")
    end
elseif Arguments[1] == "--version" then
    Runner.ShowVersion()
elseif Arguments[1] == "--help" or Arguments[1] == "-h" then
    PrintHelp()
elseif Arguments[1] == "--about" then
    Runner.ShowAbout()
elseif Arguments[1] == "--credits" then
    Runner.ShowCredits()
elseif Arguments[1] == "--changelog" then
    Runner.ShowChangeLog()
else
    print("Unknown command: " .. tostring(Arguments[1]))
    print("Use 'vyn --help' to see available commands.")
end