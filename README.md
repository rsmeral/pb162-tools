PB162 automated evaluation script
================================= 

## Quick usage

 * Configure `BASE_DIR` in both scripts
 * put the reference project at `$BASE_DIR/project-complete/pb162-2014`
 * put `is_export.zip`s into `$BASE_DIR/iterations/0X`
 * put `PB162_Projekt_-_iterace_0X.txt` (colon-separated ascii) into `$BASE_DIR/iterations/0X`
 * put `PB162_Ostry_test_0X.txt` (colon-separated ascii) into `$BASE_DIR/iterations/0X`
 * run `./evaluation.sh 0X`
 * then run `./merge.sh 0X`
 * import `PB162_Projekt_-_iterace_0X.txt` into IS

## What?

The script automatically executes the three evaluation phases 
 * run unit tests
 * run extras
 * show sources

After each phase, user enters the number of points (and optional notes), otherwise the default value is used.
The results are placed in text files named `Surname_Firstname_UCO` in a specified folder.

The script _does expect_ the JAR files to be named with the standard IS scheme: `UCO_Surname_Firstname.*\.jar`.

The script _does not expect_ you to judge its aesthetics (fyi, it works mostly with global state, yuck).

There's also a script call `merge.sh` which will transform the output to the txt format for import into notebooks. It can also subtract points from the Quick test (_Ostry test_).

## How?

First, set up a few vars documented in the script, mainly:
 * `BASE_DIR` - the expected file layout is relative to this dir
 * `REFERENCE_PROJECT_DIR` - the dir containing the complete reference solution (all iterations)
 * `JUNIT_LIB` - path to a JUnit JAR

The following layout is expected, unless configured otherwise. The dir `results` will be created by the script.

    $BASE_DIR/
        iterations/
            01/
                results/
                    Surname1_Firstname1_UCO1
                    Surname2_Firstname2_UCO2
                    ...
                UCO1_Surname1_Firstname1_somename.jar
                UCO2_Surname2_Firstname2_othername.jar
                ...
                is_export.zip
                is_export_2.zip
                ...
            02/
            ...

Once configured, execute `./evaluation.sh` in any directory. Pass iteration number in the form `01` as the argument. If you
won't, the script will ask.

## Merging

The script `merge.sh` transforms the results into the txt format for import into notebooks. It needs the same parameter as evaluation script - the iteration number (e.g. `01`). 
It expects text files in the results directory, and the notebook-exported project iteration text file and the quick test (_Ostry test_) file in the iteration dir.

    $BASE_DIR/
        iterations/
            01/ 
                results/
                    Surname1_Firstname1_UCO1
                    Surname2_Firstname2_UCO2
                    ...
                PB162_Projekt_-_iterace_01.txt
                PB162_Ostry_test_01.txt

---
_Disclaimer: these scripts are not foolproof and *might* cause your computer to spontaneously combust if improperly used. Do not put in a microwave oven. Do not tumble dry._
