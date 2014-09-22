#!/bin/bash

MY_DATE='25'
echo "My number is: $MY_DATE"
echo ''
MY_DATE_SUM=0
for i in $(echo $MY_DATE | fold -w 1); do
        MY_DATE_SUM=$[$MY_DATE_SUM + $i]
done
#EXERCISE 1 START
echo "========================================================="
echo "STARTING EXERCISE 1..."
echo "========================================================="
for ((i=1; i<=10; i++)); do
         MY_NUMBER_1=$((((MY_DATE_SUM + RANDOM)) % 106))
         
         ipaddr="$(sed -n "${MY_NUMBER_1}p" names.txt)"
         
         if [[ "$ipaddr" ]]; then
                 echo "Got host $ipaddr"
                 find_ip_addr="$(dig $ipaddr)"
                 if [[ "$find_ip_addr" ]]; then
                         echo "Found IP: $find_ip_addr"
                         #echo "Searching for additional names..."
                         
                 else
                         echo "No IP was found for host: $ipaddr"
                 fi
         else
                 echo "Couldn't find IP"
         fi
         echo ""
done
echo "========================================================="
echo "EXERCISE 1 DONE"
echo "========================================================="
#EXERCISE 1 END
echo ''
#EXERCISE 2 START
echo "========================================================="
echo "STARTING EXERCISE 2..."
echo "========================================================="

function establish_upstream () {
         echo "$1"
}

for ((i=1; i<=20; i++)); do
       MY_NUMBER_2=$((((MY_DATE_SUM + RANDOM)) % 2000 + 400))
       ipaddr="$(sed -n "${MY_NUMBER_2}p" ips.txt)"
       if [[ "$ipaddr" ]]; then
               fixed_ipaddr=$(echo $ipaddr | grep -iPo '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}')
               if [[ "$fixed_ipaddr" ]]; then
                       echo "Got IP: $fixed_ipaddr"
                       find_ip_addr="$(dig +noall +short +answer -x $fixed_ipaddr)"
                       if [[ "$find_ip_addr" ]]; then
                               if [ "$i" -le '5' ]; then
                                        establish_upstream 'hello'
                               fi
                               echo "Found hostname: $find_ip_addr"
                               #echo "Searching for additional names..."
                       else
                               echo "No hostname was found for IP: $fixed_ipaddr"
                       fi
               else
                       echo 'Result from ips.txt is not IP address.'
               fi
       else
               echo "No result from ips.txt"
       fi
       echo ""
done
echo "========================================================="
echo "EXERCISE 2 DONE"
echo "========================================================="
#EXERCISE 2 END
echo ''
#EXERCISE 4 START
echo "========================================================="
echo "STARTING EXERCISE 4..."
echo "========================================================="
MY_NUMBER_3=$((((MY_DATE_SUM + RANDOM)) % 3228 ))
for ((i=1; i<=10; i++)); do
       ip6addr="$(sed -n "${MY_NUMBER_3}p" ips6.txt)"
       if [[ "$ip6addr" ]]; then
               echo "$ip6addr"

       else
               echo "No result from ips.txt"
       fi
       ((MY_NUMBER_3=MY_NUMBER_3 + 40))
       echo ""
done
echo "========================================================="
echo "EXERCISE 4 DONE"
echo "========================================================="
echo ''
#EXERCISE 4 END
