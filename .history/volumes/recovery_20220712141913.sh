#!/bin/bash
source /tmp/mnt/env.sh

if [[ $mode = 'production' && $prod_status = 'down' ]]
then
    sudo pg_ctlcluster 10 $this_instance_name stop
    echo "Stop PG"
fi

if [[ $mode = 'replica' && $rep_stage = 'promote' ]];
then
    sudo pg_ctlcluster 10 $this_instance_name promote
    # sshpass -f /etc/postgresql/10/main/userpass rsync -avz /var/lib/postgresql/10/main/* postgres@$production_ip:/var/lib/postgresql/10/main/
    # sshpass -p 'password' rsync -avz /var/lib/postgresql/10/main/* postgres@$production_ip:/var/lib/postgresql/10/main/
    sudo tail -f /var/log/postgresql/postgresql-10-$this_instance_name.log
    echo "Replica Promoted"
fi

if [[ $mode = 'production' && $prod_status = 'up' ]]
then
    sudo mv $this_instance_var_path/recovery.done $this_instance_var_path/recovery.conf
    echo "Moved to recovery.conf"
    #sshpass -f $this_instance_etc_path/userpass rsync -avz /var/lib/postgresql/10/main/* postgres@this_instance_ip=$replica_ip:/var/lib/postgresql/10/main/
    # sudo pg_ctlcluster 10 $this_instance_name start
    # sudo tail -f /var/log/postgresql/postgresql-10-$this_instance_name.log
fi

if [[ $mode = 'replica' && $server_backup = 'yes' ]]
then
   sshpass -f $this_instance_etc_path/userpass rsync -avz /var/lib/postgresql/10/main/* postgres@$production_ip:/var/lib/postgresql/10/main/

    echo "rsyncing"

    #sshpass -f $this_instance_etc_path/userpass rsync -avz /var/lib/postgresql/10/main/* postgres@this_instance_ip=$replica_ip:/var/lib/postgresql/10/main/
    # sudo pg_ctlcluster 10 $this_instance_name start
    # sudo tail -f /var/log/postgresql/postgresql-10-$this_instance_name.log
fi

if [[ $mode = 'production' && $prod_server_start = 'yes' ]]
then
    # sshpass -f $this_instance_etc_path/userpass rsync -avz /var/lib/postgresql/10/main/* postgres@this_instance_ip=$replica_ip:/var/lib/postgresql/10/main/
    #sshpass -f $this_instance_etc_path/userpass rsync -avz /var/lib/postgresql/10/main/* postgres@this_instance_ip=$replica_ip:/var/lib/postgresql/10/main/
    sudo pg_ctlcluster 10 $this_instance_name start
    sudo tail -f /var/log/postgresql/postgresql-10-$this_instance_name.log
fi

if [[ $mode = 'replica' && $prod_status = 'up' ]];
then
    # sudo mv $this_instance_var_path/recovery.done $this_instance_var_path/recovery.conf

    # sudo pg_ctlcluster 10 $this_instance_name start
    sudo tail -f /var/log/postgresql/postgresql-10-$this_instance_name.log
fi
