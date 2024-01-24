#!/bin/bash
source /tmp/mnt/env/env.sh
echo $mode
#Check if production is down and then stops the production instance
if [[ $mode = 'production' ]]
then
echo "Demoting ..........."
    # sshpass -p password ssh postgres@$replica_ip bash /tmp/mnt/sync_database.sh
    mv $this_instance_var_path/recovery.done $this_instance_var_path/recovery.conf
    echo "Init Syncing........"
    sshpass -p password rsync -avz --stats postgres@$replica_ip:$this_instance_var_path/* $this_instance_var_path/
    sudo pg_ctlcluster 10 $this_instance_name restart
    tail  /var/log/postgresql/postgresql-10-$this_instance_name.log

fi

#Sends data difference between replica and production and vice versa
if [[ $mode = 'replica' ]]
then
   sshpass -p password rsync -avz $this_instance_var_path/* postgres@$production_ip:$this_instance_var_path/

    echo "rsyncing"
fi