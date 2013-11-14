#!/bin/bash

start_money=100

echo "Hello, welcome to the game. Game rules:
        1) You have 100 euro at start
        2) In order to win, you have to guess whether the next number will be higher or lower.
                For example: first number was 5. Is there random next number (from 1 to 100) will be higher or lower than 5?
                             If you guess right, you win money, depending on how much money you bet (more info below)
i       3) Bet - you can specify how much you can bet. For example if you bet 50 euro and lost, you will get -50 from your
                total money. If you win, you will have +50.

        Let's try!"

RANGE=100
number=`echo "40+$RANDOM%10*(2)+2 " | bc`
#           ^^

while :
do
        read -p "Place your bet: " bet
        if ! [[ "$bet"  =~ ^[0-9]+$ ]]; then
                echo "The bet must be an integer"
        elif [[ "$bet" -gt "$start_money" ]]; then
                echo "Cannot be more than your start money."
        else
                echo "Your bet is $bet..."
                break
        fi
done

echo "The random number is $number"

while :
do
        read -p "Is the next random number going to be lower or higher than $number? (type lower or higher) " answer

        if [[ "$answer"  == "lower" ]] || [[ "$answer" == "higher" ]]; then
                break
        else
                echo "Please type: lower or higher only"
        fi
done

second_number=$RANDOM

let "second_number %= $RANGE"
echo "next rumber is.... $second_number"

if [[ "$second_number" -lt "$number" ]] && [ "$answer" == "lower" ]; then
        let total_money=$start_money+$bet
        echo "Congratulations! You won $bet euro."
elif [[ "$second_number" -gt "$number" ]] && [ "$answer" == "lower" ]; then
        let total_money=$start_money-$bet
        echo "Wrong! You lost $bet euro."
elif [[ "$second_number" -lt "$number" ]] && [ "$answer" == "higher" ]; then
        let total_money=$start_money-$bet
        echo "Wrong! You lost $bet euro."
elif [[ "$second_number" -gt "$number" ]] && [ "$answer" == "higher" ]; then
        let total_money=$start_money+$bet
        echo "Congratulations! You won $bet euro."
else
        echo "something went wrong..."
fi

echo -e "You have now \e[1;38;5;16;48;5;46m ${e//[():3001]/}$total_money \e[0m euro"

while :
do

number=`echo "40+$RANDOM%10*(2)+2 " | bc`
#           ^^

while :
do
        read -p "Place your bet: " bet
        if ! [[ "$bet"  =~ ^[0-9]+$ ]]; then
                echo "The bet must be an integer"
        elif [[ "$bet" -gt "$total_money" ]]; then
                echo "Cannot be more than your total start money."
        else
                echo "Your bet is $bet..."
                break
        fi
done

echo "The random number is $number"

while :
do
        read -p "Is the next random number going to be lower or higher than $number? (type lower or higher) " answer

        if [[ "$answer"  == "lower" ]] || [[ "$answer" == "higher" ]]; then
                break
        else
                echo "Please type: lower or higher only"
        fi
done

second_number=$RANDOM

let "second_number %= $RANGE"
echo "next rumber is.... $second_number"

if [[ "$second_number" -lt "$number" ]] && [ "$answer" == "lower" ]; then
        let total_money=$total_money+$bet
        echo "Congratulations! You won $bet euro."
elif [[ "$second_number" -gt "$number" ]] && [ "$answer" == "lower" ]; then
        let total_money=$total_money-$bet
        echo "Wrong! You lost $bet euro."
elif [[ "$second_number" -lt "$number" ]] && [ "$answer" == "higher" ]; then
        let total_money=$total_money-$bet
        echo "Wrong! You lost $bet euro."
elif [[ "$second_number" -gt "$number" ]] && [ "$answer" == "higher" ]; then
        let total_money=$total_money+$bet
        echo "Congratulations! You won $bet euro."
else
        echo "something went wrong..."
fi

echo -e "You have now \e[1;38;5;16;48;5;46m ${e//[():3001]/}$total_money \e[0m euro"
echo "" 
        if [[ "$total_money" -le 0 ]]; then
                echo "GAME OVER"
                break
        fi

done
