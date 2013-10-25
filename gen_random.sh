#/bin/bash

function randomize_string () {

string=$1

str_len=${#string}
pass_len=()

for x in `seq 1 $str_len`; do
        pass_len+=($x)
done

random_indexes=()

count=1
while [ $count -le 7 ]; do
        for n in "${pass_len[@]}"; do
                let random_index=${RANDOM}%${#pass_len[@]}
                if [ ${#random_indexes[@]} -eq 0 ]; then
                        random_indexes+=($random_index)
                else
                        if [[ " ${random_indexes[*]} " == *" $random_index "* ]]; then
                                num=1
                        else
                                random_indexes+=($random_index)
                        fi
                fi

        done
        (( count++ ))
done

for n in "${random_indexes[@]}"; do
        single_char=`echo "${string:$n:1}"`
        echo $single_char
done

}

while :
do
        read -p "How many passwords do you need?: " pass_count
                if [[ "$pass_count"  =~ ^[0-9]+$ ]] && [[ "$pass_count" -gt 0 ]] && [[ "$pass_count" -lt 100 ]]; then
                break
        else
                echo "Insert the amount of passwords (from 1 to 100)"

        fi
done

while :
do
        read -p "How many small characters?: " small_char
        if [[ "$small_char"  =~ ^[0-9]+$ ]] && [[ "$small_char" -lt 10 ]]; then
                break
        else
                echo "Should be integer and less than 10."

        fi
done


while :
do
        read -p "How many big characters?: " big_char
        if [[ "$big_char"  =~ ^[0-9]+$ ]] && [[ "$big_char" -lt 10 ]]; then
                break
        else
                echo "Should be integer and less than 10."

        fi
done

while :
do
        read -p "How many numbers?: " number_char
        if [[ "$number_char"  =~ ^[0-9]+$ ]] && [[ "$number_char" -lt 20 ]]; then
                break
        else
                echo "Should be integer and less than 10."
        fi
done

big_echo="You have entered:
        Password count: $pass_count
        Small characters: $small_char
        Big characters: $big_char
        Numbers: $number_char"

echo "$big_echo"

for x in `seq 1 $pass_count`; do

        small_char_array=(a b c d e f g h i j k l m n o p q r s t u v w x y z)
        big_char_array=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)
        number_char_array=(1 2 3 4 5 6 7 8 9 0)

        max_char=${#small_char_array[*]}
        max_bigchar=${#big_char_array[*]}
        max_number=${#number_char_array[*]}

        for a in `seq 1 $small_char`; do
                let rand_char=${RANDOM}%${max_char}
                str="${str}${small_char_array[$rand_char]}"
        done

        for b in `seq 1 $big_char`; do
                let rand_bigchar=${RANDOM}%${max_bigchar}
                str="${str}${big_char_array[$rand_bigchar]}"
        done

        for c in `seq 1 $number_char`; do
                let rand_number=${RANDOM}%${max_number}
                str="${str}${number_char_array[$rand_number]}"
        done

done

let pass_len=$small_char+$big_char+$number_char
new_str=`echo $str | sed -e "s/.\{$pass_len\}/&\n/g"`

passwords=()
for k in $new_str; do
        passwords+=($k)
done

if [ $pass_count -eq 1 ]; then
        echo Generating password...
        #echo "$new_str"
else
        echo Generating passwords...
        #echo "$new_str"
fi
echo "--------------------------"
for i in "${passwords[@]}"; do
        final_pass=`randomize_string $i`
        echo $final_pass | tr -d ' '
        #sleep 1
done
   
