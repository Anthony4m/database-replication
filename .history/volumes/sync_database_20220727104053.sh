#!/bin/bash
source /tmp/mnt/env/env.sh
echo $mode
#Check if production is down and then stops the production instance
if [[ $mode = 'production' ]]
then
echo "Init Syncing"
    sshpass -p password ssh postgres@$replica_ip bash /tmp/mnt/sync_database.sh
fi

#Sends data difference between replica and production and vice versa
if [[ $mode = 'replica' ]]
then
   sshpass -p password rsync -chavzP /var/lib/postgresql/10/main/* postgres@$production_ip:/var/lib/postgresql/10/main/

    echo "rsyncing"
fi