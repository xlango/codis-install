if [ $# -ne 2 ]; then
 echo -e "Usage:   ./codis_install.sh Dirpath dashbordhost  \n
example: ./codis_install.sh /opt 192.168.10.28"
 exit 1
fi

DIRPATH=$1
DASHBORDHOST=$2

tar zxvf codis.tar.gz -C $DIRPATH
mkdir -p $DIRPATH/codis/data

host=$(echo "${DIRPATH}" | sed "s/\///g")

#update config
sed -i "19s/127.0.0.1/$DASHBORDHOST/g" $DIRPATH/codis/bin/codis-proxy-admin.sh 
sed -i "12s/\/tmp\/codis/\/$host\/codis\/data/g" $DIRPATH/codis/config/dashboard.toml
sed -i "19s/\/tmp\/codis/\/$host\/codis\/data/g" $DIRPATH/codis/bin/codis-fe-admin.sh


#start codis
$DIRPATH/codis/bin/codis-dashboard-admin.sh start
$DIRPATH/codis/bin/codis-proxy-admin.sh start
$DIRPATH/codis/bin/codis-fe-admin.sh start

