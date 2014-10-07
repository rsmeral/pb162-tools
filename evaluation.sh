#
# PB162 automated evaluation script
# 
# - automatically executes the three evaluation phases 
#  - run unit tests
#  - run extras
#  - show sources
# 
# - after each phase, user enters the number of points (and optional notes), otherwise the default value is used
# - the results are placed in text files named "Surname_Firstname_UCO" in a specified folder
# - files matching is_export*.zip are automatically exploded
# - the script expects the JAR files to be named with the standard IS scheme: "UCO_Surname_Firstname.*\.jar"
# - the script does not expect you to judge its aesthetics (fyi, it works mostly with global state, yuck)

#
# USER OPTIONS
#
# base dir, other dirs are defined relative to it
export BASE_DIR="/configure/this/dir"

# a directory containing folders named 01, 02, ..., 09; each containing JAR files with student solutions
export ITERATIONS_DIR=$BASE_DIR/iterations

# path to the reference solution project
export REFERENCE_PROJECT_DIR=$BASE_DIR/project-complete/pb162-2014

# the program to use for showing sources
export EDITOR=kwrite

# after each part of a student's solution (tests, extras, source), it's possible to enter notes for the student's notebooks
export SHOW_NOTES=true

# only valid if SHOW_NOTES=true; shows notes only if the points for the phase are not the default value (= if there is a problem)
export NOTES_ONLY_FOR_BAD=true

# automatically assigns DEFAULT_TEST_POINTS if the tests pass, without asking
export AUTO_EVALUATE_PASSING_PHASE=true

# location of junit jar (might have a dependency on hamcrest-core)
export JUNIT_LIB="/usr/share/java/junit.jar"

# java override
export JAVA_HOME=/usr/lib/jvm/java-1.7.0
export PATH=$JAVA_HOME/bin:$PATH

#
# PB162 2014 DEFAULTS
#
export DEFAULT_TEST_POINTS=3
export DEFAULT_EXTRA_POINTS=2
export DEFAULT_SOURCE_PENALISATION=0
export PACKAGE="cz.muni.fi.pb162.project"

# A map of files to be modified by students (according to the assignment) in each iteration
function relevant_files() {
    case $1 in
        01) echo "Triangle Vertex2D Demo" ;;
        02) echo "Triangle Vertex2D Circle Demo" ;;
        03) echo "Triangle Circle Gauger Snowman" ;;
        04) echo "GeneralRegularPolygon RegularOctagon Circle Square OlympicRings" ;;
        05) echo "SimplePolygon ArrayPolygon Triangle" ;;
        06) echo "DbException DbUnreachableException CannotStoreException MyStorage RegularPolygon GeneralRegularPolygon" ;;
        07) echo "Vertex2D CollectionPolygon Colored" ;;
        08) echo "LabeledPolygon Vertex2D VertexInverseComparator" ;;
        09) echo "LabeledPolygon" ;;
    esac
}

#
# INITIALISATION
#
export WORK_DIR=$BASE_DIR/work
export PACKAGE_DIR=$(echo $PACKAGE | sed "s%\.%/%g")
export ITERATION=${1:-$(echo "Iteration:" 1>&2; read ITERATION; echo -n $ITERATION)}
export ITERATION_DIR=$ITERATIONS_DIR/$ITERATION
export RESULTS_DIR=$ITERATION_DIR/results
export LESSON=lesson$ITERATION
export CLASSPATH_BASE=$JUNIT_LIB

# looks for files named is_export*.zip in $ITERATION_DIR, unzips them and possibly overwrites old jar/done files, if the unzipped is newer
function explode_is_export_zips {
    IS_EXPORT_DIR=$ITERATION_DIR/is-export-tmp
    rm -rf $IS_EXPORT_DIR
    mkdir $IS_EXPORT_DIR

    for is_export_zip in $(find $ITERATION_DIR -name "is_export*.zip") ; do
        local new_files=0
        unzip -q $is_export_zip -d $IS_EXPORT_DIR "*.jar"
        for unzipped_jar in $(find $IS_EXPORT_DIR -name "*.jar") ; do
            existing_file=$(find $ITERATION_DIR -maxdepth 1 -name "$(basename ${unzipped_jar})*")
            
            # if the iteration contains a file (jar or done) that is also in the zip, use the one from zip only if it's newer
            if [[  "x$existing_file" = "x" || ( -f $ITERATION_DIR/$existing_file && $unzipped_jar -nt $ITERATION_DIR/$existing_file ) ]] ; then
                [[ "x$existing_file" != "x" && -f $ITERATION_DIR/$existing_file ]] && rm $existing_file
                mv $unzipped_jar $ITERATION_DIR/
                ((new_files++))
            fi
        done
        rm $is_export_zip
        [[ $new_files != "0" ]] && echo "Extracted $new_files new files from $(basename $is_export_zip)"
    done
    
    rm -rf $IS_EXPORT_DIR
}

# set up dirs and vars, show info
function initiate_jar_file() {
    unset notes final_notes extra_points test_points sources_penalisation
    
    echo "========================"

    SRC=$WORK_DIR/src
    TARGET=$WORK_DIR/target

    rm -rf $WORK_DIR
    mkdir $WORK_DIR
    mkdir $SRC
    mkdir $TARGET
    
    # remember relevant part of file name
    uco_name=$(basename $jarfile | sed "s%\([0-9]*\)-\([A-Za-z_]*\).*%\2_\1%")
    echo $uco_name
    echo
}

