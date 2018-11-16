#!/bin/bash
#TODO: add function usage informations. add verify tag
verify=0
function usage
{
    echo "usage: gapbs.sh <workload-name> [-H | -h | --help] [--verify]"
    echo "    workload-name: the kernel and graph input"
    echo "    verify: if set, verifies the output of the benchmark. Default is off"
}

if [ $# -eq 0 -o "$1" == "--help" -o "$1" == "-h"]; then
    usage
    exit 3
fi

bmark_name=$1
shift
if [ "$1" == "--verify" ]; then
    verify=1
fi

mkdir -p ~/output
export OMP_NUM_THREADS=$2
echo "Starting rate $bmark_name run with $OMP_NUM_THREADS threads"
start_counters
./run/${bmark_name}.sh > ~/output/out 2>~/output/err
stop_counters
