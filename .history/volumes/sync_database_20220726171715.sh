#!/bin/bash
#Sends data difference between replica and production and vice versa
if [[ $mode = 'replica' && $rep_server_backup = 'yes' ]]
then
   sshpass -p password rsync -avz /var/lib/postgresql/10/main/* postgres@$production_ip:/var/lib/postgresql/10/main/

    echo "rsyncing"
fi