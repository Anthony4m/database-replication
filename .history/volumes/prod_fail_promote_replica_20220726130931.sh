#!/bin/bash
# source /tmp/mnt/env.sh

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