#### !!! THIS IS TO BE SOURCED BY test_scripts.sh !!!

### test for wakeup-latency script

# wakeup-latency script counts min/max/avg wake-up latency in the system

script="wakeup-latency"


# record
$CMD_PERF script record $script -a -o $CURRENT_TEST_DIR/perf.data -- $CMD_LONGER_SLEEP 2> $LOGS_DIR/script__${script}__record.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/script__${script}__record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: record"
(( TEST_RESULT += $? ))


# report
$CMD_PERF script report $script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/script__${script}__report.log 2> $LOGS_DIR/script__${script}__report.err
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "wakeup_latency stats" "total_wakeups:\s*\d+" < $LOGS_DIR/script__${script}__report.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "avg_wakeup_latency.*:\s*(?:\d+|N\/A)" "min_wakeup_latency.*:\s*\d+" "max_wakeup_latency.*:\s*\d+" < $LOGS_DIR/script__${script}__report.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report"
(( TEST_RESULT += $? ))


# latency sanity check
LAT_MIN=`grep min_wakeup_latency $LOGS_DIR/script__${script}__report.log | perl -ne 'print "$1" if /(\d+)$/'`
LAT_MAX=`grep max_wakeup_latency $LOGS_DIR/script__${script}__report.log | perl -ne 'print "$1" if /(\d+)$/'`
LAT_AVG=`grep avg_wakeup_latency $LOGS_DIR/script__${script}__report.log | perl -ne 'print "$1" if /(\d+)$/'`

if [ -z $LAT_AVG ]; then
	print_testcase_skipped "script $script :: latency sanity check"
	return 0
fi

test $LAT_MAX -ge $LAT_MIN
print_results 0 $? "script $script :: latency sanity check min <= max ($LAT_MIN <= $LAT_MAX)"
(( TEST_RESULT += $? ))

test $LAT_MAX -ge $LAT_AVG
print_results 0 $? "script $script :: latency sanity check avg <= max ($LAT_AVG <= $LAT_MAX)"
(( TEST_RESULT += $? ))

test $LAT_AVG -ge $LAT_MIN
print_results 0 $? "script $script :: latency sanity check min <= avg ($LAT_MIN <= $LAT_AVG)"
(( TEST_RESULT += $? ))
