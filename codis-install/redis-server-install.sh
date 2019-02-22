if [ $# -ne 7 ]; then
 echo -e "Usage:   ./redis-server-install.sh Dirpath ip dashbordip  masterport slaveport sentinelport groupid \n
 example: ./redis-server-install.sh /opt 192.168.10.28 192.168.10.29  6379 16379 26379 1"
 exit 1
fi

DIRPATH=$1
IP=$2
DASHBORDIP=$3
MASTERPORT=$4
SLAVEPORT=$5
SENTINELPORT=$6
GID=$7


#add codis redis group
gids=`$DIRPATH/codis/bin/codis-admin --dashboard=$IP:18080 --list-grou`
isgid=$(echo $gids | grep "\"id\": ${GID}")
if [[ "$isgid" != "" ]]
then
    echo "[error]group id already exists"
else
    $DIRPATH/codis/bin/codis-admin --dashboard=$DASHBORDIP:18080 --create-group --gid=$GID
    echo "create group id $GID success"
fi

#update redis server config
mkdir -p $DIRPATH/redis/$MASTERPORT/
cp redis/* $DIRPATH/redis/$MASTERPORT/
REDISDIR=$DIRPATH/redis/$MASTERPORT/
host=$(echo "${DIRPATH}" | sed "s/\///g")
sed -i "1s/127.0.0.1/$IP/g" $REDISDIR/redis-master.conf
sed -i "1s/127.0.0.1/$IP/g" $REDISDIR/sentinel.conf
sed -i "\$s/127.0.0.1/$IP/g" $REDISDIR/sentinel.conf
sed -i "1s/127.0.0.1/$IP/g" $REDISDIR/redis-slave.conf
sed -i "\$s/127.0.0.1/$IP/g" $REDISDIR/redis-slave.conf
sed -i "s/\/tmp/\/$host\/redis\/$MASTERPORT/g" $REDISDIR/redis-master.conf
sed -i "s/\/tmp/\/$host\/redis\/$MASTERPORT/g" $REDISDIR/redis-slave.conf
sed -i "s/\/tmp/\/$host\/redis\/$MASTERPORT/g" $REDISDIR/sentinel.conf
sed -i "s/6379/$MASTERPORT/g" $REDISDIR/redis-master.conf
sed -i "s/16379/$SLAVEPORT/g" $REDISDIR/redis-slave.conf
sed -i "s/26379/$SENTINELPORT/g" $REDISDIR/sentinel.conf

#start redis master slave sentinel
$DIRPATH/codis/bin/codis-server $DIRPATH/redis/$MASTERPORT/redis-master.conf
$DIRPATH/codis/bin/codis-server $DIRPATH/redis/$MASTERPORT/redis-slave.conf
$DIRPATH/codis/bin/redis-sentinel   $DIRPATH/redis/$MASTERPORT/sentinel.conf

#add cluster
$DIRPATH/codis/bin/codis-admin --dashboard=$DASHBORDIP:18080  --group-add  --gid=$GID --addr=$IP:$MASTERPORT
$DIRPATH/codis/bin/codis-admin --dashboard=$DASHBORDIP:18080  --group-add  --gid=$GID --addr=$IP:$SLAVEPORT
$DIRPATH/codis/bin/codis-admin --dashboard=$DASHBORDIP:18080  --sync-action  --create --addr=$IP:$MASTERPORT
$DIRPATH/codis/bin/codis-admin --dashboard=$DASHBORDIP:18080  --sync-action  --create --addr=$IP:$SLAVEPORT
$DIRPATH/codis/bin/codis-admin --dashboard=$DASHBORDIP:18080  --sentinel-add   --addr=$IP:$SENTINELPORT
$DIRPATH/codis/bin/codis-admin --dashboard=$DASHBORDIP:18080  --sentinel-resync
$DIRPATH/codis/bin/codis-admin --dashboard=$DASHBORDIP:18080  --rebalance
