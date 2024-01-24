#!/bin/bash
source /tmp/mnt/env.sh
#Moves production to replica
if [[ $mode = 'production' && $prod_status = 'stable' ]]
then
    sudo mv $this_instance_var_path/recovery.conf $this_instance_var_path/recovery.done
    echo "Moved to recovery.conf"
fi