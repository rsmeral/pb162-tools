# base dir, other dirs are defined relative to it
export BASE_DIR="/configure/this/dir"

# a directory containing folders named 01, 02, ..., 09; each containing JAR files with student solutions
export ITERATIONS_DIR=$BASE_DIR/iterations
export ITERATION=${1:-$(echo "Iteration:" 1>&2; read ITERATION; echo -n $ITERATION)}
export ITERATION_DIR=$ITERATIONS_DIR/$ITERATION
export RESULTS_DIR=$ITERATION_DIR/results

export PROJECT_NOTEBOOK_TXT_NAME="PB162_Projekt_-_iterace_${ITERATION}.txt";
export TEST_NOTEBOOK_TXT_NAME="PB162_Ostry_test_${ITERATION}.txt"

# parse all result files
for result_file in $(ls ${RESULTS_DIR}) ; do
    uco=${result_file##*_}
    echo $uco
    
    #
    # PARSE INPUT
    #
    student_result=$(cat ${RESULTS_DIR}/$result_file | tr -d $'\r' | sed "s%\n% %g")
    project_points=$(echo $student_result | sed "s%\*\([0-9\.]*\).*%\1%")
    project_note=$(echo $student_result | sed "s%\*[0-9\.]*\s*\(.*\)%\1%")
    
    # if test notebook present, subtract test points
    if [[ -f $ITERATION_DIR/$TEST_NOTEBOOK_TXT_NAME ]] ; then
        quick_test_points=$(grep "${uco}" $ITERATION_DIR/$TEST_NOTEBOOK_TXT_NAME | tr -d $'\r' | sed "s%${uco}.*\*\(.*\)%\1%")
        project_points=$(echo "$project_points + $quick_test_points" | bc)
    fi
    
    echo $student_result
    echo $project_points
    echo $project_note

    #
    # WRITE OUT
    #
    sed -i "s%\(${uco}.*${uco}/.*/.*\):.*%\1:*$project_points $project_note%" $ITERATION_DIR/$PROJECT_NOTEBOOK_TXT_NAME
done

# still need to deal with those who did not turn in their solution - fill zeros
sed -i "s%^\([0-9]\{6\}.*[0-9]\{6\}/.*/.*\):$%\1:*0%g" $ITERATION_DIR/$PROJECT_NOTEBOOK_TXT_NAME