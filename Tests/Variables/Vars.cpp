#include <iostream>
using namespace std;

int main() {
    int score = 0;

    // Block scope
    {
        int coins = 5;
        int bonus = 10;

        int total = coins * bonus;
        score += total;

        cout << "Inside block: " << total << endl;
    }

    // Outside block
    cout << "Final score: " << score << endl;
    cout << "Coins outside block: " << coins << endl; // Error: coins not defined

    return 0;
}
