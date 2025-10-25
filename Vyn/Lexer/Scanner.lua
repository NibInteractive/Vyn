local Token = require("Vyn.Lexer.Token")
local Rules = require("Vyn.Lexer.Rules")
local Errors = require("Vyn.Lexer.Errors")

local Scanner = {}
Scanner.__index = Scanner

function Scanner.New(Source)
    return setmetatable({
        Source = Source,
        Position = 1,
        Line = 1,
        Col = 1,
        IndentLevel = 0,
    }, Scanner)
end

function Scanner:NextCharacter()
    local Character = self.Source:sub(self.Position, self.Position)
    self.Position = self.Position + 1

    if Character == "\n" then
        self.Line = self.Line + 1
        self.Col = 1
    else
        self.Col = self.Col + 1
    end

    return Character
end

function Scanner:Peek()
    return self.Source:sub(self.Position, self.Position)
end

function Scanner:Tokenize()
    local Tokens = {}
    local IndentStack = {0}

    while self.Position <= #self.Source do
        local Character = self:Peek()
        local CurrentIndent = IndentStack[#IndentStack] or 0

        if Character:match("%s") then
            self:NextCharacter() -- Skip whitespace
        elseif Character == "\n" then
            self:NextCharacter()

            local Count = 0

            while self:Peek() == " " do
                self:NextCharacter()
                Count = Count + 1
            end

            local NextCharacter = self:Peek()

            if NextCharacter ~= "" then
                local LastIndent = IndentStack[#IndentStack]

                if Count > LastIndent then
                    table.insert(Tokens, Token.New("INDENT", nil, self.Line, self.Col, Count))
                    table.insert(IndentStack, Count)
                elseif Count < LastIndent then
                    while #IndentStack > 0 and Count < IndentStack[#IndentStack] do
                        table.insert(Tokens, Token.New("DEDENT", nil, self.Line, self.Col, Count))
                        table.remove(IndentStack)
                    end
                end
            end
        elseif Rules.IsDigit(Character) then
            local StartCol = self.Col
            local NumberString = ""

            while Rules.IsDigit(self:Peek()) do
                NumberString = NumberString .. self:NextCharacter()
            end

            table.insert(Tokens, Token.New("NUMBER", tonumber(NumberString), self.Line, StartCol, CurrentIndent))
        elseif Rules.IsLetter(Character) then
            local StartCol = self.Col
            local IdString = self:NextCharacter()

            while Rules.IsLetter(self:Peek()) do
                IdString = IdString .. self:NextCharacter()
            end

            local Type = Rules.Keywords[IdString] or "IDENTIFIER"
            table.insert(Tokens, Token.New(Type, IdString, self.Line, StartCol, CurrentIndent))
        elseif Character == ">" or Character == "<" then
            local StartCol = self.Col
            local _Character = self:NextCharacter()
            local NextCharacter = self:Peek()

            if NextCharacter == "=" then
                self:NextCharacter()
                local op = (_Character == ">" and "GTEQ" or "LTEQ")
                table.insert(Tokens, Token.New(op, _Character..NextCharacter, self.Line, StartCol, CurrentIndent))
            else
                local op = (_Character == ">" and "GT" or "LT")
                table.insert(Tokens, Token.New(op, _Character, self.Line, StartCol, CurrentIndent))
            end
        elseif Rules.Operators[Character] then
            table.insert(Tokens, Token.New(Rules.Operators[Character], Character, self.Line, self.Col, CurrentIndent))
            self:NextCharacter()
        else
            Errors.Warn("Unknown character '"..Character.."'", self.Line, self.Col)
            self:NextCharacter()
        end
    end

    while #IndentStack > 1 do
        local LastIndent = IndentStack[#IndentStack]

        print("Adding DEDENT for indent level: "..LastIndent)

        table.insert(Tokens, Token.New("DEDENT", nil, self.Line, 0, LastIndent))
        table.remove(IndentStack)
    end

    return Tokens
end

return Scanner
