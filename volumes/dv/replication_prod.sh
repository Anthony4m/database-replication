#!/bin/bash

# before we begin:
# 1. set mode in env file
# 2. get IPs of production and replica
# 3. set IPs in env file

#/bin/bash

# Update package list and install necessary packages
apt update
apt install -y sudo sshpass rsync grsync openssh-server openssh-client
sudo service ssh start

# Source environment variables
source /tmp/production_dr_rplicaiton/env.sh

# create database instance
sudo pg_createcluster 10 $this_instance_name
sudo pg_ctlcluster 10 $this_instance_name start


echo $default_postgres_password
# set database password for postgres
echo "ALTER USER postgres PASSWORD '$default_postgres_password';" | sudo -u postgres psql -p $this_instance_port

# Create userpass file with default password
echo "$default_postgres_password" | sudo tee "$this_instance_etc_path/userpass" > /dev/null

# Configure PostgreSQL settings
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


# Running in elevated mode
echo "running in elevated mode"
sudo su <<EOF
source /tmp/production_dr_rplicaiton/env.sh

# Configure pg_hba.conf
sudo printf "local\treplication\trep_user\t\t\t\ttrust\t#for local replicas\n" >> "$this_instance_etc_path/pg_hba.conf"
sudo printf "host\treplication\trep_user\t$other_instance_ip/32\t\tmd5\t#for remote replicas\n" >> "$this_instance_etc_path/pg_hba.conf"

# Create replication user
sudo psql -c "CREATE USER rep_user WITH REPLICATION LOGIN ENCRYPTED PASSWORD 'rep_user_123';" --dbname postgresql://postgres:password@localhost:$this_instance_port/postgres?password=postgres123

#passwd postgres
echo "ALTER USER postgres WITH PASSWORD '$default_postgres_password';" | sudo -u postgres psql -p $this_instance_port

# Allow postgres port through firewall
sudo apt install -y ufw
sudo ufw allow from $other_instance_ip to any port $this_instance_port proto tcp

# Restart PostgreSQL cluster
sudo pg_ctlcluster 10 $this_instance_name restart

source /tmp/production_dr_rplicaiton/env.sh

# Create .pgpass file
echo "#host:port:database:user:password" >> /var/lib/postgresql/.pgpass
echo "$other_instance_ip:$other_instance_port:replication:rep_user:rep_user_123" >> /var/lib/postgresql/.pgpass
chmod 0600 /var/lib/postgresql/.pgpass

# Exit postgres user
exit
EOF

echo "end running in elevated mode"

# Create recovery.conf
echo "restore_command = 'cp $this_instance_var_path/pg_log_archive/%f %p'" >> $this_instance_var_path/recovery.conf
echo "recovery_target_timeline = 'latest'" >> $this_instance_var_path/recovery.conf
echo "standby_mode = 'on'" >> $this_instance_var_path/recovery.conf
echo "primary_conninfo = 'host=$other_instance_ip port=$other_instance_port user=rep_user passfile=''/var/lib/postgresql/.pgpass'''" >> $this_instance_var_path/recovery.conf
echo "archive_cleanup_command = 'pg_archivecleanup $this_instance_var_path/pg_log_archive %r'" >> $this_instance_var_path/recovery.conf

# Give postgres user permission over var/postgresql folder
chown -R postgres "$this_instance_var_path"

# Set as primary
mv "$this_instance_var_path/recovery.conf" "$this_instance_var_path/recovery.done"

# Restart PostgreSQL cluster
pg_ctlcluster 10 $this_instance_name restart

# Create a table and insert data into production (not needed if you already have data in production database)
echo "creating table student and inserting value"
sudo -u postgres psql -p $this_instance_port -c "CREATE TABLE student (id int); INSERT INTO student VALUES (1);"

echo "login postgres"

#/var/log/postgresql/postgresql-10-main.log
sudo tail -f /var/log/postgresql/postgresql-10-$this_instance_name.log
sudo -u postgres psql -p $this_instance_port
