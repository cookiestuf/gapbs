#!/bin/bash
#default values
command_file=test.cmd
t_pwd="/gapbs"
jsonFlag=false
input_type=test
verifyFlag=false

workload_file="gapbs.json"
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
if [ "$jsonFlag" = true ]; then
    echo "{" > $workload_file
fi

while IFS= read -r command; do
    bmark=`echo $command | sed 's/\.\/\([a-z]*\).*/\1/'`
    graph=`echo ${command} | grep -Eo 'benchmark/graphs/\w*\.\w*'`
    output_file="${t_pwd}/`echo $command | grep -Eo "benchmark\/out/.*out"`"
    binary="${bmark}"
    workload=$(basename $output_file .out)
    echo "workload: ${workload}"
    echo "output_file: ${output_file}"
    echo "graph: ${graph}"
    echo "binary: ${binary}"
    run_script=run/${workload}.sh
    echo '#!/bin/bash' > $run_script
    if [ "$verifyFlag" = true ]; then
        echo $command | sed "s/benchmark/\\${t_pwd}\/benchmark/g" | sed "s/^\./\\${t_pwd}/" | sed "s/-n/-vn/g" >> $run_script
    else
        echo $command | sed "s/benchmark/\\${t_pwd}\/benchmark/g" | sed "s/^\./\\${t_pwd}/" >> $run_script
    fi

    chmod +x $run_script
    cat $run_script
    if [ "$jsonFlag" = true ]; then
        echo "  {" >> $workload_file
        echo "    \"name\": \"${workload}\"," >> $workload_file
        echo "    \"files\": [\"${binary}\", \"${graph}\"]," >> $workload_file
        echo "    \"command\": \"cd /gapbs && ./gapbs.sh ${workload}\"," >> $workload_file
        echo "    \"outputs\": []" >> $workload_file
        echo "  }," >> $workload_file
    fi
done < $command_file
if [ "$jsonFlag" = true ]; then
    echo "$(head -n -1 $workload_file)" > $workload_file
    echo "  }" >> $workload_file
    echo "]" >> $workload_file
fi
