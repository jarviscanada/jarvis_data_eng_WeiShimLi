#! /bin/bash

#Setup arguments
psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5
#validate arguments
if [ "$#" -ne 5 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

#parse hardware specification
hostname=$(hostname -f)
lscpu_out=`lscpu`

cpu_number=$(echo "$lscpu_out"  | egrep "^CPU\(s\):" | awk '{print $2}' | xargs)
cpu_architecture=$(echo "$lscpu_out"  | egrep "^Architecture\:" | awk '{print $2}' | xargs)
cpu_model=$(echo "$lscpu_out" | awk -F': *' '/^Model name:/ {print $2}')
cpu_mhz=$(echo "$cpu_model"  | awk -F '@ *' 'NF>1 {print $2*1000}' )
l2_cache=$(echo "$lscpu_out"  | egrep "^L2\scache:" | awk '{print $3}' | xargs)     # in kB
total_mem=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo) # in kB
timestamp=$(date -u '+%Y-%m-%d %H:%M:%S') # Current time in UTC time zone



#DO NOT put extra empty lines, it's ugly

insert_stmt="INSERT INTO host_info (hostname, cpu_number, cpu_architecture, cpu_model, cpu_mhz, l2_cache, \"timestamp\", total_mem) VALUES('$hostname', $cpu_number, '$cpu_architecture', '$cpu_model', $cpu_mhz, $l2_cache, '$timestamp', $total_mem);"

export PGPASSWORD=$psql_password

psql -h localhost -p 5432 -U postgres -d host_agent -c "TRUNCATE TABLE host_info RESTART IDENTITY CASCADE;" && psql -h localhost -p 5432 -U postgres -d host_agent -c "$insert_stmt"

#put appropriate exit number
exit 0

