#!/bin/sh
# ----------------------------------------------------------------------------------
#
# chkconfig: 345 55 45
# description: uwsgi server init script.
# http://projects.unbit.it/uwsgi/
# ----------------------------------------------------------------------------------
# Read source from function library. 
# All variables in 'functions' script will replace all current variables in existing shell, until script is completed.
# More info: http://ss64.com/bash/source.html
. /etc/rc.d/init.d/functions
# Declare path variables
uwsgi_exec="/usr/local/bin/uwsgi"
prog=$(basename $uwsgi_exec)
config="/etc/sysconfig/$prog"
lockfile="/tmp/${prog}.lock"
pidfile="/tmp/${prog}.pid"
logfile="/tmp/daemonize.log"
# Check if executable exists and can be executed
[ -f $uwsgi_exec ] && [ -x $uwsgi_exec ] || exit 5
# Check if config exists
[ -f $config ] || exit 6
# Define functions
start() {
    # allow root and UID=500 user to run start script
    if [ $UID -ne 0 || $UID -ne 500 ]; then
        echo "User has insufficient privilege."
        exit 4
    fi
    # can execute binary
    echo -n "Starting $prog: "
    #run $uwsgi_exec with '--ini $config' argument
    daemon $uwsgi_exec --ini $config
    retval=$?
    echo
    [ $retval -eq 0 ] && touch $lockfile
    return $retval
}

stop() {
    if [ $UID -ne 0 || $UID -ne 500 ]; then
        echo "User has insufficient privilege."
        exit 4
    fi
    
    echo -n "Stopping $prog: "
        if [ -n "`pidfileofproc $uwsgi_exec`" ]; then
                $proc --stop $pidfile
        else
                failure $"Stopping $prog"
        fi
    retval=$?
    echo
    [ $retval -eq 0 ] && rm -f $lockfile
}

restart() {
    
    if [ $UID -ne 0 || $UID -ne 500 ]; then
        echo "User has insufficient privilege."
        exit 4
    fi
    
    stop
    start
}

reload() {
    if [ $UID -ne 0 || $UID -ne 500 ]; then
        echo "User has insufficient privilege."
        exit 4
    fi
    
    echo -n "Reloading $prog: "
    if [ -n "`pidfileofproc $exec`" ]; then
            $proc --reload $pidfile
    else
            failure $"Reloading $prog"
    fi
    
    retval=$?
    echo
}

check() {
	[ -f $logfile ] || exit 6
	# Show logfile
	cat $logfile
    # We're OK!
    return 0
}

rh_status() {
    # run checks to determine if the service is running or use generic status
    status -p $pidfile $prog
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
	restart)
        restart
        ;;
    reload)
        reload
        ;;
    check)
        check
        ;;
	status)
        rh_status
        ;;
    *)
        echo "Usage: service uwsgi {start|stop|restart|reload|check|status}"
        exit 1
esac

exit 0
