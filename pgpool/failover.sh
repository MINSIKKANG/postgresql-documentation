#failover_command = '/etc/pgpool-II/failover.sh %d %h %p %D %m %M %H %P %r %R'
#failover.sh
if [ $# -ne 10 ]; then
        echo "argument not matched (10): failover.sh failed_node_id fail_node_hostname fail_node_port fail_node_database_cluster_path new_main_id new new_main_hostname old_main_id old_primary_id new_main_port new_main_database_cluster_path"
        exit 1
fi

FAILED_NODE_ID=$1
FAILED_NODE_HOST=$2
FAILED_NODE_PORT=$3
FAILED_NODE_DATABASE_CLUSTER_PATH=$4
NEW_MASTER_ID=$5
OLD_MAIN_NODE_ID=$6
NEW_MASTER_HOST=$7
OLD_PRIMARY_NODE_ID=$8
NEW_MAIN_NODE_PORT=$9
NEW_MAIN_NODE_DATABASE_CLUSTER_PATH=${10}

pg_ctl=/usr/pgsql-11/bin/pg_ctl
DATA_CLUSTER=/var/lib/pgsql/11/data
log=/var/lib/pgsql/11/log/failover.log

mkdir -p /var/lib/pgsql/11/log

# Do nothing if standby server goes down
echo "[LOG] failover.sh :New Primary Server :$NEW_MAIN_NODE_DATABASE_CLUSTER_PATH" >> $log
NEW_MASTER_STATUS=`ssh -T postgres@$NEW_MASTER_HOST $pg_ctl status -D $NEW_MAIN_NODE_DATABASE_CLUSTER_PATH | xargs | cut -c 9-25`
if [ "$NEW_MASTER_STATUS" != "server is running" ]; then
        echo "[ERROR] New Primary Server is downed or Not find Primary Server; $(date) \n" >> $log
        exit 1
fi
echo "[LOG] NEW MASTER $NEW_MASTER_STATUS" >> $log

echo "failover.sh FAILED_NODE:id=${FAILED_NODE_ID}, host=${FAILED_NODE_HOST}; NEW_MASTER:id=${NEW_MASTER_ID},host=${NEW_MASTER_HOST}; at $(date)\n" >> $log

#sudo -u postgres ssh -T postgres@${NEW_MASTER} touch $TRIGGER_FILE

echo ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null postgres@$NEW_MASTER_HOST $pg_ctl -D $NEW_MAIN_NODE_DATABASE_CLUSTER_PATH promote >>$log  # let standby take over
ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
         postgres@$NEW_MASTER_HOST $pg_ctl -D $NEW_MAIN_NODE_DATABASE_CLUSTER_PATH  promote       # let standby take over

sleep 2

if [ $? -ne 0 ]; then
        echo ERROR: failover.sh: end: failover failed
        exit 1
fi

echo "`date` failover.sh: end: failover success; node${FAILED_NODE_ID} -> node${NEW_MASTER_ID}" >> $log
echo "`date` failover.sh: end: failover success; node${FAILED_NODE_ID} -> node${NEW_MASTER_ID};"

exit 0
