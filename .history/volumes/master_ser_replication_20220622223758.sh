!/bin/bash

# before we begin:
# 1. set mode in env file
# 2. get IPs of production and replica
# 3. set IPs in env file

echo "started"

echo "next line"
mode=production
platform=docker # docker, ubuntu

echo "starting ....."

production_name=main
production_var_path=/var/lib/postgresql/10/main
production_etc_path=/etc/postgresql/10/main
production_ip=172.25.0.3 #ip a. look for eth or eth0. pick the ip that has a subnet. eg 127.20.0.3/16
production_port=5433
echo "enter password"
read password 
echo master_password = password
echo "Enter postgress user password"
passwd postgres
replica_var_path=/var/lib/postgresql/10/main
replica_etc_path=/etc/postgresql/10/main
replica_ip=172.25.0.2
replica_port=5433

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

echo /bin/bash
echo "*********************APT UPDATE************************************"
#    echo apt update
#    apt install -y sudo
    # apt install sshpass
    # sudo apt install rsync grsync

echo "done with install"
source /tmp/mnt/env.sh

# create database instance
echo "*********************CREATE DATABASE INSTANCE************************************"
    sudo pg_createcluster 10 $this_instance_name
    sudo pg_ctlcluster 10 $this_instance_name start
echo "done with cluster creating"

# set database password for postgres
echo "*********************SET DATABASE PASSWORD************************************"
sudo -u postgres psql -p $this_instance_port
  ALTER USER postgres PASSWORD 'postgres123';
#sudo psql -U postgres -d postgres -h localhost -p $this_instance_port -c "ALTER USER postgres PASSWORD 'postgres123';"

# \q

echo "done with postgres"

#Enter password for master/slave server
echo touch $this_instance_etc_path/userpass
echo "saving master password"
master_password > "$this_instance_etc_path"/userpass
 

echo "done with password"

# configure postgres.conf
echo "*********************CONFIGURE POSTGRESS CONF************************************"
sudo -H -u postgres mkdir "$this_instance_var_path"/pg_log_archive -p
sudo sed -i -e 's|#max_prepared_transactions = 0|max_prepared_transactions = 256|g' "$this_instance_etc_path"/postgresql.conf
sudo sed -i -e 's|max_connections = 100|max_connections = 288|g' "$this_instance_etc_path"/postgresql.conf
sudo sed -i -e "s|#listen_addresses = 'localhost'|listen_addresses = '*'|g" "$this_instance_etc_path"/postgresql.conf
sudo sed -i -e 's|#wal_level = replica|wal_level = replica|g' "$this_instance_etc_path"/postgresql.conf
sudo sed -i -e 's|#wal_log_hints = off|wal_log_hints = on|g' "$this_instance_etc_path"/postgresql.conf
sudo sed -i -e 's|#archive_mode = off|archive_mode = on|g' "$this_instance_etc_path"/postgresql.conf
sudo sed -i -e "s|#archive_command = ''|archive_command = 'test ! -f $this_instance_var_path/pg_log_archive/%f \&\& cp %p $this_instance_var_path/pg_log_archive/'|g" "$this_instance_etc_path"/postgresql.conf
sudo sed -i -e 's|#max_wal_senders = 10|max_wal_senders = 10|g' "$this_instance_etc_path"/postgresql.conf
sudo sed -i -e 's|#wal_keep_segments = 0|wal_keep_segments = 64|g' "$this_instance_etc_path"/postgresql.conf
sudo sed -i -e 's|#hot_standby = on|hot_standby = on|g' "$this_instance_etc_path"/postgresql.conf

echo "*********************SU************************************"
#sudo su
echo "*********************SU************************************"
source /tmp/mnt/env.sh
echo "*********************PG_HBA.CONF************************************"
sudo printf "local\treplication\trep_user\t\t\t\ttrust\t#for local replicas\n" >> "$this_instance_etc_path"/pg_hba.conf
sudo printf "host\treplication\trep_user\t$other_instance_ip/32\t\tmd5\t#for remote replicas\n" >> "$this_instance_etc_path"/pg_hba.conf

