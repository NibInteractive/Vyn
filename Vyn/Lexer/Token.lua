local Token = {}
Token.__index = Token

function Token.New(Type, Value, Line, Col, IndentLevel)
    return setmetatable({
        Type = Type,
        Value = Value,
        Line = Line,
        Col = Col,
        IndentLevel = IndentLevel or 0,
    }, Token)
end

return Token
