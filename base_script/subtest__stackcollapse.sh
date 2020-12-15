#### !!! THIS IS TO BE SOURCED BY test_scripts.sh !!!

### test for stackcollapse

# stackcollapse produces callgraphs in short form for scripting use

script="stackcollapse"


# record
$CMD_PERF script record $script -a -o $CURRENT_TEST_DIR/perf.data -- $CMD_BASIC_SLEEP 2> $LOGS_DIR/script__${script}__record.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/script__${script}__record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE 0 "script $script :: record"
(( TEST_RESULT += $? ))


# report

# stackcollapse has no option for input file
cd $CURRENT_TEST_DIR
CHECK_EXIT_CODE=$?

$CMD_PERF script report $script > $LOGS_DIR/script__${script}__report.log 2> $LOGS_DIR/script__${script}__report.err
PERF_EXIT_CODE=$?

cd $OLDPWD
(( CHECK_EXIT_CODE += $? ))

$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data | grep -oP "^[^\[]*\[" | sed 's/\s*[0-9]*\s\[$//g' | sort | uniq -c | sed 's/^\s*\([0-9]*\)\s*\(.*\)$/\2 \1/g' | sed 's/ /_/g' | sed 's/_\([^_]*$\)/ \1/g' | LC_COLLATE=C sort > $LOGS_DIR/script__${script}__collapse.log
(( CHECK_EXIT_CODE += $? ))

diff $LOGS_DIR/script__${script}__collapse.log $LOGS_DIR/script__${script}__report.log &> $LOGS_DIR/script__${script}__report.diff
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report"
(( TEST_RESULT += $? ))


# sample count check
N_SAMPLES=`perl -ne 'print "$1" if /\((\d+) samples\)/' $LOGS_DIR/script__${script}__record.log`
CNT=`perl -ne 'BEGIN{$n=0;} {$n+=$1 if (/[\w-~#:]+\s(\d+)/)} END{print "$n";}' $LOGS_DIR/script__${script}__report.log`

test $N_SAMPLES -eq $CNT
print_results 0 $? "script $script :: sample count check ($CNT = $N_SAMPLES)"
(( TEST_RESULT += $? ))
