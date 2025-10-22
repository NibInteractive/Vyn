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
