#!/bin/bash
command_file=bmark.cmd
t_pwd="/gapbs"

workload_file="gapbs.json"
mkdir -p run
echo "[" > $workload_file

while IFS= read -r command; do
    bmark=`echo $command | sed 's/\.\/\([a-z]*\).*/\1/'`
    graph=`echo ${command} | grep -Eo 'benchmark/graphs/\w*\.\w*'`
    output_file="${t_pwd}/`echo $command | grep -Eo "benchmark\/out/.*out"`"
    binary="${bmark}"
    workload=$(basename $output_file .out)
    echo ${workload}
    echo ${output_file}
    echo ${graph}
    echo ${binary}
#    run_script=run/${workload}.sh
#    echo '#!/bin/bash' > $run_script
#    echo $command | sed "s/benchmark/\\${t_pwd}\/benchmark/g" | sed "s/^\./\\${t_pwd}/" >> $run_script
#    chmod +x $run_script

    echo "  {" >> $workload_file
    echo "    \"name\": \"${workload}\"," >> $workload_file
    echo "    \"files\": [\"${binary}\", \"${graph}\"]," >> $workload_file
    echo "    \"command\": \"cd /gapbs && ./gapbs.sh ${workload}\"," >> $workload_file
    echo "    \"outputs\": []" >> $workload_file
    echo "  }," >> $workload_file

done < $command_file
echo "$(head -n -1 $workload_file)" > $workload_file
echo "  }" >> $workload_file
echo "]" >> $workload_file

