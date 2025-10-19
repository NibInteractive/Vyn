local Scanner = require("Vyn.Lexer.Scanner")

local Lexer = {}

function Lexer.Tokenize(source)
    local SCAN = Scanner.New(source)

    return SCAN:Tokenize()
end

return Lexer

