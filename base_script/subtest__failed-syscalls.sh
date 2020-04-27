#### !!! THIS IS TO BE SOURCED BY test_scripts.sh !!!

### test for failed-syscalls

# failed-syscalls displays system-wide failed system call totals,
# if a [comm] is specified, only syscalls called by [comm] are displayed

script="failed-syscalls"


# record
! $CMD_PERF script record $script -a -o $CURRENT_TEST_DIR/perf.data -- cat nonexisting 2> $LOGS_DIR/script__${script}__record.log
PERF_EXIT_CODE=$?

# note: this script does not produce any record output

print_results $PERF_EXIT_CODE 0 "script $script :: record all"
(( TEST_RESULT += $? ))


# report
$CMD_PERF script report $script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/script__${script}__report_all.log 2> /dev/null
PERF_EXIT_CODE=$?

REGEX_HEADER_MSG="failed syscalls by comm:"
REGEX_HEADER_LINE="comm\s+# errors"
REGEX_HEADER_UNDERLINE="[- ]{30,}"
REGEX_COMM_LINE="[\w\-:\[\]]+\s+(\d+)"

../common/check_all_patterns_found.pl "$REGEX_HEADER_MSG" "$REGEX_HEADER_LINE" "$REGEX_HEADER_UNDERLINE" "$REGEX_COMM_LINE" < $LOGS_DIR/script__${script}__report_all.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report all"
(( TEST_RESULT += $? ))


# error count check
N_ERRORS=`perl -ne 'BEGIN{$n=0;} {$n+=$1 if /'$REGEX_COMM_LINE'/} END{print "$n";}'  $LOGS_DIR/script__${script}__report_all.log`
CNT=`$CMD_PERF script 2> /dev/null | grep -P '= -\d*' | wc -l`

test $CNT -eq $N_ERRORS
print_results 0 $? "script $script :: all error count check ($CNT == $N_ERRORS)"
(( TEST_RESULT += $? ))


# record for single command
! $CMD_PERF script record $script -o $CURRENT_TEST_DIR/perf.data -- cat nonexisting 2> $LOGS_DIR/script__${script}__record.log
PERF_EXIT_CODE=$?

# note: this script does not produce any record output

print_results $PERF_EXIT_CODE 0 "script $script :: record single command"
(( TEST_RESULT += $? ))


# report for single command
$CMD_PERF script report $script cat -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/script__${script}__report_cat.log 2> /dev/null
PERF_EXIT_CODE=$?

REGEX_CAT_LINE="cat\s+(\d+)"

../common/check_all_patterns_found.pl "$REGEX_HEADER_MSG" "$REGEX_HEADER_LINE" "$REGEX_HEADER_UNDERLINE" "$REGEX_CAT_LINE" < $LOGS_DIR/script__${script}__report_cat.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report single command"
(( TEST_RESULT += $? ))


# error count check
N_ERRORS=`perl -ne 'print "$1" if /'$REGEX_CAT_LINE'/' $LOGS_DIR/script__${script}__report_cat.log`
CNT=`$CMD_PERF script 2> /dev/null | grep -P '= -\d*' | wc -l`

test $CNT -eq $N_ERRORS
print_results 0 $? "script $script :: single command error count check ($CNT == $N_ERRORS)"
(( TEST_RESULT += $? ))
