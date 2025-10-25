local Logger = require("Vyn.utils.Logger")

local Parser = {}

local Precedence = {
	["PLUS"] = 1,
	["MINUS"] = 1,
	["MULT"] = 2,
	["DIV"] = 2,
    ["EXPO"] = 3, -- Exponentiation ^
    ["PRCNT"] = 3, -- Modulo %

    ["EQ"] = 1, -- ==
    ["NEQ"] = 1, -- !=
    ["GT"] = 1, -- >
    ["LT"] = 1, -- <
    ["GTEQ"] = 1, -- >=
    ["LTEQ"] = 1, -- <=

    ["AND"] = -1,
    ["OR"] = -2,

    ["ASSIGN"] = -3,
}

local function Peek(Tokens, i)
    return Tokens[i]
end

local function Consume(Tokens, i, ExpectedType)
    local _Token = Tokens[i]

    if not _Token or _Token.Type ~= ExpectedType then
        error("Parser Error: Expected "..ExpectedType.." at token "..(i or "?"))
    end

    return _Token, i+1
end

local function GetPrecedence(Token)
	if not Token then return 0 end

	return Precedence[Token.Type] or 0
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
        error("Parser Error: COLON block style not implemented yet")

        local BaseIndent = Tokens[i - 1].Indent or 0
        i = i + 1

        local Iteration = 0

        while Tokens[i] do
            Iteration = Iteration + 1
            if Iteration > 10000 then
                error("Parser Error: Possible infinite loop detected while parsing block")
            end

            local CurrentIndent = Tokens[i].Indent or 0
            local _Type = Tokens[i].Type

            print("[DEBUG] Block:", Style, "Token:", _Type, "Indent:", CurrentIndent, "Base:", BaseIndent)
            if CurrentIndent <= BaseIndent or _Type == "END" or _Type == "ELSE" or _Type == "ELSEIF" then
                break
            end

            local stmt
            
            stmt, i = ParseStatement(Tokens, i)
            table.insert(Body, stmt)
        end
    elseif Style == "THEN" then
        i = i + 1

        while Tokens[i] and Tokens[i].Type ~= "END" and Tokens[i].Type ~= "ELSE" and Tokens[i].Type ~= "ELSEIF" do
            local stmt
            stmt, i = ParseStatement(Tokens, i)

            table.insert(Body, stmt)
        end
    end

    return { op = "BLOCK", Body = Body }, i
end

local function ParseElse(Tokens, i, ParentStyle)
    if not Tokens[i] then
        Logger.Error("Parser", "Unexpected end after else")
        
        return {}, i
    end

    local Style

    if ParentStyle == "THEN" then
        Style = "THEN"
    elseif Tokens[i].Type == "COLON" then
        Style = "COLON"
        i = i + 1
    elseif Tokens[i].Type == "LBRACE" then
        Style = "BRACE"
        i = i + 1
    elseif ParentStyle == "BRACE" or ParentStyle == "COLON" then
        Style = ParentStyle
    else
        Logger.Error("Parser", "Expected block start after else", {
            Token = Tokens[i].Type,
            Index = i
        })

        return {}, i
    end

    local ElseBlock, NextIndex = ParseBlock(Tokens, i, Style)

    return ElseBlock.Body, NextIndex
end

local function ParseIf(Tokens, i)
    i = i + 1
    local Condition, NextIndex = ParseExpression(Tokens, i)
    i = NextIndex

    local Style

    if Tokens[i] then
        if Tokens[i].Type == "COLON" then
            error("Parser Error: COLON block style not implemented yet")

            Style = "COLON"
            i = i + 1
        elseif Tokens[i].Type == "THEN" then
            Style = "THEN"
            i = i + 1
        elseif Tokens[i].Type == "LBRACE" then
            Style = "BRACE"
            i = i + 1
        else
            Logger.Error("Parser", "Expected block start after if condition", {
                Token = Tokens[i].Type,
                Index = i
            })
        end
    else
        Logger.Error("Parser", "Unexpected end after if condition")
    end

    local BlockNode
    BlockNode, i = ParseBlock(Tokens, i, Style)

    local Node = { op = "IF", Condition = Condition, Body = BlockNode.Body }

    while Tokens[i] and (Tokens[i].Type == "ELSEIF" or Tokens[i].Type == "ELSE") do
        local Keyword = Tokens[i].Type
        i = i + 1

        if Keyword == "ELSEIF" then
            local ElseIfNode

            ElseIfNode, i = ParseIf(Tokens, i)
            Node.ElseBody = Node.ElseBody or {}
            
            table.insert(Node.ElseBody, ElseIfNode)
        elseif Keyword == "ELSE" then
            local ElseStyle

            if Tokens[i] then
                if Style == "THEN" then
                    ElseStyle = "THEN"
                elseif Tokens[i].Type == "COLON" then
                    ElseStyle = "COLON"
                    i = i + 1
                elseif Tokens[i].Type == "LBRACE" then
                    ElseStyle = "BRACE"
                    i = i + 1
                else
                    ElseStyle = "THEN"
                end
            else
                ElseStyle = "THEN"
            end

            local ElseBlock
            ElseBlock, i = ParseBlock(Tokens, i, ElseStyle)
            Node.ElseBody = ElseBlock.Body

            break
        end
    end

    if Tokens[i] and Tokens[i].Type == "END" then
        i = i + 1
    else
        Logger.Error("Parser", "Expected END after if statement", {Token = Tokens[i] and Tokens[i].Type or "nil", Index = i})
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
        error("Parser Error: COLON block style not implemented yet")
        
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
    if not _Token then return nil, i end

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
    elseif _Token.Type == "RETURN" then
        i = i + 1
        local Values = {}

        while Tokens[i] and Tokens[i].Type ~= "NEWLINE" and Tokens[i].Type ~= "RBRACE" do
            local Expression

            Expression, i = ParseExpression(Tokens, i, 0)
            table.insert(Values, Expression)

            if Tokens[i] and Tokens[i].Type == "COMMA" then
                i = i + 1
            else
                break
            end
        end

        return { op = "RETURN", Values = Values }, i
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
        Logger.Error("Parser", "Unknown statement", {Token = _Token.Type, Index = i})
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
        if Tokens[i + 1] and Tokens[i + 1].Type == "LPAREN" then
			local Name = _Token.Value
			i = i + 2 

			local args = {}
			while Tokens[i] and Tokens[i].Type ~= "RPAREN" do
				local Expression
				Expression, i = ParseExpression(Tokens, i, 0)
				table.insert(args, Expression)

				if Tokens[i] and Tokens[i].Type == "COMMA" then
					i = i + 1
				end
			end

			_, i = Consume(Tokens, i, "RPAREN")

			return { op = "CALL", Name = Name, Args = args }, i
		end

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
