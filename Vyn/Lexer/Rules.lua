local Rules = {}

-- Keywords
Rules.Keywords = {
    -- Variable Types --
    ["local"] = "LOCAL",
    ["private"] = "PRIVATE",

    -- Function Keywords --
    ["function"] = "FUNCTION",
    ["func"] = "FUNCTION",
    ["fn"] = "FUNCTION",

    ["return"] = "RETURN",
    ["continue"] = "CONTINUE",
    ["break"] = "BREAK",

    -- Control
    ["if"] = "IF",
    ["else"] = "ELSE",
    ["then"] = "THEN",
    ["end"] = "END",

    -- 2Be in standard library
    ["print"] = "PRINT"
}

-- Single-char operators
Rules.Operators = {
    ["+"] = "PLUS",
    ["-"] = "MINUS",
    ["*"] = "MULT",
    ["/"] = "DIV",
    ["="] = "ASSIGN",

    ["^"] = "EXPO",
    ["%"] = "PRCNT",

	["("] = "LPAREN",
	[")"] = "RPAREN",
    ["{"] = "LBRACE",
    ["}"] = "RBRACE",

    [">"] = "GT",
    ["<"] = "LT",
    [">="] = "GTEQ",
    ["<="] = "LTEQ",

    -- Others --
    [":"] = "COLON",
    [","] = "COMMA",

    ['"'] = "QUOTE",
}

function Rules.IsDigit(Character)
    return Character:match("%d")
end

function Rules.IsLetter(Character)
    return Character:match("%a")
end

return Rules
