local Window = {}

local backend_path = "D:/GitProjects/Vyn/Vyn/src/stdlib/backend/Window.exe"

function Window.Create(title, width, height)
    -- Build command string
    local cmd = string.format('"%s" "%s" %d %d', backend_path, title, width, height)
    
    -- Call backend executable and capture output
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()

    -- Return stdout as string
    return result
end

Window.Create("Sample Window", 800, 600)  -- Example usage

return Window
