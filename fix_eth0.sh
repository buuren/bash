#!/bin/bash
# place to /sbin/ifup-local
# chmod a+x /sbin/ifup-local

#global script
get_ip=$(hostname -I)

if [[ ! $get_ip ]]; then
        current_mac=$(ifconfig -a | grep HWaddr | awk -F ' ' '{print $5}')

        mac_in_config=$(cat /etc/sysconfig/networking/devices/ifcfg-eth0 | grep HWADDR | awk -F '=' '{print $2}')

        if [[ $current_mac != $mac_in_config ]]; then
		
		
                rm /etc/udev/rules.d/70-persistent-net.rules
                #sed -i '2s/.*/HWADDR='${current_mac}'/' /etc/sysconfig/networking/devices/ifcfg-eth0
                sed -i '2s/.*/HWADDR='${current_mac}'/' /etc/sysconfig/network-scripts/ifcfg-eth0
				
                reboot
        fi
fi

# Only for eth0
if [[ "$1" == "eth0" ]]; then

while true; do

        current_ip=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`

        if [[ "$current_ip" =~ "172.28" ]]; then
                sed -i '3s/.*/'${current_ip}' earchive.ucm11g earchive/' /etc/hosts
                exit 1
        else
                sleep 5
        fi

done

fi
