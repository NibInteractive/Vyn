-- Global variable
Score = 0

-- Block scope simulation
do
    local coins = 5
    local bonus = 10

    local total = coins * bonus
    score = score + total

    print("Inside block: " .. total)
end

-- Outside block
print("Final score: " .. score)
-- print("Coins outside block: " .. coins) -- Would error: coins is local
