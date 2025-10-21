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

TEST_RESULT=0


### perf stat record

# perf stat record should produce perf.data file apart from regular stat printing
$CMD_PERF stat record -o $CURRENT_TEST_DIR/perf.data $CMD_SIMPLE 2> $LOGS_DIR/record_report_record.log
PERF_EXIT_CODE=$?

REGEX_HEADER="\s*Performance counter stats for .+true':"
REGEX_LINES="\s*$RE_NUMBER\s+$RE_EVENT\s+#\s+$RE_NUMBER%?.*"
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

# the reported output should match the original perf stat output for core events
# Note: TopdownL1 metrics are formatted differently between record and report modes,
# so we compare only the basic events that should have identical values
> $LOGS_DIR/record_report_diff.log
CHECK_EXIT_CODE=0

for event in "task-clock" "context-switches" "cpu-migrations" "page-faults" "instructions" "cycles" "branches" "branch-misses"; do
	grep "$event" $LOGS_DIR/record_report_record.log | grep -v "stalled-cycles" > $LOGS_DIR/record_report_record_$event.tmp 2>/dev/null
	grep "$event" $LOGS_DIR/record_report_report.log | grep -v "stalled-cycles" > $LOGS_DIR/record_report_report_$event.tmp 2>/dev/null

	# Only compare if the event exists in the record output
	if [ -s $LOGS_DIR/record_report_record_$event.tmp ]; then
		diff -u $LOGS_DIR/record_report_record_$event.tmp $LOGS_DIR/record_report_report_$event.tmp >> $LOGS_DIR/record_report_diff.log
		if [ $? -ne 0 ]; then
			CHECK_EXIT_CODE=1
		fi
	fi

	rm -f $LOGS_DIR/record_report_record_$event.tmp $LOGS_DIR/record_report_report_$event.tmp
done

test $TESTLOG_VERBOSITY -ge 2 && cat $LOGS_DIR/record_report_diff.log

print_results 0 $CHECK_EXIT_CODE "diff"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
