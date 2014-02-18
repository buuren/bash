#!/bin/bash

if [ $# -eq 0 ]; then
		echo "Script usage: you must..."
		exit
elif [ $# -eq 1 ]; then
		echo "must be 2 params..."
		exit
elif [ $#  -eq 2 ]; then

	if ! [[ $1  =~ ^[0-9]+$ ]]; then
		echo "first must be an integer"
		exit
	elif [[ $1 == 0 ]]; then
		echo "cant be 0"
		exit
	elif ! [[ $2 =~ ^[A-Za-z]+$ ]]; then
		echo "2nd param must be string"
		exit
	else

		basedir="/home/www"

		for ((i=1; i<=$1; i++)); do
			foldername="$2$i"
			mkdir "$basedir/$foldername"

			for ((x=1; x<=$1; x++)); do
				filename="$basedir/$foldername/$foldername"_"$2$x"

				for ((p=$1; p>=1; p--)); do
					printf "$p" >> "$filename"
				done

				echo -e "\n$filename" >> "$filename"

			done

		done

	fi
	
fi
