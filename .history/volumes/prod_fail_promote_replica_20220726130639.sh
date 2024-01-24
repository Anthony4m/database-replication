#!/bin/bash
source /tmp/mnt/env.sh

sudo pg_ctlcluster 10 $this_instance_name stop
echo "Stop PG"