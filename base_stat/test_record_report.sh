#!/bin/bash

#
#	test_record_report of perf_stat test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests record/report functionality of perf stat command.
#	For some time, perf stat support record/report into/from perf.data
#	file, which contains no samples, but allow to re-read the stats later.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


### perf stat record

# perf stat record should produce perf.data file apart from regular stat printing
$CMD_PERF stat record -o $CURRENT_TEST_DIR/perf.data $CMD_SIMPLE 2> $LOGS_DIR/record_report_record.log
PERF_EXIT_CODE=$?

REGEX_HEADER="\s*Performance counter stats for .+true':"
REGEX_LINES="\s*"$RE_NUMBER"\s+"$RE_EVENT"\s+#\s+"$RE_NUMBER"%?.*"
../common/check_all_patterns_found.pl "$REGEX_HEADER" "$REGEX_LINES" < $LOGS_DIR/record_report_record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "record"
(( TEST_RESULT += $? ))


### perf stat report

# perf stat report should reproduce the same stat data as perf stat normally prints
$CMD_PERF stat report -i $CURRENT_TEST_DIR/perf.data 2> $LOGS_DIR/record_report_report.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$REGEX_HEADER" "$REGEX_LINES" < $LOGS_DIR/record_report_report.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "report"
(( TEST_RESULT += $? ))


### stats comparison

# the reported output should match the original perf stat output
# (however, there is one difference in the header line)
diff -u <(grep -v "Performance counter stats" $LOGS_DIR/record_report_record.log) <(grep -v "Performance counter stats" $LOGS_DIR/record_report_report.log) > $LOGS_DIR/record_report_diff.log
CHECK_EXIT_CODE=$?
test $TESTLOG_VERBOSITY -ge 2 && cat $LOGS_DIR/record_report_diff.log

print_results 0 $CHECK_EXIT_CODE "diff"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
