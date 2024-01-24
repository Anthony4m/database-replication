#!/bin/bash
source /tmp/mnt/env/env.sh
#Moves production to replica
echo $mode
if [[ $mode = 'production' ]]
then
    sudo mv $this_instance_var_path/recovery.conf $this_instance_var_path/recovery.done
    echo "Promoted production"
    sudo pg_ctlcluster 10 $this_instance_name restart
    sshpass -p password ssh postgres@$replica_ip bash /tmp/mnt/promote_prod.sh
    
fi

if [[ $mode = 'replica' ]]
then
    #use this on an actual server
    # sudo mv $this_instance_var_path/recovery.done $this_instance_var_path/recovery.conf
    # Use this on docker
    mv $this_instance_var_path/recovery.done $this_instance_var_path/recovery.conf
    echo "Demote Replica"
    
    #use this on an actual server 
    #  pg_ctlcluster 10 $this_instance_name restart
    #use this on docker
    pg_ctlcluster 10 $this_instance_name restart
fi

# sudo tail -f /var/log/postgresql/postgresql-10-$this_instance_name.log
tail -f /var/log/postgresql/postgresql-10-$this_instance_name.log