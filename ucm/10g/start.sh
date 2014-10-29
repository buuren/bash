#!/bin/bash
# bash script start ucm 10g

current_user=`awk -v val="$UID" -F ":" '$3==val{print $1}' /etc/passwd`

if [[ "$current_user" == "root" ]]; then
        echo "Don't run as root."
        echo "su - oracle"
        exit 1
else
        current_ip=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`

        if [[ "$current_ip" =~ "192.28" ]]; then

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
                echo "Starting Admin server..."
                /oracle/ucm/server/admin/etc/idcadmin_start
                echo "Done"
                echo "Starting UCM server..."
                /oracle/ucm/server/etc/idcserver_start
                echo "Done"
                echo "------------------------------------------------------"
                ip_address=$(hostname -I)
                echo "Login: http://$ip_address"
        else
                echo "Bad IP"
        fi
fi