# unpacking, moving, replacing, copying authoritative files, compilation
function prepare_jar_file() {

     # unpack the sources from the jar
    unzip -q $jarfile -d $SRC *.java
    
    # remove test and draw files from student's archive and replace with authoritative ones
    rm -rf $SRC/$PACKAGE_DIR/test
    rm -rf $SRC/$PACKAGE_DIR/demo/Draw*.java

    # copy authoritative test files and fix package and imports
    mkdir $SRC/$PACKAGE_DIR/test
    cat $REFERENCE_PROJECT_DIR/test/$LESSON/test/ProjectTest.java | sed "s%package *$LESSON%package $PACKAGE%" | sed "s%import *$LESSON%import $PACKAGE%" > $SRC/$PACKAGE_DIR/test/ProjectTest.java
    cp -r $REFERENCE_PROJECT_DIR/test/cz $SRC/
    for javafile in $(find $REFERENCE_PROJECT_DIR -path *$LESSON/demo* -name Draw*.java) ; do
        cat $javafile | sed "s%package *$LESSON%package $PACKAGE%" | sed "s%import *$LESSON%import $PACKAGE%" > $SRC/$PACKAGE_DIR/demo/$(basename $javafile)
    done
    
    # compile the sources
    echo
    echo COMPILING
    find $SRC -name *.java | xargs javac -d $TARGET -classpath $CLASSPATH_BASE:$SRC
}

# takes input, points for given category, and stores in given variable
function points_notes() {
    msg=$1
    points_var=$2
    default_points=$3
    auto_default=${4:-"false"}
    
    echo "$msg (Leave empty for default (${default_points}))":
    if $auto_default ; then
        eval $points_var=$default_points
        echo "${default_points} (auto)"
    else
            
        read $points_var
        eval assigned_points=\$$points_var

        [[ "x$assigned_points" = "x" ]] && eval $points_var=$default_points
        eval assigned_points=\$$points_var    

        if $SHOW_NOTES ; then
            if ! $NOTES_ONLY_FOR_BAD || [[ $assigned_points != $default_points ]] ; then
                echo "Notes:"
                read notes
                [[ "x$notes" != "x" ]] && final_notes="$final_notes \n$notes"
            fi
        fi
    fi
    
}

# run the tests
function run_tests() {
    echo 
    echo RUNNING ProjectTest
    if java -cp $TARGET:$CLASSPATH_BASE org.junit.runner.JUnitCore "$PACKAGE.test.ProjectTest" && $AUTO_EVALUATE_PASSING_PHASE ; then
        auto_eval_test="true"
    else 
        auto_eval_test="false"
    fi
    points_notes "Points for test" test_points $DEFAULT_TEST_POINTS $auto_eval_test
}

# run the extras
function run_extras() {
    echo
    echo RUNNING EXTRAS
    [[ -f $TARGET/$PACKAGE_DIR/demo/Demo.class ]] && java -cp $TARGET "$PACKAGE.demo.Demo"
    [[ -f $TARGET/$PACKAGE_DIR/demo/Draw.class ]] && java -cp $TARGET "$PACKAGE.demo.Draw"
    [[ -f $TARGET/$PACKAGE_DIR/demo/DrawExtra$ITERATION.class ]] && java -cp $TARGET "$PACKAGE.demo.DrawExtra$ITERATION"
    
    points_notes "Points for extras" extra_points $DEFAULT_EXTRA_POINTS
}

# open source files in editor one by one
function show_sources() {
    echo
    echo SHOWING SOURCES
    for pattern in $(relevant_files $ITERATION) ; do
        $EDITOR $(find $SRC -name "${pattern}*")
    done
    
    points_notes "Penalisation for sources (negative)" sources_penalisation $DEFAULT_SOURCE_PENALISATION
}


# the full cycle for one student jar file
function process_jar_file() {

    initiate_jar_file
    
    prepare_jar_file

    run_tests

    run_extras

    show_sources

}

# sum points, concatenate notes, output, ask if done
function summarize_output() {
    total=$(echo "$test_points + $extra_points + $sources_penalisation" | bc)
    echo 
    echo "Total points: $total"
    echo "*${total}" > $RESULTS_DIR/$uco_name

    if $SHOW_NOTES ; then
        echo -e $final_notes
        echo -e $final_notes >> $RESULTS_DIR/$uco_name
    fi

    # trim empty lines
    sed -i '/^\s*$/d' $RESULTS_DIR/$uco_name

    echo 
    echo "MARK AS DONE? (Enter or 'n')"
    read mark_done
    if [[ $mark_done != "n" ]] ; then
        mv $jarfile $jarfile.done
    fi
}

# start the process for jar files found in $ITERATION_DIR
function start_evaluation() {

    [[ ! -d $RESULTS_DIR ]] && mkdir $RESULTS_DIR

    for jarfile in $(find $ITERATION_DIR -name *.jar) ; do
        
        process_jar_file
        
        summarize_output

        echo
        echo "CONTINUE TO NEXT FILE? (Enter or Ctrl-C)"
        read
    done
}

function main() {
    
    explode_is_export_zips

    start_evaluation   
    
}

main
