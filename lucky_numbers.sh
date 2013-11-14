#!/bin/bash

start=100
end=1000

while [ $start -lt $end ]; do
	
	len=`echo $start | wc -c`
	len_start=0
	
	sum=()

	while [ $len_start -lt $len ]; do
		first_digit=`echo ${start:$len_start:1}`
		sum+=("$first_digit")
	let len_start=len_start+1
	done

	sm=0
	for x in ${sum[*]}; do sm=$(( $sm + $x )); done 

	if [[ $sm -eq 7 ]]; then
		echo Lucky number $start
	fi

let start=start+1
done
