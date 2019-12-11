#!/bin/bash

# Simple script to query the number of available jobs on icecc.
# Usage: icecc-jobs.sh [PORT]

if (( ! $# )); then
   # No arguments. Using default port
   PORT=8766
else
   PORT=$1
fi


# We asume that's the port where the icecc-scheduler is running on port $PORT.
# We also assume that no other machine has that port open.
#
# Ask (nicely) to all the machines connected to all networks we are a part of, if they have port $PORT open.
for BROADCAST in `ip -o -f inet addr show | awk '/scope global/ {print $4}'`;do
    SCHEDULER=`nmap --open -Pn ${BROADCAST} -p${PORT} | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`
    # You've got to ask yourself one question. Do I fell lucky? Well, do ya, punk?
    RET=$?

    if (( RET == 0 ))
    then
        break
    fi
done

if test -z $SCHEDULER; then
   echo "Well...this is embarrassing. No IP for you"
   exit 1
fi

# Ask the scheduler for remote nodes info
info=$(nc $SCHEDULER 8766 <<< "listcs")

# Example node info:
# MatiLaptop (xx.xxx.x.xxx:xxxx) [x86_64] speed=420.00 jobs=0/8 load=218
# So we match the number after "jobs=0/"
matches=($(grep -Po "(?<=jobs=[0-9]\/)(.[0-9]*)" <<< "$info"))

# Sum matches
jobs=0
for j in "${matches[@]}"
do
   ((jobs+=j))
done

echo $jobs
