#!/bin/bash
#-------------------------------------------------------------------------------
# This is still a Work-In-Progress.
#
# The idea was to create my own script for file compare (replicate functionality
#	of linux command "diff")
#
# Usage:
#	./script.sh file_1.txt file_2.txt
# Output:
#	you will see difference between files
#------------------------------------------------------------------------------
file_1=`echo $1`
file_2=`echo $2`

function compare_char {

			original_size=`echo -n $original_line | wc -m`
                        new_size=`echo -n $new_line | wc -m`

                        original_array=()
                        new_line_array=()

                        if [[ "$original_size" -lt "$new_size" ]]; then

                                for (( s=0; s<$new_size; s++)); do
                                        new_line_char=`echo ${new_line:$s:1}`
                                        original_line_char=`echo ${original_line:$s:1}`

                                        if [ "$new_line_char" == "$original_line_char" ]; then
                                                new_line_array+=("$new_line_char")
                                                original_array+=("$original_line_char")
                                        else
                                                new_line_array+=("\033[4m$new_line_char\033[0m")
                                                original_array+=("\033[4m$original_line_char\033[0m")
                                        fi
                                done

                        elif [[ "$original_size" -gt "$new_size" ]]; then

                                for (( s=0; s<$original_size; s++)); do
                                        new_line_char=`echo ${new_line:$s:1}`
                                        original_line_char=`echo ${original_line:$s:1}`

                                        if [ "$new_line_char" == "$original_line_char" ]; then
                                                new_line_array+=("$new_line_char")
                                                original_array+=("$original_line_char")
                                        else
                                                new_line_array+=("\033[4m$new_line_char\033[0m")
                                                original_array+=("\033[4m$original_line_char\033[0m")
                                        fi
                                done

                        else

				echo $new_size
                                for (( s=0; s<$new_size; s++)); do
                                        new_line_char=`echo ${new_line:$s:1}`
                                        original_line_char=`echo ${original_line:$s:1}`
					
                                        if [ "$new_line_char" == "$original_line_char" ]; then
                                                new_line_array+=("$new_line_char")
                                                original_array+=("$original_line_char")
						echo $new_line_char equals $original_line_char
                                        else
                                                new_line_array+=("\033[4m$new_line_char\033[0m")
                                                original_array+=("\033[4m$original_line_char\033[0m")
						echo $new_line_char does not equal $original_line_char
                                        fi
                                done

                        fi

                        #original_array_bar=$(printf "%s" "${original_array[@]}")
                        #new_array_bar=$(printf "%s" "${new_line_array[@]}")
			echo ${new_line_array[*]}
			echo ${original_array[*]}
			#echo ++++++++++++++++++++++++++++++++++++++++++++++++++
                        #echo -e Line $i in file_1: $original_array_bar
                        #echo -e Line $i in file_2: $new_array_bar
}

if [ $# -eq 0 ]; then
        echo -e "Script usage: you must specify script argument ./script.sh file_1 file_2"
        echo -e "./script.sh file_1.txt file_2.txt"
        exit 0
else 
	echo "Starting to compare files..."
	echo "File 1: $file_1"
	echo "File 2: $file_2"
	sleep 1
	i=0

	file_1_lines=`cat $1 | wc -l`
	file_2_lines=`cat $2 | wc -l`

#let file_1_lines=$file_1_lines+1
#let file_2_lines=$file_2_lines+1


	if [[ "$file_1_lines" -lt "$file_2_lines" ]]; then
		echo "Warning. $2 has more lines than $1."
		echo "The script will ignore the following lines in file $2:"
		echo ------------------------------------------------------
		for (( x=$file_1_lines+1; x<=$file_2_lines; x=$x+1)); do
			skip_line=`sed -n ${x}p $2`
			echo line $x: $skip_line
		done
		echo ------------------------------------------------------
		echo Starting to compare lines...
		for line in $(cat $1); do
			let i=$i+1
			original_line=`echo -e $line`
			new_line=$(sed -n ${i}p $2)
			if [ "$original_line" = "$new_line" ]; then
				:
			else
				compare_char
			fi
		done
	elif [[ "$file_1_lines" -gt "$file_2_lines" ]]; then
		echo "Warning. $1 has more lines than $2."
		echo "The script will ignore the following lines in file $1:"
		echo ------------------------------------------------------
		echo doing from $file_2_lines to $file_1_lines
		for (( x=$file_2_lines+1; x<=$file_1_lines; x=$x+1)); do	
			skip_line=`sed -n ${x}p $1`
			echo line $x: $skip_line
		done
		echo ------------------------------------------------------
		echo Starting to compare lines...
		for line in $(cat $2); do
			let i=$i+1
			original_line=`echo -e $line`
                	new_line=$(sed -n ${i}p $1)
               	 	if [ "$original_line" = "$new_line" ]; then
                 	       :
                	else
                		compare_char
			fi
       	 	done
	else
		echo "Line count equal"
		for line in $(cat $1); do
			let i=$i+1
			original_line=$(sed -n ${i}p $1)
			new_line=$(sed -n ${i}p $2)
			if [ "$original_line" = "$new_line" ]; then
				:
				#echo "lines are equal"
			else	
				compare_char
			fi
			#echo $original_line
			#echo $new_line
			#echo --------------------------
			#sleep 5
		done
	fi

fi
