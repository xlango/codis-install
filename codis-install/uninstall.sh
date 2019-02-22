if [ $# -ne 1 ]; then
 echo -e "Usage:   ./uninstall.sh Dirpath  \n
example: ./uninstall.sh /opt"
 exit 1
fi

DIRPATH=$1

#stop codis
$DIRPATH/codis/bin/codis-dashboard-admin.sh stop
$DIRPATH/codis/bin/codis-proxy-admin.sh stop
$DIRPATH/codis/bin/codis-fe-admin.sh stop

rm -rf $DIRPATH/codis
rm -rf /home/codis-data

