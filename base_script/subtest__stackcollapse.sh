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

REGEX_DATA_LINE=".*\s+(\d+)"

../common/check_all_lines_matched.pl "$REGEX_DATA_LINE" < $LOGS_DIR/script__${script}__report.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report"
(( TEST_RESULT += $? ))


# sample count check
N_SAMPLES=`perl -ne 'print "$1" if /\((\d+) samples\)/' $LOGS_DIR/script__${script}__record.log`
CNT=`perl -ne 'BEGIN{$n=0;} {$n+=$1 if (/\w+\s(\d+)/)} END{print "$n";}' $LOGS_DIR/script__${script}__report.log`

test $N_SAMPLES -eq $CNT
print_results 0 $? "script $script :: sample count check ($CNT = $N_SAMPLES)"
(( TEST_RESULT += $? ))
