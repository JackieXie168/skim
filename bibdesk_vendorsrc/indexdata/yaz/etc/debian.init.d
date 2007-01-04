#! /bin/sh
# $Id: debian.init.d,v 1.1 2004/01/18 21:11:11 adam Exp $
# Debian sample start/stop script for YAZ Generic Frontend Server
#
set -e

DAEMON=/usr/local/bin/yaz-ztest
NAME=yaz-ztest
PIDFILE=/var/run/yaz-ztest.pid
LOGFILE=/var/log/yaz-ztest.log
RUNAS=nobody

test -x $DAEMON || exit 0

case "$1" in
  start)
    echo -n "Starting YAZ server: "
    start-stop-daemon --start --pidfile $PIDFILE \
			    --exec $DAEMON -- \
			    -u $RUNAS -l $LOGFILE -D -p $PIDFILE @:210
			  
    echo "$NAME."
    ;;
  stop)
    echo -n "Stopping YAZ server: "
    start-stop-daemon --stop --pidfile $PIDFILE \
			    --oknodo --retry 30 --exec $DAEMON
    echo "$NAME."
      ;;
  restart)
    echo -n "Restarting YAZ server: "
    start-stop-daemon --stop --pidfile $PIDFILE  \
			    --oknodo --retry 30 --exec $DAEMON
    start-stop-daemon --start --pidfile $PIDFILE d \
			    --exec $DAEMON -- \
			    -u $RUNAS -l $LOGFILE -D -p $PIDFILE @:210
    echo "$NAME."
    ;;
  reload|force-reload)
    echo "Reloading $NAME configuration files"
    start-stop-daemon --stop --pidfile $PIDFILE \
			    --signal 1 --exec $DAEMON
    ;;
  *)
    echo "Usage: /etc/init.d/$NAME {start|stop|restart|reload}"
    exit 1
    ;;
esac

exit 0
