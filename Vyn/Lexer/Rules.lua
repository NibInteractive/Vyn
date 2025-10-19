local Rules = {}

-- Keywords
Rules.Keywords = {
    ["local"] = "LOCAL",
    ["private"] = "PRIVATE",

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
}

-- Helper checks
function Rules.IsDigit(Character)
    return Character:match("%d")
end

function Rules.IsLetter(Character)
    return Character:match("%a")
end

return Rules
