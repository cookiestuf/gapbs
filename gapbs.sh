#!/bin/bash
bmark_name=$1
mkdir -p ~/output
export OMP_NUM_THREADS=$2
echo "Starting rate $bmark_name run with $OMP_NUM_THREADS threads"
start_counters
./run/${bmark_name}.sh > ~/output/out 2>~/output/err
stop_counters
