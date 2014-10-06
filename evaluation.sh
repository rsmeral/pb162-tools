#
# PB162 automated evaluation script
# 
# - automatically executes the three evaluation phases 
#  - tests
#  - extras
#  - sources
# 
# - after each phase, user enters the number of points, otherwise the default is used
# - the results are placed in text files named "Surname_Firstname_UCO" in a specified folder
#
# - the program expects the JAR files to be named with the standard IS scheme: "UCO_Surname_Firstname.*\.jar"
#
#
# USER OPTIONS
#
# base dir, other dirs are defined relative to it
export BASE_DIR="/home/rsmeral/Dropbox/pb162"

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
export CLASSPATH_BASE=$BASE_DIR/resources/junit/junit-4.10.jar

[[ ! -d $RESULTS_DIR ]] && mkdir $RESULTS_DIR

for jarfile in $(find $ITERATION_DIR -name *.jar) ; do
    
    unset notes final_notes extra_points test_points negative_points
    
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

    # run the tests - max 3 points
    echo 
    echo RUNNING ProjectTest
    java -cp $TARGET:$CLASSPATH_BASE org.junit.runner.JUnitCore "$PACKAGE.test.ProjectTest"
    echo "Points for test (max $DEFAULT_TEST_POINTS):"
    read test_points
    [[ "x$test_points" = "x" ]] && test_points=$DEFAULT_TEST_POINTS
    
    if $SHOW_NOTES ; then
        if ! $NOTES_ONLY_FOR_BAD || [[ $test_points != $DEFAULT_TEST_POINTS ]] ; then
            echo "Notes:"
            read notes
            [[ "x$notes" != "x" ]] && final_notes="$final_notes \n$notes"
        fi
    fi

    # run the extras - max 2 points
    echo
    echo RUNNING EXTRAS
    [[ -f $TARGET/$PACKAGE_DIR/demo/Demo.class ]] && java -cp $TARGET "$PACKAGE.demo.Demo"
    [[ -f $TARGET/$PACKAGE_DIR/demo/Draw.class ]] && java -cp $TARGET "$PACKAGE.demo.Draw"
    [[ -f $TARGET/$PACKAGE_DIR/demo/DrawExtra$ITERATION.class ]] && java -cp $TARGET "$PACKAGE.demo.DrawExtra$ITERATION"
    echo "Points for extras (max $DEFAULT_EXTRA_POINTS):"
    read extra_points
    [[ "x$extra_points" = "x" ]] && extra_points=$DEFAULT_EXTRA_POINTS

    if $SHOW_NOTES ; then
        if  ! $NOTES_ONLY_FOR_BAD || [[ $extra_points != $DEFAULT_EXTRA_POINTS ]] ; then
            echo "Notes:"
            read notes
            [[ "x$notes" != "x" ]] && final_notes="$final_notes \n$notes"
        fi
    fi

    # open source files in editor one by one
    echo
    echo SHOWING SOURCES
    for pattern in $(relevant_files $ITERATION) ; do
        $EDITOR $(find $SRC -name "${pattern}*")
    done
    echo "Penalisation for sources (negative):"
    read negative_points
    [[ "x$negative_points" = "x" ]] && negative_points=$DEFAULT_SOURCE_PENALISATION

    if $SHOW_NOTES ; then
        if ! $NOTES_ONLY_FOR_BAD || [[ $negative_points != $DEFAULT_SOURCE_PENALISATION ]] ; then
            echo "Notes:"
            read notes
            [[ "x$notes" != "x" ]] && final_notes="$final_notes \n$notes"
        fi
    fi
    
    total=$(echo "$test_points + $extra_points + $negative_points" | bc)
    echo 
    echo "Total points: $total"
    echo "*${total}" > $RESULTS_DIR/$uco_name

    if $SHOW_NOTES ; then
        echo -e $final_notes
        echo -e $final_notes >> $RESULTS_DIR/$uco_name
    fi

    echo 
    echo "MARK AS DONE? (Enter or 'n')"
    read mark_done
    if [[ $mark_done != "n" ]] ; then
        mv $jarfile $jarfile.done
    fi

    echo
    echo "CONTINUE TO NEXT FILE? (Enter or Ctrl-C)"
    read
done