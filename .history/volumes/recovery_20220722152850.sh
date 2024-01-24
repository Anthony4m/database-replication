#!/bin/bash
source /tmp/mnt/env.sh

#Check if production is down and then stops the production instance
if [[ $mode = 'production' && $prod_status = 'down' ]]
then
    sudo pg_ctlcluster 10 $this_instance_name stop
    echo "Stop PG"
fi

#Promote the replica database into the a production database
if [[ $mode = 'replica' && $rep_stage = 'promote' ]];
then
    sudo pg_ctlcluster 10 $this_instance_name promote
    sudo tail  /var/log/postgresql/postgresql-10-$this_instance_name.log
    echo "Replica Promoted"
fi

#Moves production to replica
if [[ $mode = 'production' && $prod_status = 'up' ]]
then
    sudo mv $this_instance_var_path/recovery.done $this_instance_var_path/recovery.conf
    echo "Moved to recovery.conf"
fi

#Sends data difference between replica and production and vice versa
if [[ $mode = 'replica' && $rep_server_backup = 'yes' ]]
then
   sshpass -p password rsync -avz /var/lib/postgresql/10/main/* postgres@$production_ip:/var/lib/postgresql/10/main/

    echo "rsyncing"
fi

if [[ $mode = 'production' && $prod_server_start = 'yes' ]]
then
    sudo pg_ctlcluster 10 $this_instance_name start
    sudo tail -f /var/log/postgresql/postgresql-10-$this_instance_name.log
fi

if [[ $mode = 'replica' && $prod_status = 'up' ]];
then
    sudo tail -f /var/log/postgresql/postgresql-10-$this_instance_name.log
fi

# --------------------------------------------- End of recovery -------------------------------------------------------------