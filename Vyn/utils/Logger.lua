local Logger = {}

function Logger.Error(Type, Message, Info)
    local Prefix = "["..(Type or "Unknown").."]"
    print(Prefix.." "..Message)

    if Info then
        for k,v in pairs(Info) do
            print("  "..k..": "..tostring(v))
        end
    end

    error(Prefix.." "..Message)
end

return Logger
