#!/bin/bash

#
#	test_overhead of perf_trace test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tries to trace a heavier load.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

# skip if not running in at least standard runmode
consider_skipping $RUNMODE_STANDARD


#### systemwide

# system-wide tracing limited by sleep time should finish
$CMD_PERF trace -o $LOGS_DIR/overhead_systemwide.log -a -- $CMD_LONGER_SLEEP &
PERF_PID=$!
$CMD_LONGER_SLEEP
$CMD_LONGER_SLEEP
! kill -SIGINT $PERF_PID &> $LOGS_DIR/overhead_systemwide_kill.log
wait $PERF_PID
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$RE_LINE_TRACE_FULL" < $LOGS_DIR/overhead_systemwide.log
CHECK_EXIT_CODE=$?

../common/check_all_patterns_found.pl "No such process" < $LOGS_DIR/overhead_systemwide_kill.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "systemwide"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
