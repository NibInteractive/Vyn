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