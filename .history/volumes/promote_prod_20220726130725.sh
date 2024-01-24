#!/bin/bash
source /tmp/mnt/env.sh
#Moves production to replica
if [[ $mode = 'production' && $prod_status = 'stable' ]]
then
    sudo mv $this_instance_var_path/recovery.conf $this_instance_var_path/recovery.done
    echo "Promoted production"
    sshpass -p password ssh postgres@$replica_ip /tmp/mnt/promote_prod.sh
    sudo pg_ctlcluster 10 $this_instance_name restart
fi

if [[ $mode = 'replica' && $prod_status = 'stable' ]]
then
    sudo mv $this_instance_var_path/recovery.done $this_instance_var_path/recovery.conf
    echo "Demote Replica"
    
    sudo pg_ctlcluster 10 $this_instance_name restart

    sudo tail -f /var/log/postgresql/postgresql-10-$this_instance_name.log


fi