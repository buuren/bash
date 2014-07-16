#!/bin/bash
# place to /sbin/ifup-local
# chmod a+x /sbin/ifup-local
# for RHEL


get_ip=$(hostname -I)
if [[ ! $get_ip ]]; then
        current_mac=$(ifconfig -a | grep HWaddr | awk -F ' ' '{print $5}')

        if [[ $current_mac ]]; then
                find_eth0_number=$(grep -rin 'eth0' /etc/udev/rules.d/70-persistent-net.rules | awk -F: '{print $1}')

                if [[ $find_eth0_number ]]; then

                        cat /etc/sysconfig/network-scripts/ifcfg-eth0 | grep -qi $current_mac

                        if [ $? -eq 1 ]; then
                                grep -v "eth0" /etc/udev/rules.d/70-persistent-net.rules > /etc/udev/rules.d/70-persistent-net.rules.temp
                                mv -f /etc/udev/rules.d/70-persistent-net.rules.temp /etc/udev/rules.d/70-persistent-net.rules
                                sed -i 's/eth1/eth0/g' /etc/udev/rules.d/70-persistent-net.rules
                                sed -i "7s/.*/HWADDR=$current_mac/" /etc/sysconfig/network-scripts/ifcfg-eth0
                                reboot
                        fi
                fi

        fi
fi

# Run this part of the script only with eth0 param
if [[ "$1" == "eth0" ]]; then
        current_ip=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`

        if [[ "$current_ip" =~ "172.28" ]]; then
                sed -i '3s/.*/'${current_ip}' earchive.ucm11g earchive/' /etc/hosts
	fi

fi
