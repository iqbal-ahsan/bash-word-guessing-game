#!/bin/bash

# Create necessary files and directories
mkdir -p players

ACCOUNTS_FILE="accounts.txt"
LEADERBOARD_FILE="leaderboard.txt"
WORDS_FILE="words.txt"

# Function to register a new user
register_user() {
    echo "Enter a new username:"
    read username

    if grep -q "^$username " "$ACCOUNTS_FILE"; then
        echo "Username already exists."
        return
    fi

    echo "Enter a 3-character password:"
    read -s password

    if [ ${#password} -ne 3 ]; then
        echo "Password must be exactly 3 characters."
        return
    fi

    echo "$username $password" >> "$ACCOUNTS_FILE"
    touch "players/$username.txt"
    echo "Account created successfully."
}

# Function to login existing user
login_user() {
    echo "Enter username:"
    read username
    echo "Enter password:"
    read -s password

    if grep -q "^$username $password$" "$ACCOUNTS_FILE"; then
        echo "Login successful."
        game "$username"
    else
        echo "Invalid username or password."
    fi
}

# Function to update leaderboard
update_leaderboard() {
    local username=$1
    score=0
    if grep -q "^$username-" "$LEADERBOARD_FILE"; then
        score=$(grep "^$username-" "$LEADERBOARD_FILE" | cut -d'-' -f2)
        grep -v "^$username-" "$LEADERBOARD_FILE" > temp.txt && mv temp.txt "$LEADERBOARD_FILE"
    fi
    score=$((score + 1))
    echo "$username-$score" >> "$LEADERBOARD_FILE"
    sort -t'-' -k2 -nr "$LEADERBOARD_FILE" -o "$LEADERBOARD_FILE"
}

# Main game logic
game() {
    username=$1

    if [ ! -s "$WORDS_FILE" ]; then
        echo "Word list is empty."
        return
    fi

    latest_entry=$(tail -n 1 "$WORDS_FILE")
    today=$(echo $latest_entry | cut -d' ' -f1)
    word=$(echo $latest_entry | cut -d' ' -f2)
    echo "Today's word starts with '${word:0:1}'"

    tries=5
    progress="${word:0:1}"
    for ((i=1; i<${#word}; i++)); do progress+="_"; done

    while [ $tries -gt 0 ]; do
        echo "You have $tries tries left."
        echo "Current progress: $progress"
        echo -n "Enter next letter: "
        read guess

        if [ -z "$guess" ]; then
            echo "Please enter a letter."
            continue
        fi

        correct=false
        updated_progress=""

        for ((i=0; i<${#word}; i++)); do
            if [ "${word:$i:1}" == "$guess" ] && [ "${progress:$i:1}" == "_" ]; then
                updated_progress+="$guess"
                correct=true
            else
                updated_progress+="${progress:$i:1}"
            fi
        done

        if [ "$correct" = true ]; then
            echo "Correct guess!"
            progress=$updated_progress
        elif [[ $word == *$guess* ]]; then
            echo "The letter '$guess' exists but in a different position."
        else
            echo "The letter '$guess' does not exist in the word."
        fi

        if [ "$progress" == "$word" ]; then
            echo "Congratulations! You guessed the word '$word'."
            echo "$today 1" >> "players/$username.txt"
            update_leaderboard "$username"
            return
        fi

        tries=$((tries - 1))
    done

    echo "You have 0 tries left. You lose. Game over."
    echo "$today 0" >> "players/$username.txt"
}

# Main menu loop
while true; do
    echo "To login, press 1"
    echo "To create an account, press 2"
    echo "To exit, press 3"
    read choice

    case $choice in
        1) login_user ;;
        2) register_user ;;
        3) echo "Goodbye!"; exit ;;
        *) echo "Invalid option." ;;
    esac
done
