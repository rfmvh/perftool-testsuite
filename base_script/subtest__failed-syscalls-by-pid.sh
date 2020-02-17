#### !!! THIS IS TO BE SOURCED BY test_scripts.sh !!!

### test for failed-syscalls-by-pid

# what they do

script="failed-syscalls-by-pid"


# record
$CMD_PERF script record $script -o $CURRENT_TEST_DIR/perf.data -- $CMD_BASIC_SLEEP 2> $LOGS_DIR/script__${script}__record.log
PERF_EXIT_CODE=$?

# note: this script does not produce any record output

print_results $PERF_EXIT_CODE 0 "script $script :: record"
(( TEST_RESULT += $? ))


#report
$CMD_PERF script report $script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/script__${script}__report.log 2> $LOGS_DIR/script__${script}__report.err
PERF_EXIT_CODE=$?

REGEX_HEADER_MSG_1="Press control\+C to stop and show the summary"
REGEX_HEADER_MSG_2="syscall errors:"
REGEX_HEADER_LINE="comm \[pid\]\s+count"
REGEX_PID_LINE="[\w\-:\[\]]+\s+[$RE_NUMBER]"
REGEX_SYSCALL_LINE="\s+syscall: [\w\-:\[\]]+"
REGEX_ERR_LINE="\s+err = \w+\s+$RE_NUMBER"

../common/check_all_patterns_found.pl "$REGEX_HEADER_MSG_1" "$REGEX_HEADER_MSG_2" "$REGEX_HEADER_LINE" < $LOGS_DIR/script__${script}__report.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_PID_LINE" "$REGEX_SYSCALL_LINE" "$REGEX_ERR_LINE" < $LOGS_DIR/script__${script}__report.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report"
(( TEST_RESULT += $? ))

