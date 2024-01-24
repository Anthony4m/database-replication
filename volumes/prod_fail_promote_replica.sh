#!/bin/bash
source /tmp/mnt/env/env.sh
echo $mode
#Check if production is down and then stops the production instance
if [[ $mode = 'production' ]]
then
echo "Start"
    sudo pg_ctlcluster 10 $this_instance_name stop
    echo "Stop PG"
    sshpass -p password ssh postgres@$replica_ip bash /tmp/mnt/prod_fail_promote_replica.sh
    mv $this_instance_var_path/recovery.done $this_instance_var_path/recovery.conf
fi

#Promote the replica database into the a production database
if [[ $mode = 'replica' ]];
then
    hostname
    pg_ctlcluster 10 $this_instance_name promote
    echo "Replica Promoted"
    tail  /var/log/postgresql/postgresql-10-$this_instance_name.log
fi