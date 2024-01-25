# Database Replication Setup

Follow these steps to set up database replication between your production and disaster recovery (DR) servers. Please exercise caution, especially when dealing with scripts that can impact your database cluster.

## Steps
1. Clone the project and go to the file and run docker compose up -d
2. Go into the terminal and run *_docker ps --format="ID\t{{.ID}}\nNAME\t{{.Names}}\nImage\t{{.Image}}\nPORTS\t{{.Ports}}\nCOMMAND\t{{.Command}}\nCREATED\t{{.CreatedAt}}\nSTATUS\t{{.Status}}\n"_*
3. Find the container id of both production and replica.
4.  Using the container id run docker exec -it “container id” /bin/bash
5. Run the script “ip a” to check for the ip of both servers.
6. Go into the env.sh and replace replica and production ip with their appropriate ips.
7. run chmod +x /tmp/mnt/replication_prod.sh for prod and chmod +x /tmp/mnt/replication_replica.sh for replica
8. Run the replica script twice, once to get it to run to accept connection and the second time to get it to expect connections.