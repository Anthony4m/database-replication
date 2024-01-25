#!/bin/bash

# Before we begin:
# 1. Set mode in env file
# 2. Get IPs of production and replica
# 3. Set IPs in env file

#/bin/bash

apt update
apt install -y sudo
apt install -y sshpass
sudo apt install -y rsync grsync
sudo apt install -y openssh-server
sudo apt-get install -y openssh-client
sudo service ssh start

source /tmp/production_dr_rplicaiton/env.sh




# Create database instance
# sudo pg_ctlcluster 10 $this_instance_name stop
# sudo service postgresql stop
# sudo pg_dropcluster 10 $this_instance_name

if pg_lsclusters | grep -q "\<10[ \t]\+$this_instance_name"; then
    sudo pg_ctlcluster 10 $this_instance_name stop
    sudo service postgresql stop
    sudo pg_dropcluster 10 $this_instance_name
    echo "PostgreSQL cluster stopped and removed."
else
    echo "PostgreSQL cluster does not exist."
fi



sudo pg_createcluster 10 $this_instance_name
sudo pg_ctlcluster 10 $this_instance_name start


# Set database password for postgres
echo "ALTER USER postgres PASSWORD '$default_postgres_password';" | sudo -u postgres psql -p $this_instance_port

# Create userpass file with default password
echo "$default_postgres_password" | sudo tee "$this_instance_etc_path/userpass" > /dev/null

# Configure postgres.conf
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

echo "Elevated mode activated"
sudo su <<EOF

echo "Sourcing"
source /tmp/production_dr_rplicaiton/env.sh

echo "Printing to pg_hba.conf"
sudo printf "local\treplication\trep_user\t\t\t\ttrust\t#for local replicas\n" >> "$this_instance_etc_path"/pg_hba.conf
sudo printf "host\treplication\trep_user\t$other_instance_ip/32\t\tmd5\t#for remote replicas\n" >> "$this_instance_etc_path"/pg_hba.conf

# --dbname postgresql://[username]:password@[ip]:[port]/[db_name]?password=[password]
echo "Creating replication user"
sudo psql -c "CREATE USER rep_user WITH REPLICATION LOGIN ENCRYPTED PASSWORD 'rep_user_123';" --dbname postgresql://postgres:$default_postgres_password@localhost:$this_instance_port/postgres?password=$default_postgres_password

echo "Setting postgres password"
#passwd postgres
echo "ALTER USER postgres WITH PASSWORD '$default_postgres_password';" | sudo -u postgres psql -p $this_instance_port


# Allow postgres port through firewall
echo "Installing firewall"
sudo apt install -y ufw

echo "Allowing postgres port through firewall"
sudo ufw allow from $other_instance_ip to any port $this_instance_port
EOF
echo "Restarting pg_cluster"
sudo pg_ctlcluster 10 $this_instance_name restart

# Clean directory of db instance
echo "Elevated privileges activated"
#sudo su
sudo su <<EOF
source /tmp/production_dr_rplicaiton/env.sh

echo "cd ing"

cd "$this_instance_var_path"
echo "find"

sudo find . -name . -o -prune -exec rm -rf -- {} +
#exit

echo "Login to postgres"
sudo su - postgres
#/bin/bash
#source /tmp/production_dr_rplicaiton/env.sh

echo "#host:port:database:user:password" >> /var/lib/postgresql/.pgpass
echo "$other_instance_ip:$other_instance_port:replication:rep_user:rep_user_123" >> /var/lib/postgresql/.pgpass
chmod 0600 /var/lib/postgresql/.pgpass
EOF
# Exit postgres user
#exit
#exit

# Backup production database
echo "Initiating pg_basebackup"
pg_basebackup --dbname postgresql://rep_user:$default_postgres_password@$other_instance_ip:$other_instance_port/postgres?password=rep_user_123 -D $this_instance_var_path

echo "Creating recovery file"
# Create a recovery.conf file
echo "restore_command = 'cp $this_instance_var_path/pg_log_archive/%f %p'" >> $this_instance_var_path/recovery.conf
echo "recovery_target_timeline = 'latest'" >> $this_instance_var_path/recovery.conf
echo "standby_mode = 'on'" >> $this_instance_var_path/recovery.conf
echo "primary_conninfo = 'host=$other_instance_ip port=$other_instance_port user=rep_user passfile=''/var/lib/postgresql/.pgpass'''" >> $this_instance_var_path/recovery.conf
echo "archive_cleanup_command = 'pg_archivecleanup $this_instance_var_path/pg_log_archive %r'" >> $this_instance_var_path/recovery.conf

# Give postgres user permission over var/postgresql folder
echo "Changing ownership of path"
chown -R postgres $this_instance_var_path

# Start replica database
echo "Starting cluster"
sudo pg_ctlcluster 10 $this_instance_name restart

# Check the log
echo "Checking logs"
sudo tail -f /var/log/postgresql/postgresql-10-$this_instance_name.log

#sudo -u postgres psql -p $this_instance_port


postgres=# \c sormas_db
You are now connected to database "sormas_db" as user "postgres".
sormas_db=# 

select extract('Year' from creationdate), count(*) from person group by extract('Year' from creationdate) 
 order by extract('Year' from creationdate);

ERROR:  relation "persons" does not exist
LINE 1: ... extract('Year' from creationdate), count(*) from persons gr...
                                                             ^
sormas_db=#