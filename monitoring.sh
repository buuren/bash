#!/bin/bash
#---------------------------------------------
# Example of script for monitoring
# 

start=1
end=1000

while [ $start -lt $end ]; do

  log_dir="/logs/$(date +%Y)/$(date +%m)/"
  for log in "$log_dir"/*; do
  	if echo "$log" | grep -q '.log$'; then
  		real_log=$log
  	fi
  done
  if [ $# -eq 0 ]; then
  	echo -e "Script usage: you must specify script argument ./script.sh ARG where ARG is:"
  	echo -e "\t1 - read log file\n\t2 - ping error hosts\n\t3 - something else\n\t4 - something else"
  	echo -e "For example:\n\t ./parse-log.sh 2"
  	exit 0
  elif [ $1 -eq 1 ]; then
  	echo "$real_log"
  	less $real_log
  elif [ $1 -eq 2 ]; then
  	ERRORS=()
  	if [ ! -f $real_log ]; then
  		echo "Log file does not exist. Exit"
  		exit 0
  	elif [[ ! -s $real_log ]]; then
  		echo "$real_log is empty. Exit"
  		exit 0
  	else
  		while read line; do
  			if [[ "$line" == *"network error"* ]]; then
  				if [[ "${ERRORS[*]}" =~ "$line" ]]; then
  					:
  				else
  					ERRORS+=("$line")
  				fi
  			fi	
  		done < $real_log
  			if [ ${#ERRORS[@]} = 0 ]; then
  				echo "Array is empty. No errors in the log"
  				exit 0
  			else
  				echo "Starting to ping servers..."
  				for e in "${ERRORS[@]}"; do
  					#echo "$each_server"
  					e=$(echo "$e" | grep -iPo '(?<=\().*(?=\))' | sed 's/:80//')
  					#echo "$e"
  					lost_packets=$(ping -c 4 "$e" | grep 'received' | awk -F ',' '{print $3}' | awk -F ' ' '{print"\t",$1}' | tr -d '%')
  					failed_counter=$(cat $real_log | grep "Update had a network error ($e:80)" | wc -l)
  					if [ $lost_packets -eq 100 ]; then
  						echo -e "\e[1;38;5;15;48;5;1m $e: 100% PACKETS LOSS. CONTACT HELP DESK. \e[0m. Occured: $failed_counter times"
  						echo "$e" | mail -s "CURRENCY TABLE REPORT:" your.mail@yourmail.com
  					elif [ $lost_packets -eq 75 ]; then
  						echo -e "\e[1;38;5;15;48;5;208m $e: 75% packet loss \e[0m. Occured: $failed_counter times"
  					elif [ $lost_packets -eq 50 ]; then
  						echo -e "\e[1;38;5;16;48;5;226m $e: 50% packet loss \e[0m. Occured: $failed_counter times"
  					elif [ $lost_packets -eq 25 ]; then
  						echo -e "\e[1;38;5;16;48;5;87m $e: 25% packet loss \e[0m. Occured: $failed_counter times"
  					elif [ $lost_packets -eq 0 ]; then
  						echo -e "\e[1;38;5;16;48;5;46m $e: 0% packet loss \e[0m. Occured: $failed_counter times"
  					else
  						echo "Unknown output"
  					fi 
  				done
  
  				echo "Done."
  			fi
  	fi
  elif [ $1 -eq 3 ]; then
  	echo "3 is not ready yet"
  elif [ $1 -eq 4 ]; then
  	echo "4 is not ready yet"
  else
  	echo "Wrong param. Launch script again"
  fi
  
  sleep 1200
  let start=start+1
  
done
