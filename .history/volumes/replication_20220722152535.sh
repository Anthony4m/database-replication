#!/bin/bash

# before we begin:
# 1. set mode in env file
# 2. get IPs of production and replica
# 3. set IPs in env file

/bin/bash

if [ $platform = 'docker' ]
then
    apt update
    apt install -y sudo
    apt install sshpass
    sudo apt install rsync grsync
    sudo apt install openssh-server
    sudo apt-get install openssh-client
    sudo service ssh start

fi

source /tmp/mnt/env.sh

# create database instance
if [ $mode = 'replica' -o $platform = 'docker' ]
then
    sudo pg_createcluster 10 $this_instance_name
    sudo pg_ctlcluster 10 $this_instance_name start
fi

# set database password for postgres
sudo -u postgres psql -p $this_instance_port
ALTER USER postgres PASSWORD 'postgres123';
\q

touch $this_instance_etc_path/userpass
echo "enter password for postgres user"
read postgres_password
echo $postgres_password > $this_instance_etc_path/userpass
# configure postgres.conf
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

sudo su
source /tmp/mnt/env.sh

sudo printf "local\treplication\trep_user\t\t\t\ttrust\t#for local replicas\n" >> "$this_instance_etc_path"/pg_hba.conf
sudo printf "host\treplication\trep_user\t$other_instance_ip/32\t\tmd5\t#for remote replicas\n" >> "$this_instance_etc_path"/pg_hba.conf

# --dbname postgresql://[username]:password@[ip]:[port]/[db_name]?password=[password]
sudo psql -c "CREATE USER rep_user WITH REPLICATION LOGIN ENCRYPTED PASSWORD 'rep_user_123';" --dbname postgresql://postgres:password@localhost:$this_instance_port/postgres?password=postgres123

passwd postgres

# allow postgres port through firewall
sudo apt install -y ufw
sudo ufw allow from $other_instance_ip to any port $this_instance_port

sudo pg_ctlcluster 10 $this_instance_name restart

# clean directory of db instance
if [ $mode = 'replica' ]
then
    sudo su
    source /tmp/mnt/env.sh
    cd "$this_instance_var_path"
    sudo find . -name . -o -prune -exec rm -rf -- {} +
    exit
fi

sudo su - postgres
/bin/bash
source /tmp/mnt/env.sh

echo "#host:port:database:user:password" >> /var/lib/postgresql/.pgpass
echo "$other_instance_ip:$other_instance_port:replication:rep_user:rep_user_123" >> /var/lib/postgresql/.pgpass
chmod 0600 /var/lib/postgresql/.pgpass

# exit postgres user
exit
exit

#backup production database
if [ $mode = 'replica' ]
then
    pg_basebackup --dbname postgresql://rep_user:password@$other_instance_ip:$other_instance_port/postgres?password=rep_user_123 -D $this_instance_var_path
fi

# Create a recovery.conf file
echo "restore_command = 'cp $this_instance_var_path/pg_log_archive/%f %p'" >> $this_instance_var_path/recovery.conf
echo "recovery_target_timeline = 'latest'" >> $this_instance_var_path/recovery.conf
echo "standby_mode = 'on'" >> $this_instance_var_path/recovery.conf
echo "primary_conninfo = 'host=$other_instance_ip port=$other_instance_port user=rep_user passfile=''/var/lib/postgresql/.pgpass'''" >> $this_instance_var_path/recovery.conf
echo "archive_cleanup_command = 'pg_archivecleanup $this_instance_var_path/pg_log_archive %r'" >> $this_instance_var_path/recovery.conf

#Give postgres user permission over var/postgresql folder
chown -R postgres $this_instance_var_path

#Create a table and insert data into production not needed if you already have data in production database
if [ $mode = 'production' ]
then
    # set as primary
    mv $this_instance_var_path/recovery.conf $this_instance_var_path/recovery.done

    pg_ctlcluster 10 $this_instance_name restart

    sudo -u postgres psql -p $this_instance_port
    CREATE TABLE student (id int);
    INSERT INTO student VALUES (1);
    \q
fi

#Start 
if [ $mode = 'replica' ]
then
    sudo pg_ctlcluster 10 $this_instance_name start

    # check the log
    sudo tail -f /var/log/postgresql/postgresql-10-$this_instance_name.log
fi

# 
# end of replication
# 

