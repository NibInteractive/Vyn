local Lexer = require("Vyn.Lexer.Lexer")
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

return Runner
