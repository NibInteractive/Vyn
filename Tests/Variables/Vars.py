score = 0

# Block scope (Python has function-level scope)
def block():
    coins = 5
    bonus = 10

    total = coins * bonus
    global score
    score += total

    print("Inside block:", total)

block()

# Outside block
print("Final score:", score)
print("Coins outside block:", coins) # Would error: coins undefined