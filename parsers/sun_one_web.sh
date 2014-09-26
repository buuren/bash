#!/bin/bash
start=`date +%s`
MY_DATE='22/Sep/2014'
LOG_FILE='access.201409230000'
HOURS_REQUESTS_ARRAY=()
MINUTES_REQUESTS_ARRAY=()

echo "Getting statistics for $MY_DATE..."
#=======================================================================================================
for each_log_file in `ls | grep access`; do
    for each_hour in {0..23}; do

        if [ "$each_hour" -lt 10 ]; then
              new_each_hour="0$each_hour"
        else
              new_each_hour="$each_hour"
        fi

        http_counter=$(grep "$MY_DATE:$new_each_hour" "$each_log_file" | wc -l)
        
        if [ ${HOURS_REQUESTS_ARRAY[$each_hour]} ]; then
             let new_value=HOURS_REQUESTS_ARRAY[$each_hour]+$http_counter
             HOURS_REQUESTS_ARRAY[$each_hour]=$new_value
        else
             HOURS_REQUESTS_ARRAY[$each_hour]=$http_counter
        fi

    done
    
done

highest_hour_value=$(printf "%d\n" ${HOURS_REQUESTS_ARRAY[@]} | sort -n | tail -n1)
lowest_hour_value=$(printf "%d\n" ${HOURS_REQUESTS_ARRAY[@]} | sort -n | head -1)

for (( i = 0; i < ${#HOURS_REQUESTS_ARRAY[@]}; i++ )); do
   if [ "${HOURS_REQUESTS_ARRAY[$i]}" = "${lowest_hour_value}" ]; then
      lowest_hours=$i
   fi
   
   if [ "${HOURS_REQUESTS_ARRAY[$i]}" = "${highest_hour_value}" ]; then
      highest_hours=$i
   fi

done

total_hour_requests=0
hours_counter=0
for i in ${HOURS_REQUESTS_ARRAY[@]}; do
    echo "$hours_counter;$i"
    let total_hour_requests+=$i
    let hours_counter+=1
done

echo "Total amount of requests: $total_hour_requests"
echo "Lowest amount of HTTP requests at $lowest_hours:00 -> $lowest_hour_value"
echo "Highest amount of HTTP requests at $highest_hours:00 -> $highest_hour_value"

hour_array_len=${#HOURS_REQUESTS_ARRAY[@]}
average_hour_requests=$((total_hour_requests / hour_array_len ))
echo "Average amount of HTTP requests per hour: $average_hour_requests"

#=======================================================================================================
echo "Getting statistics for $highest_hours:00 - $highest_hours:59..."
for each_log_file in `ls | grep access`; do
    for each_minute in {0..59}; do
    
        new_each_hour=$highest_hours

        if [ "$new_each_hour" -lt 10 ]; then
              new_each_hour="0$new_each_hour"
        else
              new_each_hour="$new_each_hour"
        fi

        if [ "$each_minute" -lt 10 ]; then
              new_each_minute="0$each_minute"
        else
              new_each_minute="$each_minute"
        fi
        #echo "$MY_DATE:$new_each_hour:$new_each_minute"
        http_counter=$(grep "$MY_DATE:$new_each_hour:$new_each_minute" "$each_log_file" | wc -l)
        
        if [ ${MINUTES_REQUESTS_ARRAY[$each_minute]} ]; then
             let new_value=MINUTES_REQUESTS_ARRAY[$each_minute]+$http_counter
             MINUTES_REQUESTS_ARRAY[$each_minute]=$new_value
        else
             MINUTES_REQUESTS_ARRAY[$each_minute]=$http_counter
        fi
    done
done

highest_minute_value=$(printf "%d\n" ${MINUTES_REQUESTS_ARRAY[@]} | sort -n | tail -n1)
lowest_minute_value=$(printf "%d\n" ${MINUTES_REQUESTS_ARRAY[@]} | sort -n | head -1)

for (( i = 0; i < ${#MINUTES_REQUESTS_ARRAY[@]}; i++ )); do
   if [ "${MINUTES_REQUESTS_ARRAY[$i]}" = "${lowest_minute_value}" ]; then
      lowest_minutes=$i
   fi
   
   if [ "${MINUTES_REQUESTS_ARRAY[$i]}" = "${highest_minute_value}" ]; then
      highest_minutes=$i
   fi

done

total_minutes_requests=0
minutes_counter=0
for i in ${MINUTES_REQUESTS_ARRAY[@]}; do
    echo "$minutes_counter;$i"
    let total_minutes_requests+=$i
    let minutes_counter+=1
done

echo "Total amount of requests during $highest_hours:00 - $highest_hours:59 ->  $total_minutes_requests"
echo "Lowest amount of HTTP requests at $lowest_minutes -> $lowest_minute_value"
echo "Highest amount of HTTP requests at $highest_minutes -> $highest_minute_value"

minutes_array_len=${#MINUTES_REQUESTS_ARRAY[@]}
average_minutes_requests=$((total_minutes_requests / minutes_array_len ))
echo "Average amount of HTTP requests per hour: $average_minutes_requests"

end=`date +%s`
runtime=$((end-start))
echo "Completed in $runtime seconds"
