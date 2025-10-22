local Parser = {}

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
