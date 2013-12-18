#!/bin/bash
# Bash script to fix IP conflict issue after importing
# and automatically run all services which are required
# for UCM11g. Run this after restarting machine.

current_user=`awk -v val="$UID" -F ":" '$3==val{print $1}' /etc/passwd`

if [[ "$current_user" == "root" ]]; then
        echo "Don't run as root."
        exit 1
else
        current_ip=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`

        if [[ "$current_ip" =~ "192.168" ]]; then
                ip_in_xml=`less $OLDPWD/cs-ds-jdbc.xml | grep -oP '(?<=@).*(?=:1521)'`

                if [ $current_ip == $ip_in_xml ]; then
                        echo "IP is OK"
                else
                        echo "Chaning XML..."
                        nano_time=`date +"%Y-%m-%d_%H-%M-%S"`
                        #backup existing file before modifying it
                        cp $OLDPWD/cs-ds-jdbc.xml $OLDPWD/cs-ds-jdbc_$nano_time.xml
                        sed -i "s/$ip_in_xml/$current_ip/Ig" $OLDPWD/cs-ds-jdbc.xml
                fi

                echo "Starting database..."
                oracle_bin="/u01/app/oracle/product/11.2.0/db_1/bin"
                db_sysuser="sys"
                db_syspass="123abc"
                sqlplus_connect="$oracle_bin/sqlplus $db_sysuser/$db_syspass as sysdba"
                echo "startup" | $sqlplus_connect
                echo "Done"
                echo "Starting listener..."
                $oracle_bin/lsnrctl start
                echo "Done"
                echo "Starting Enterprise manager.."
                $oracle_bin/emctl start dbconsole
                echo "Done"
                echo "Starting Weblogic..."
                $MW_HOME/user_projects/domains/oracle7.ucm11g/bin/startWebLogic.sh &
                sleep 30
                echo "Done"
                echo "Starting nodemanager..."
                $MW_HOME/wlserver_10.3/server/bin/startNodeManager.sh &
                sleep 10
                echo "Done"
                echo "------------------------------------------------------"
                ip_address=$(hostname -I)
                echo "Login: http://$ip_address:7001/console"
        else
                echo "Bad IP"
        fi
fi
