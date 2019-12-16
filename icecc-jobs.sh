#!/bin/bash

# Script that queries the number of available jobs on icecc.
# Usage: icecc-jobs.sh [--help] [-p | --port <port>] [-s | --scheduler <scheduler>]

# Set default arguments
PORT=8766           # icecc-scheduler port
PRINT_HELP=false    # flag indicating wether to print the help or not
SCHEDULER=""        # icecc-scheduler host

# Parse arguments
while [ "$1" != "" ]; do
    case "$1" in
        -h | --help )        PRINT_HELP=true;   ;;   
        -p | --port )        PORT="$2";         shift;;
        -s | --scheduler )   SCHEDULER="$2";    shift;;
    esac
    shift
done

function print_help {
    echo -e "\n"\
        "Script that queries the number of available jobs on icecc.\n\n"\
        "Usage: icecc-jobs.sh [--help] [-p | --port <port>] [-s | --scheduler <scheduler>]\n\n"\
        "-h | --help: show this help.\n"\
        "-p | --port <port>: icecc-scheduler port, defaults to 8766.\n"\
        "-s | --scheduler <scheduler>: scheduler host address, allows to skip network scan (faster result).\n\n"\
        "If the scheduler address is not specified, the script will scan over all available networks.\n"\
        "The first computer found with icecc-scheduler port open will be considered to be the scheduler.\n"
}

function discover_schedulers {
    # We asume that's the port where the icecc-scheduler is running on port $PORT.
    # We also assume that no other machine has that port open.
    #
    # Ask (nicely) to all the machines connected to all networks we are a part of, if they have port $PORT open.
    for BROADCAST in `ip -o -f inet addr show | awk '/scope global/ {print $4}'`;do
        SCHEDULER_LIST=(`nmap --open -Pn ${BROADCAST} -p${PORT} | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`)
        # You've got to ask yourself one question. Do I fell lucky? Well, do ya, punk?
        RET=$?

        if (( RET == 0 ))
        then
            break
        fi
    done

    if test -z $SCHEDULER_LIST; then
        echo "Well...this is embarrassing. No scheduler found for you"
        exit 1
    fi
}

if $PRINT_HELP; then
    print_help
    exit 0;
fi

if test -z $SCHEDULER; then
    discover_schedulers
    if [ "${#SCHEDULER_LIST[@]}" -gt 1 ]; then
        echo "Multiple schedulers found:"
        for S in "${SCHEDULER_LIST[@]}"
        do
            echo $S
        done
        echo "Please specify which to query using the -s <scheduler> option"
        exit 1
    fi
    SCHEDULER=${SCHEDULER_LIST[0]}
fi

# Ask the scheduler for remote nodes info
INFO=$(nc $SCHEDULER $PORT -w 5 <<< "listcs")

if [[ -z $INFO ]]; then
    echo "Ups! The scheduler is not responding."
    exit 1
fi

# Example node info:
# MatiLaptop (xx.xxx.x.xxx:xxxx) [x86_64] speed=420.00 jobs=0/8 load=218
# So we match the number after "jobs=0/"
MATCHES=($(grep -Po "(?<=jobs=[0-9]\/)(.[0-9]*)" <<< "$INFO"))

# Sum matches
JOBS=0
for j in "${MATCHES[@]}"
do
   ((JOBS+=j))
done

echo $JOBS
