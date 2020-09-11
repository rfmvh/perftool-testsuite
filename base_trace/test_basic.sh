#!/bin/bash

#
#	test_basic of perf_trace test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf trace command.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

#### help message

if [ "$PARAM_GENERAL_HELP_TEXT_CHECK" = "y" ]; then
	# test that a help message is shown and looks reasonable
	$CMD_PERF trace --help > $LOGS_DIR/basic_helpmsg.log 2> $LOGS_DIR/basic_helpmsg.err
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "PERF-TRACE" "NAME" "SYNOPSIS" "DESCRIPTION" "OPTIONS" "PAGEFAULTS" "EXAMPLES" "SEE ALSO" "NOTES" < $LOGS_DIR/basic_helpmsg.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "all-cpus" "expr" "output" "pid" "tid" "uid" "verbose" "cpu" "duration" "summary" "sched" "event" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "perf trace record" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_no_patterns_found.pl "No manual entry for" < $LOGS_DIR/basic_helpmsg.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "help message"
fi

#### basic execution

# test that perf trace is working
$CMD_PERF trace $CMD_QUICK_SLEEP 2> $LOGS_DIR/basic_basic.log
PERF_EXIT_CODE=$?

REGEX_TIMESTAMP="^\s*(\d+(?:\.\d+))\s"

../common/check_all_lines_matched.pl "$RE_LINE_TRACE_FULL" < $LOGS_DIR/basic_basic.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$RE_LINE_TRACE_FULL" < $LOGS_DIR/basic_basic.log
(( CHECK_EXIT_CODE += $? ))
../common/check_timestamps.pl "$REGEX_TIMESTAMP" < $LOGS_DIR/basic_basic.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "basic execution"
(( TEST_RESULT += $? ))


### duration threshold

# '--duration X' should show only syscalls that take longer than X ms
$CMD_PERF trace --duration 80 $CMD_BASIC_SLEEP 2> $LOGS_DIR/basic_duration.log
PERF_EXIT_CODE=$?

REGEX_SLEEP_SYSCALL_ONLY="^\s*$RE_NUMBER\s*\(\s*$RE_NUMBER\s*ms\s*\):\s*$RE_PROCESS_PID\s+\w*sleep\(.*\)\s+=\s+\-?$RE_NUMBER|$RE_NUMBER_HEX.*$"
../common/check_all_lines_matched.pl "$REGEX_SLEEP_SYSCALL_ONLY" < $LOGS_DIR/basic_duration.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "duration threshold"
(( TEST_RESULT += $? ))


### systemwide

# '-a' should trace system-wide from all CPUs
$CMD_PERF trace -o $LOGS_DIR/basic_systemwide.log -a &
PERF_PID=$!
$CMD_LONGER_SLEEP
kill -SIGINT $PERF_PID
wait $PERF_PID
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$RE_LINE_TRACE_FULL" < $LOGS_DIR/basic_systemwide.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "systemwide"
(( TEST_RESULT += $? ))


### full timestamp

# '-T' should print the full timestamp instead of the relative one
$CMD_PERF trace -T -- $CMD_QUICK_SLEEP 2> $LOGS_DIR/basic_full_timestamp.log
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$RE_LINE_TRACE_FULL" "\d{5,}\." < $LOGS_DIR/basic_full_timestamp.log
CHECK_EXIT_CODE=$?
../common/check_timestamps.pl "$REGEX_TIMESTAMP" < $LOGS_DIR/basic_full_timestamp.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "full timestamp"
(( TEST_RESULT += $? ))


### summary

# '-s' should print out a summary table
$CMD_PERF trace -s -- $CMD_QUICK_SLEEP 2> $LOGS_DIR/basic_summary.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_EMPTY" "$RE_LINE_TRACE_SUMMARY_HEADER" "$RE_LINE_TRACE_SUMMARY_CONTENT" < $LOGS_DIR/basic_summary.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "summary"
(( TEST_RESULT += $? ))


### attach process

# perf-trace should be able to attach an existing process by '-p PID'
echo "some_test_string" | $CURRENT_TEST_DIR/examples/vest &
$CMD_PERF trace -p $! -o $LOGS_DIR/basic_attach.log
PERF_EXIT_CODE=$?

# sanity check
REGEX_UNPAIRED="^\s+\?\s*\(\s*\??\s*\):\s+\.\.\.\s+\[continued\]:\s+(?:nano)?sleep\(\)\)\s*=\s*0"
../common/check_all_lines_matched.pl "$REGEX_UNPAIRED" "$RE_LINE_TRACE_ONE_PROC" "$RE_LINE_TRACE_CONTINUED" "exit" < $LOGS_DIR/basic_attach.log
CHECK_EXIT_CODE=$?

# perf should know the syscall even if perf attached during it (*sleep)
../common/check_all_patterns_found.pl "$REGEX_UNPAIRED" < $LOGS_DIR/basic_attach.log
(( CHECK_EXIT_CODE += $? ))
# the following syscalls should have full entries in the log:
../common/check_all_patterns_found.pl "(?:nano)?sleep\([^\)]" "open(?:at)?\([^\)]" "close\([^\)]" "write\([^\)]" < $LOGS_DIR/basic_attach.log
(( CHECK_EXIT_CODE += $? ))
../common/check_timestamps.pl "$REGEX_TIMESTAMP" < $LOGS_DIR/basic_attach.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "attach process"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
