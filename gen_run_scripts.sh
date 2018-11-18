#!/bin/bash
#default values
command_file=test.cmd
t_pwd="/gapbs"
jsonFlag=false
input_type=test
verifyFlag=false

#default vals for json
bootbinary="bbl-vmlinux"
output="/benchmark/out/"
root_fs="gapbs.img"


workload_file="gapbs.json"
workload=$(basename $workload_file .json)
function usage
{
    echo "usage gen_run_scripts.sh [--json] [-h] --input [test | graph500 | ref] [--verify]"
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
         --verify)
             verifyFlag=true
             ;;
    esac
    shift
done


mkdir -p run
if [ "$jsonFlag" = true ];
then
    echo "{" > $workload_file
    echo "  \"common_bootbinary\" : \"${bootbinary}\"," >> $workload_file
    echo "  \"benchmark_name\" : \"${workload}\"," >> $workload_file
    echo "  \"deliver_dir\" : \"${workload}\"," >> $workload_file
    echo "  \"common_args\" : []," >> $workload_file
    echo "  \"common_files\" : [\"gapbs.sh\"]," >> $workload_file
    echo "  \"common_outputs\" : [\"/output\"]," >> $workload_file
#    echo "  \"common_rootfs\" : \"${root_fs}\"," >> $workload_file
    echo "  \"workloads\" : [" >> $workload_file
fi

while IFS= read -r command; do
    bmark=`echo $command | sed 's/\.\/\([a-z]*\).*/\1/'`
    graph=`echo ${command} | grep -Eo 'benchmark/graphs/\w*\.\w*'`
    output_file="`echo $command | grep -Eo "benchmark\/out/.*out"`"
    workload=$(basename $output_file .out)
    binary="${bmark}"
    echo "workload: ${workload}"
    echo "output_file: ${output_file}"
    echo "graph: ${graph}"
    echo "binary: ${binary}"
    run_script=run/${workload}.sh
    echo '#!/bin/bash' > $run_script
    echo $command | sed "s/benchmark/\\${t_pwd}\/benchmark/g" | sed "s/^\./\\${t_pwd}/" | sed "s/-n/\$1 -n/g" |sed "s/ >.*//" >> $run_script

    chmod +x $run_script
    cat $run_script
    if [ "$jsonFlag" = true ]; then
        echo "    {" >> $workload_file
        echo "      \"name\": \"${workload}\"," >> $workload_file
        echo "      \"files\": [\"${binary}\", \"${run_script}\", \"${graph}\"]," >> $workload_file
        echo "      \"command\": \"cd /gapbs && ./gapbs.sh ${workload}\"," >> $workload_file
        echo "      \"outputs\": [\"${output_file}\"]" >> $workload_file
        echo "    }," >> $workload_file
    fi
done < $command_file
if [ "$jsonFlag" = true ]; then
    echo "$(head -n -1 $workload_file)" > $workload_file
    echo "    }" >> $workload_file
    echo "  ]" >> $workload_file
    echo "}" >> $workload_file
fi
