#!/bin/sh
psql=/usr/pgsql-11/bin/psql
pg_rewind=/usr/pgsql-11/bin/pg_rewind
pg_ctl=/usr/pgsql-11/bin/pg_ctl
DATA_CLUSTER=/var/lib/pgsql/11/data

PRIMARY_NODE_PGDATA="$1"
DEST_NODE_HOST="$2"
DEST_NODE_PGDATA="$3"
PRIMARY_NODE_PORT="$4"
DEST_NODE_ID="$5"
DEST_NODE_PORT="$6"
PRIMARY_NODE_HOST="$7"

#-- SET CUSTOM VALUE --#
RECOVERY_USER=postgres
ARCHIVEDIR=/var/lib/pgsql/11/archive
PGHOME=/usr/pgsql-11
log=/var/lib/pgsql/11/log/recovery.log
#--#

mkdir -p /var/lib/pgsql/11/log/
echo `date` : recovery_1st_stage: start >> $log

echo PRIMARY: PGDATA=$PRIMARY_NODE_PGDATA, PORT=$PRIMARY_NODE_PORT, HOSTNAME=$PRIMARY_NODE_HOST >> $log
echo DEST : PGDATA=$DEST_NODE_PGDATA, PORT=$DEST_NODE_PORT, HOSTNAME=$DEST_NODE_HOST >> $log

#- Get PostgreSQL major version
PGVERSION=`${PGHOME}/bin/initdb -V | awk '{print $3}' | sed 's/\..*//' | sed 's/\([0-9]*\)[a-zA-Z].*/\1/'`
if [ $PGVERSION -ge 12 ]; then
    RECOVERYCONF=${DEST_NODE_PGDATA}/myrecovery.conf
else
    RECOVERYCONF=${DEST_NODE_PGDATA}/recovery.conf
fi

#-bakcup recovery.conf
if [ -f $RECOVERYCONF ]; then
        mv $RECOVERYCONF $RECOVERYCONF.bak
fi

## Test passwordless SSH
ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null postgres@${DEST_NODE_HOST} -i ~/.ssh/id_rsa ls /tmp > /dev/null

if [ $? -ne 0 ]; then
    echo ERROR: basebackup.sh : passwordless SSH to postgres@${DEST_NODE_HOST} failed. Please setup passwordless SSH or Check SSH configuration. >> $log
    echo ERROR: basebackup.sh : passwordless SSH to postgres@${DEST_NODE_HOST} failed. Please setup passwordless SSH or Check SSH configuration..
    exit 1
fi

## Destination Node check server status
RECOVERY_SERVER_STATUS=`ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null postgres@$DEST_NODE_HOST -i ~/.ssh/id_rsa " 
    $pg_ctl -D $DEST_NODE_PGDATA status | xargs | cut -c 9-25
"
`

## Server ssh connection failed or Server is still running
if [ "$RECOVERY_SERVER_STATUS" == "server is running" ]; then
    echo "`date` Destination Server is still running : try again after Destination Server($DEST_NODE_HOST) stop
        command : pg_ctl -h $DEST_NODE_HOST -p $DEST_NODE_PORT -D $DEST_NODE_PGDATA stop" >> $log
    exit 1
    #ssh -T -o StrictHostKeyChecking -o UserKnownHostsFile=/dev/null postgres@$DEST_NODE_HOST -i ~/.ssh/id_rsa "
    #    $pg_ctl -D $DEST_NODE_PGdATA stop
    #" >> $log
fi

## Execute pg_basebackup to recovery Standby node
ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null postgres@$DEST_NODE_HOST -i ~/.ssh/id_rsa "

    set -o errexit

    rm -rf $DEST_NODE_PGDATA/*
    rm -rf $ARCHIVEDIR/*

    ${PGHOME}/bin/pg_basebackup -h $PRIMARY_NODE_HOST -U $RECOVERY_USER -p $PRIMARY_NODE_PORT -D $DEST_NODE_PGDATA -X stream

    cat > ${RECOVERYCONF} << EOT
standby_mode = on
primary_conninfo = 'host=${PRIMARY_NODE_HOST} port=${PRIMARY_NODE_PORT} user=${RECOVERY_USER} application_name=''server$DEST_NODE_ID'''
recovery_target_timeline = 'latest'
#restore_command = 'scp ${PRIMARY_NODE_HOST}:${ARCHIVEDIR}/%f %p'
#primary_slot_name = '${REPL_SLOT_NAME}'
EOT

if [ ${PGVERSION} -ge 12 ]; then
        sed -i -e \"\\\$ainclude_if_exists = '$(echo ${RECOVERYCONF} | sed -e 's/\//\\\//g')'\" \
               -e \"/^include_if_exists = '$(echo ${RECOVERYCONF} | sed -e 's/\//\\\//g')'/d\" ${DEST_NODE_PGDATA}/postgresql.conf
        touch ${DEST_NODE_PGDATA}/standby.signal
    else
        echo \"standby_mode = 'on'\" >> ${RECOVERYCONF}
    fi

    sed -i \"s/#*port = .*/port = ${DEST_NODE_PORT}/\" ${DEST_NODE_PGDATA}/postgresql.conf
"

if [ $? -ne 0 ]; then
    echo ERROR: basebackup.sh: Fail basebackup primary to node${DEST_NODE_ID} >> $log
    exit 1
fi


echo `date` basebackup.sh: end: recovery_1st_stage is completed successfully >> $log
exit 0
