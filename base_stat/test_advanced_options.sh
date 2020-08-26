#!/bin/bash

#
#	test_advanced_options.sh of perf_stat test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests some more advanced options offered by perf-stat.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

# disable in BASIC mode
consider_skipping $RUNMODE_STANDARD


### delay

FULL_DELAY_S=0.4
FULL_DELAY_MS=`echo "$FULL_DELAY_S * 1000" | bc`
HALF_DELAY_MS=`echo "scale=0 ; $FULL_DELAY_MS / 2" | bc`
EVENTS_TO_TEST=`$CMD_PERF list hw sw | grep -e cpu-cycles -e instructions -e cpu-clock | perl -ne 'print "$1 " if /^\s\s([\w\-]+)\s/'`
REGEX_METRIC_LINE="^;+$RE_NUMBER;[\w\s]+"
if [ -n "$EVENTS_TO_TEST" ]; then
	test -d $LOGS_DIR/delay || mkdir $LOGS_DIR/delay

	for event in $EVENTS_TO_TEST; do
		# full measurement
		$CMD_PERF stat -e $event -o $LOGS_DIR/delay/$event--full.log -x';' -- sleep $FULL_DELAY_S
		PERF_EXIT_CODE=$?
		REGEX_LINES="$RE_NUMBER;[^;]*;$event;$RE_NUMBER;100\.00"
		../common/check_all_patterns_found.pl "$REGEX_LINES" < $LOGS_DIR/delay/$event--full.log
		CHECK_EXIT_CODE=$?
		../common/check_all_lines_matched.pl "$REGEX_LINES" "$RE_LINE_EMPTY" "$RE_LINE_COMMENT" "$REGEX_METRIC_LINE" < $LOGS_DIR/delay/$event--full.log
		(( CHECK_EXIT_CODE += $? ))

		print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "delay event $event full"
		(( TEST_RESULT += $? ))

		# half measurement
		$CMD_PERF stat -e $event -o $LOGS_DIR/delay/$event--half.log -x';' --delay $HALF_DELAY_MS -- sleep $FULL_DELAY_S
		PERF_EXIT_CODE=$?
		../common/check_all_patterns_found.pl "$REGEX_LINES" < $LOGS_DIR/delay/$event--half.log
		CHECK_EXIT_CODE=$?
		../common/check_all_lines_matched.pl "$REGEX_LINES" "$RE_LINE_EMPTY" "$RE_LINE_COMMENT" "$REGEX_METRIC_LINE" < $LOGS_DIR/delay/$event--half.log
		(( CHECK_EXIT_CODE += $? ))

		print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "delay event $event half"
		(( TEST_RESULT += $? ))

		# result sanity
		FULL_RESULT=`grep -P '^\d' $LOGS_DIR/delay/$event--full.log | awk -F';' '{print $1}'`
		HALF_RESULT=`grep -P '^\d' $LOGS_DIR/delay/$event--half.log | awk -F';' '{print $1}'`
		ZERO=`echo "($FULL_RESULT * 0.05 > $HALF_RESULT) + ($FULL_RESULT * 0.49 < $HALF_RESULT)" | bc`
		# ZERO should be equal to 0 if PASS

		print_results 0 $ZERO "delay event $event values OK"
		(( TEST_RESULT += $? ))
	done
else
	print_testcase_skipped "delay"
fi


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
