mode=replica # production, replica
platform=docker # docker, ubuntu
prod_status=down #up/down
prod_stage=demote #promote/demote
rep_stage=demote #promote/demote
prod_server_start=no #yes/no
server_backup=no #yes/no

production_name=main
production_var_path=/var/lib/postgresql/10/main
production_etc_path=/etc/postgresql/10/main
production_ip=172.21.0.4 #ip a. look for eth or eth0. pick the ip that has a subnet. eg 127.20.0.3/16
production_port=5433

replica_name=main
replica_var_path=/var/lib/postgresql/10/main
replica_etc_path=/etc/postgresql/10/main
replica_ip=172.21.0.3
replica_port=5433

cd /tmp/mnt

if [ $mode = 'production' ]
then
    this_instance_name=$production_name
    this_instance_var_path=$production_var_path
    this_instance_etc_path=$production_etc_path
    this_instance_ip=$production_ip
    this_instance_port=$production_port
    
    other_instance_name=$replica_name
    other_instance_path=$replica_var_path
    other_instance_etc_path=$replica_etc_path
    other_instance_ip=$replica_ip
    other_instance_port=$replica_port
elif [ $mode = 'replica' ]
then
    this_instance_name=$replica_name
    this_instance_var_path=$replica_var_path
    this_instance_etc_path=$replica_etc_path
    this_instance_ip=$replica_ip
    this_instance_port=$replica_port
    
    other_instance_name=$production_name
    other_instance_path=$production_var_path
    other_instance_etc_path=$production_etc_path
    other_instance_ip=$production_ip
    other_instance_port=$production_port
fi
