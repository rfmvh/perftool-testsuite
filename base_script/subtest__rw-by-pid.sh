#### !!! THIS IS TO BE SOURCED BY test_scripts.sh !!!

### test for rw-by-pid script

# rw-by-pid script displays r/w activity for all processes or
# for specified process


script="rw-by-pid"


# record
REAL_COUNT=10

$CMD_PERF script record $script -o $CURRENT_TEST_DIR/perf.data -- dd if=/dev/zero of=/dev/null bs=1024 count=$REAL_COUNT 2> $LOGS_DIR/script__${script}__record.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/script__${script}__record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: record"
(( TEST_RESULT += $? ))


# report
$CMD_PERF script report $script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/script__${script}__report.log 2> $LOGS_DIR/script__${script}__report.err
PERF_EXIT_CODE=$?

REGEX_HEADER_READ_PID="\s*pid\s+comm\s+# reads\s+bytes_requested\s+bytes_read"
REGEX_HEADER_FAIL_PID="\s*pid\s+comm\s+error #\s+# errors"
REGEX_HEADER_WRITE_PID="\s*pid\s+comm\s+# writes\s+bytes_written"
REGEX_PID_LINE="\s*$RE_NUMBER\s+[\w\-:\[\]]+\s+$RE_NUMBER\s+$RE_NUMBER"

../common/check_all_patterns_found.pl "$REGEX_HEADER_READ_PID" "$REGEX_HEADER_FAIL_PID" "$REGEX_HEADER_WRITE_PID" < $LOGS_DIR/script__${script}__report.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_PID_LINE" < $LOGS_DIR/script__${script}__report.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report"
(( TEST_RESULT += $? ))

# sample count check
