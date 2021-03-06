#!/bin/bash
#default values
command_file=test.cmd
t_pwd="/gapbs"
jsonFlag=false
input_type=test
verifyFlag=false
binariesFlag=false

#default vals for json
bootbinary="bbl-vmlinux"
output="/benchmark/out/"
root_fs="gapbs.img"

#more default values
KRON_ARGS=-g10
SUITE="bc bfs cc cc_sv pr sssp tc gapbs.sh"
workload_file="gapbs.json"
workload=$(basename $workload_file .json)
function usage
{
    echo "usage gen_run_scripts.sh [--binaries] [--json] [-h] --input [test | graph500 | ref] [--verify]"
}

while test $# -gt 0
do
    case "$1" in
         --json)
             jsonFlag=true
             ;;
         --input)
             shift;
             input_type=$1
             command_file=$1.cmd
             ;;
         -h)
             usage
             exit
             ;;
         --binaries)
             binariesFlag=true
             ;;
          --verify)
             verifyFlag=true
             ;;
    esac
    shift
done
if [ "$input_type" = graph500 ];
then
    KRON_ARGS=-g20
fi

if [ "$binariesFlag" = true ] && [ ! -d "overlay/$input_type" ];
then
    make converter
    CXX=${RISCV}/bin/riscv64-unknown-linux-gnu-g++ CXX_FLAGS+=--static make
    mkdir -p overlay/$input_type/benchmark/graphs
    cp $SUITE overlay/$input_type/
    ./converter $KRON_ARGS -wb overlay/$input_type/benchmark/graphs/kron.wsg
    ./converter $KRON_ARGS -b overlay/$input_type/benchmark/graphs/kron.sg
    ./converter $KRON_ARGS -b overlay/$input_type/benchmark/graphs/kronU.sg
fi

mkdir -p overlay/$input_type/run
if [ "$jsonFlag" = true ];
then
    echo "{" > $workload_file
    echo "  \"common_bootbinary\" : \"${bootbinary}\"," >> $workload_file
    echo "  \"benchmark_name\" : \"gapbs-kron\"," >> $workload_file
    echo "  \"deliver_dir\" : \"${workload}\"," >> $workload_file
    echo "  \"common_args\" : []," >> $workload_file
    echo "  \"common_files\" : [\"gapbs.sh\"]," >> $workload_file
    echo "  \"common_outputs\" : [\"/output\"]," >> $workload_file
    echo "  \"workloads\" : [" >> $workload_file
fi

while IFS= read -r command; do
    bmark=`echo $command | sed 's/\.\/\([a-z]*\).*/\1/'`
    graph=`echo ${command} | grep -Eo 'benchmark/graphs/\w*\.\w*'`
    output_file="`echo $command | grep -Eo "benchmark\/out/.*out"`"
    workload=$(basename $output_file .out)
    binary="${bmark}"
    run_script=overlay/$input_type/run/${workload}.sh
    run_script_no_overlay=run/${workload}.sh
    echo '#!/bin/bash' > $run_script
    echo $command | sed "s/benchmark/\\${t_pwd}\/benchmark/g" | sed "s/^\./\\${t_pwd}/" | sed "s/-n/\$1 -n/g" |sed "s/ >.*//" >> $run_script

    chmod +x $run_script
    if [ "$jsonFlag" = true ]; then
        echo "    {" >> $workload_file
        echo "      \"name\": \"${workload}\"," >> $workload_file
        echo "      \"files\": [\"${binary}\", \"${run_script_no_overlay}\", \"${graph}\"]," >> $workload_file
        echo "      \"command\": \"cd /gapbs && ./gapbs.sh ${workload}\"," >> $workload_file
        echo "      \"outputs\": []" >> $workload_file
        echo "    }," >> $workload_file
    fi
done < $command_file
if [ "$jsonFlag" = true ]; then
    echo "$(head -n -1 $workload_file)" > $workload_file
    echo "    }" >> $workload_file
    echo "  ]" >> $workload_file
    echo "}" >> $workload_file
fi
