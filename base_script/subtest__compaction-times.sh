#### !!! THIS IS TO BE SOURCED BY test_scripts.sh !!!

### test for compaction-times script

# compaction-times script should report time spent in mm compaction. It is possible
# to report times in nanoseconds (default) or microseconds (-u)

script="compaction-times"

if ! should_support_compaction_times_script; then
	print_testcase_skipped "script $script"
	return 0
fi


### record
$CMD_PERF script record $script -a -o $CURRENT_TEST_DIR/perf.data -- echo 1 > /proc/sys/vm/compact_memory 2> $LOGS_DIR/script__${script}__record.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/script__${script}__record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: record"
(( TEST_RESULT += $? ))


### report

# help message

$CMD_PERF script report $script -- -h > $LOGS_DIR/script__${script}__helpmsg.log 2> /dev/null
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "-h\s+display this help" "-p\s+display by process" "-t\s+display stall times only" "-m\s+display stats for migration" "-fs\s+display stats for free scanner"  "-ms\s+display stats for migration scanner" < $LOGS_DIR/script__${script}__helpmsg.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report help message"
(( TEST_RESULT += $? ))


# no options

REGEX_DATA_LINE="total:\s+[0-9]+ns\s+migration:\s+moved=[0-9]+\s+failed=[0-9]+\s+free_scanner:\s+scanned=[0-9]+\s+isolated=[0-9]+\s+migration_scanner:\s+scanned=[0-9]+\s+isolated=[0-9]+"

$CMD_PERF script report $script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/script__${script}__report.log 2> /dev/null
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$REGEX_DATA_LINE" < $LOGS_DIR/script__${script}__report.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report no options"
(( TEST_RESULT += $? ))


# process option

# we should find echo
REGEX_ECHO_LINE="[0-9]+\[echo\]:\s+[0-9]+ns\s+migration:\s+moved=[0-9]+\s+failed=[0-9]+\s+free_scanner:\s+scanned=[0-9]+\s+isolated=[0-9]+\s+migration_scanner:\s+scanned=[0-9]+\s+isolated=[0-9]+"

$CMD_PERF script report $script -i $CURRENT_TEST_DIR/perf.data -- -p > $LOGS_DIR/script__${script}__report.log 2> /dev/null
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$REGEX_DATA_LINE" "$REGEX_ECHO_LINE" < $LOGS_DIR/script__${script}__report.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report process option"
(( TEST_RESULT += $? ))


# time option

REGEX_TIME="total:\s[0-9]+ns"

$CMD_PERF script report $script -i $CURRENT_TEST_DIR/perf.data -- -t > $LOGS_DIR/script__${script}__report_t.log 2> /dev/null
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$REGEX_TIME" < $LOGS_DIR/script__${script}__report_t.log
CHECK_EXIT_CODE=$?

# should not differ from the original
cat $LOGS_DIR/script__${script}__report.log | grep -q "`cat $LOGS_DIR/script__${script}__report_t.log`"
(( CHECK_EXIT_CODE += $?))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report time option"
(( TEST_RESULT += $? ))


# microseconds option

REGEX_DATA_MICRO_LINE="total:\s+[0-9]+us\s+migration:\s+moved=[0-9]+\s+failed=[0-9]+\s+free_scanner:\s+scanned=[0-9]+\s+isolated=[0-9]+\s+migration_scanner:\s+scanned=[0-9]+\s+isolated=[0-9]+"

$CMD_PERF script report $script -i $CURRENT_TEST_DIR/perf.data -- -u > $LOGS_DIR/script__${script}__report_u.log 2> /dev/null
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$REGEX_DATA_MICRO_LINE" < $LOGS_DIR/script__${script}__report_u.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report microseconds option"
(( TEST_RESULT += $? ))


# migration option

REGEX_MIGRATION="migration:\s+moved=[0-9]+\s+failed=[0-9]+"

$CMD_PERF script report $script -i $CURRENT_TEST_DIR/perf.data -- -m > $LOGS_DIR/script__${script}__report_m.log 2> /dev/null
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$REGEX_TIME\s+$REGEX_MIGRATION" < $LOGS_DIR/script__${script}__report_m.log
CHECK_EXIT_CODE=$?

# should not differ from the original
cat $LOGS_DIR/script__${script}__report.log | grep -q "`cat $LOGS_DIR/script__${script}__report_m.log`"
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report migration option"
(( TEST_RESULT += $? ))


# free scanner option

REGEX_FREE_SCANNER="free_scanner:\s+scanned=[0-9]+\s+isolated=[0-9]+"

$CMD_PERF script report $script -i $CURRENT_TEST_DIR/perf.data -- -fs > $LOGS_DIR/script__${script}__report_fs.log 2> /dev/null
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$REGEX_TIME\s+$REGEX_FREE_SCANNER" < $LOGS_DIR/script__${script}__report_fs.log
CHECK_EXIT_CODE=$?

# should not differ from the original
cat $LOGS_DIR/script__${script}__report.log | grep -q "`cat $LOGS_DIR/script__${script}__report_fs.log | grep -o "$REGEX_TIME"`"
(( CHECK_EXIT_CODE += $? ))

cat $LOGS_DIR/script__${script}__report.log | grep -q "`cat $LOGS_DIR/script__${script}__report_fs.log | grep -o "$REGEX_FREE_SCANNER"`"
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report free scanner option"
(( TEST_RESULT += $? ))


# migration scanner option

REGEX_MIGRATION_SCANNER="migration_scanner:\s+scanned=[0-9]+\s+isolated=[0-9]+"

$CMD_PERF script report $script -i $CURRENT_TEST_DIR/perf.data -- -ms > $LOGS_DIR/script__${script}__report_ms.log 2> /dev/null
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$REGEX_TIME\s+$REGEX_MIGRATION_SCANNER" < $LOGS_DIR/script__${script}__report_ms.log
CHECK_EXIT_CODE=$?

# should not differ from the original
cat $LOGS_DIR/script__${script}__report.log | grep -q "`cat $LOGS_DIR/script__${script}__report_ms.log | grep -o "$REGEX_TIME"`"
(( CHECK_EXIT_CODE += $? ))

cat $LOGS_DIR/script__${script}__report.log | grep -q "`cat $LOGS_DIR/script__${script}__report_ms.log | grep -o "$REGEX_MIGRATION_SCANNER"`"
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report migration scanner option"
(( TEST_RESULT += $? ))
