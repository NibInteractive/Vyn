local Errors = {}

function Errors.Warn(Message, Line, Col)
    print(string.format("Lexer Warning at %d:%d → %s", Line, Col, Message))
end

return Errors
