let score = 0;

// Block scope
{
    let coins = 5;
    let bonus = 10;

    let total = coins * bonus;
    score += total;

    console.log("Inside block:", total);
}

// Outside block
console.log("Final score:", score);
console.log("Coins outside block:", coins); // Would error: coins not defined