# --dbname postgresql://[username]:password@[ip]:[port]/[db_name]?password=[password]
echo "*********************CREATE REP USER************************************"
sudo psql -c "CREATE USER rep_user WITH REPLICATION LOGIN ENCRYPTED PASSWORD 'rep_user_123';" --dbname postgresql://postgres:password@localhost:$this_instance_port/postgres?password=postgres123

echo "done with creating user"

# allow postgres port through firewall
echo "*********************FIREWALL************************************"
# sudo apt install -y ufw
#sudo ufw allow from $other_instance_ip to any port $this_instance_port

sudo pg_ctlcluster 10 $this_instance_name restart


echo "***************POSTGRESS LOGIN****************************"
# sudo su - postgres
# /bin/bash
# source /tmp/mnt/env.sh

"*******************PGPASS******************************"

echo "#host:port:database:user:password" >> /var/lib/postgresql/.pgpass
echo "$other_instance_ip:$other_instance_port:replication:rep_user:rep_user_123" >> /var/lib/postgresql/.pgpass
chmod 0600 /var/lib/postgresql/.pgpass


# exit postgres user
echo exit
echo exit

# not needed
# printf "\nhost\tall\t\tall\t0.0.0.0/0\tmd5" >> "$this_instance_etc_path"/pg_hba.conf
# printf "\nhost\tall\t\tall\t::/0\t\tmd5" >> "$this_instance_etc_path"/pg_hba.conf


echo "restore_command = 'cp $this_instance_var_path/pg_log_archive/%f %p'" >> $this_instance_var_path/recovery.conf
echo "recovery_target_timeline = 'latest'" >> $this_instance_var_path/recovery.conf
echo "standby_mode = 'on'" >> $this_instance_var_path/recovery.conf
echo "primary_conninfo = 'host=$other_instance_ip port=$other_instance_port user=rep_user passfile=''/var/lib/postgresql/.pgpass'''" >> $this_instance_var_path/recovery.conf
echo "archive_cleanup_command = 'pg_archivecleanup $this_instance_var_path/pg_log_archive %r'" >> $this_instance_var_path/recovery.conf
#echo "trigger_file = '$this_instance_var_path/failover'" >> $this_instance_var_path/recovery.conf

echo chown -R postgres $this_instance_var_path

    # set as primary
    echo "*********************PRIMARY SETTING************************************"
    mv $this_instance_var_path/recovery.conf $this_instance_var_path/recovery.done

    echo pg_ctlcluster 10 $this_instance_name restart

    #echo sudo psql -U postgres -d database_name -c "CREATE TABLE student (id int);" --dbname postgresql://postgres:password@localhost:$this_instance_port
    #echo sudo psql -U postgres -d database_name -c "INSERT INTO student VALUES (1);" --dbname postgresql://postgres:password@localhost:$this_instance_port

    # sudo -u postgres psql -p - $this_instance_port
    echo "*********************CREATE DATABASES************************************"
    sudo psql -U postgres -d postgres -h localhost -p $this_instance_port -c "CREATE TABLE student (id int)"
    sudo psql -U postgres -d postgres -h localhost -p $this_instance_port -c "INSERT INTO student VALUES (1)"

    # CREATE TABLE student (id int);
    # INSERT INTO student VALUES (1);
    # \q


# if [ $mode = 'replica' ]
# then
#     sudo pg_ctlcluster 10 $this_instance_name start

#     # check the log
    sudo tail -f /var/log/postgresql/postgresql-10-$this_instance_name.log
    ^c
    # cat /var/log/postgresql/postgresql-10-$this_instance_name.log
# fi

# 
# end of replication
# 

# 
# now, switch over. a tool called repmgr
# 