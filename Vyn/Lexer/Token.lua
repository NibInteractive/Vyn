local Token = {}
Token.__index = Token

function Token.New(Type, Value, Line, Col)
    return setmetatable({
        Type = Type,
        Value = Value,
        Line = Line,
        Col = Col,
        IndentLevel = 0,
    }, Token)
end

return Token
