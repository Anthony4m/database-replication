#!/bin/bash
source /tmp/mnt/env.sh
#Moves production to replica
if [[ $mode = 'production' && $prod_status = 'stable' ]]
then
    sudo mv $this_instance_var_path/recovery.conf $this_instance_var_path/recovery.done
    echo "Promoted production"
    sshpass -p password ssh postgres@$replica_ip /tmp/mnt/promote_prod.sh
fi

if [[ $mode = 'replica' && $prod_status = 'stable' ]]
then
    sudo mv $this_instance_var_path/recovery.done $this_instance_var_path/recovery.conf
    echo "Demote Replica"
    sshpass -p password rsync -avz /var/lib/postgresql/10/main/* postgres@$production_ip:/var/lib/postgresql/10/main/

    echo "rsyncing"

fi