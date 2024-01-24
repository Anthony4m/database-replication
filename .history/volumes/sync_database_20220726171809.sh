#!/bin/bash
echo $mode
#Check if production is down and then stops the production instance
if [[ $mode = 'production' ]]
then
echo "Init Syncing"
    sshpass -p password ssh postgres@$replica_ip bash /tmp/mnt/prod_fail_promote_replica.sh
fi

#Sends data difference between replica and production and vice versa
if [[ $mode = 'replica' && $rep_server_backup = 'yes' ]]
then
   sshpass -p password rsync -avz /var/lib/postgresql/10/main/* postgres@$production_ip:/var/lib/postgresql/10/main/

    echo "rsyncing"
fi