#!/bin/bash

# Simple script to query the number of available jobs on icecc.
# Usage: icecc-jobs.sh <scheduler-host-address>

scheduler=$1

# Ask the scheduler for remote nodes info
info=$(nc $scheduler 8766 <<< "listcs")

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
