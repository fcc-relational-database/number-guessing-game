#!/bin/bash

# Function to execute PSQL queries
execute_psql_query() {
    PSQL_QUERY="$1"
    RESULT=$(psql --username=freecodecamp --dbname=number_guess -t --no-align -c "$PSQL_QUERY")
    echo "$RESULT"
}

# Random number between 1 and 1000:
NUM=$(( ( RANDOM % 1000 ) + 1 ))

# Get the username 
echo "Enter your username:" 
read USERNAME

# Check whether the user exists 

USER_INFO=$(execute_psql_query "SELECT user_id, games_played, best_game, username FROM users WHERE username='$USERNAME';")


if [[ -z $USER_INFO ]]; then
    USER_INSERT_RESULT=$(execute_psql_query "INSERT INTO users (username) VALUES ('$USERNAME');")

    if [[ $USER_INSERT_RESULT = "INSERT 0 1" ]]; then
        echo "Welcome, $USERNAME! It looks like this is your first time here."
        USER_PLAYED_GAMES=0
    else
        echo "Whoops, something went wrong while adding your username to the database!"
        exit
    fi
else
    # get all info into variables
    read USER_ID USER_PLAYED_GAMES USER_BEST_GAME USERNAME <<< $(echo $USER_INFO | sed -r 's/\|/ /g')
    echo "Welcome back, $USERNAME! You have played $USER_PLAYED_GAMES games, and your best game took $USER_BEST_GAME guesses."
fi

NUM_GUESSES=0

# Play the game
echo "Guess the secret number between 1 and 1000:"
while [[ $NUM -ne $USER_GUESS ]]; do
    read -p "Enter your guess: " USER_GUESS
    ((NUM_GUESSES++))

    # Ensure the user's guess is a positive integer
    while [[ ! $USER_GUESS =~ ^[0-9]*$ ]]; do
        echo "That is not an integer, guess again:"
        read USER_GUESS
    done

    if [[ $USER_GUESS -lt $NUM ]]; then
        echo "It's higher than that, guess again:"
    elif [[ $USER_GUESS -gt $NUM ]]; then
        echo "It's lower than that, guess again:"
    fi
done

# Update the user's game statistics in the database
if [[ $USER_PLAYED_GAMES -eq 0 || $NUM_GUESSES -lt $USER_BEST_GAME ]]; then
    execute_psql_query "UPDATE users SET games_played=games_played + 1, best_game=$NUM_GUESSES WHERE username='$USERNAME';"
else
    execute_psql_query "UPDATE users SET games_played=games_played + 1 WHERE username='$USERNAME';"
fi

# Display the final result to the user
# You guessed it in <number_of_guesses> tries. The secret number was <secret_number>. Nice job!
echo "You guessed it in $NUM_GUESSES tries. The secret number was $NUM. Nice job!"
