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
        Col = 1
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

    while self.Position <= #self.Source do
        local Character = self:Peek()

        if Character:match("%s") then
            self:NextCharacter() -- Skip whitespace
        elseif Rules.IsDigit(Character) then
            local StartCol = self.Col
            local NumberString = ""

            while Rules.IsDigit(self:Peek()) do
                NumberString = NumberString .. self:NextCharacter()
            end

            table.insert(Tokens, Token.New("NUMBER", tonumber(NumberString), self.Line, StartCol))
        elseif Rules.IsLetter(Character) then
            local StartCol = self.Col
            local IdString = ""

            while Rules.IsLetter(self:Peek()) do
                IdString = IdString .. self:NextCharacter()
            end

            local Type = Rules.Keywords[IdString] or "IDENTIFIER"
            table.insert(Tokens, Token.New(Type, IdString, self.Line, StartCol))
        elseif Character == ">" or Character == "<" then
            local StartCol = self.Col
            local _Character = self:NextCharacter()
            local NextCharacter = self:Peek()

            if NextCharacter == "=" then
                self:NextCharacter()
                local op = (_Character == ">" and "GTEQ" or "LTEQ")
                table.insert(Tokens, Token.New(op, _Character..NextCharacter, self.Line, StartCol))
            else
                local op = (_Character == ">" and "GT" or "LT")
                table.insert(Tokens, Token.New(op, _Character, self.Line, StartCol))
            end
        elseif Rules.Operators[Character] then
            table.insert(Tokens, Token.New(Rules.Operators[Character], Character, self.Line, self.Col))
            self:NextCharacter()
        else
            Errors.Warn("Unknown character '"..Character.."'", self.Line, self.Col)
            self:NextCharacter()
        end
    end

    return Tokens
end

return Scanner
