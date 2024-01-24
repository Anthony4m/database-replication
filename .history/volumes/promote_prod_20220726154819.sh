#!/bin/bash
source /tmp/mnt/env.sh
#Moves production to replica
if [[ $mode = 'production' ]]
then
    # sudo mv $this_instance_var_path/recovery.conf $this_instance_var_path/recovery.done
    echo "Promoted production"
    # sshpass -p password ssh postgres@$replica_ip ./tmp/mnt/promote_replica_path.sh
    sshpass -p srv_epareto2020 ssh ghs@51.89.37.111 touch testfile
    # sudo pg_ctlcluster 10 $this_instance_name restart
fi

# if [[ $mode = 'replica' ]]
# then
#     sudo mv $this_instance_var_path/recovery.done $this_instance_var_path/recovery.conf
#     echo "Demote Replica"
    
#     sudo pg_ctlcluster 10 $this_instance_name restart
# fi

# sudo tail -f /var/log/postgresql/postgresql-10-$this_instance_name.log