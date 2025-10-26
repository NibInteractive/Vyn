local NativeFunctions = {}

NativeFunctions["Window.Create"] = function(args)
    local title, w, h = args[1], args[2], args[3]
    return call_c_create_window(title, w, h)
end

return NativeFunctions