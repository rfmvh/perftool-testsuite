#!/bin/bash

#
#	test_basic of perf_stat test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf stat command.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


### help message

if [ "$PARAM_GENERAL_HELP_TEXT_CHECK" = "y" ]; then
	# test that a help message is shown and looks reasonable
	$CMD_PERF stat --help > $LOGS_DIR/basic_helpmsg.log 2> $LOGS_DIR/basic_helpmsg.err
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "PERF-STAT" "NAME" "SYNOPSIS" "DESCRIPTION" "OPTIONS" "STAT\s+RECORD" "STAT\s+REPORT" < $LOGS_DIR/basic_helpmsg.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "CSV\s+FORMAT" "EXAMPLES" "SEE\s+ALSO" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "performance\scounter\sstatistics" "command" "record" "report" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "event" "no-inherit" "pid" "tid" "all-cpus" "scale" "detailed" "repeat" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "big-num" "no-aggr" "null" "verbose" "SEP" "field-separator" "cgroup" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "append" "pre" "post" "interval-print" "metric-only" "per-socket" "per-core" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "per-thread" "delay" "msecs" "transaction" "topdown" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_no_patterns_found.pl "No manual entry for" < $LOGS_DIR/basic_helpmsg.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "help message"
fi


#### basic execution

# test that perf stat is even working
$CMD_PERF stat $CMD_SIMPLE 2> $LOGS_DIR/basic_basic.log
PERF_EXIT_CODE=$?

REGEX_HEADER="\s*Performance counter stats for 'true':"
REGEX_LINES="\s*"$RE_NUMBER"\s+"$RE_EVENT"\s+#\s+"$RE_NUMBER"%?.*"
../common/check_all_patterns_found.pl "$REGEX_HEADER" "$REGEX_LINES" < $LOGS_DIR/basic_basic.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "basic execution"
(( TEST_RESULT += $? ))


#### some options

# test some basic options that they change the behaviour
$CMD_PERF stat -i -a -r 3 -o /dev/stdout -- $CMD_BASIC_SLEEP > $LOGS_DIR/basic_someopts.log
PERF_EXIT_CODE=$?

REGEX_HEADER="^\s*Performance counter stats for '(sleep [\d\.]+|system wide)' \(3 runs\):"
REGEX_LINES="\s*"$RE_NUMBER"\s+"$RE_EVENT"\s+#\s+"$RE_NUMBER"%?.*\s*"$RE_NUMBER"%?.*"
REGEX_FOOTER="^\s*$RE_NUMBER\s+(?:\+\-\s+$RE_NUMBER\s+)?seconds time elapsed.*"
../common/check_all_patterns_found.pl "$REGEX_HEADER" "$REGEX_LINES" "$REGEX_FOOTER" < $LOGS_DIR/basic_someopts.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "some options"
(( TEST_RESULT += $? ))


#### CSV output

# with -x'<SEPARATOR>' perf stat should produce a CSV output
$CMD_PERF stat -x';' -o /dev/stdout -a -- sleep 0.1 > $LOGS_DIR/basic_csv.log
PERF_EXIT_CODE=$?

REGEX_LINES="^"$RE_NUMBER";+"$RE_EVENT
REGEX_UNSUPPORTED_LINES="^<not supported>;+"$RE_EVENT
REGEX_METRIC_LINE="stalled\scycles\sper\sinsn"
../common/check_all_lines_matched.pl "$REGEX_LINES" "$REGEX_METRIC_LINE" "$REGEX_UNSUPPORTED_LINES" "$RE_LINE_EMPTY" "$RE_LINE_COMMENT" < $LOGS_DIR/basic_csv.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "CSV output"
(( TEST_RESULT += $? ))


### BUG: perf stat -a --per-node -x, --metric-only true command crashes

# the bug was caused by missing aggr_header_csv for AGGR_NODE and should be fixed
# this testcase tests, whether the segfault has been fixed

{ $CMD_PERF stat -a --per-node -x, --metric-only $CMD_SIMPLE; } > $LOGS_DIR/basic_per_node_x_crash.log 2> $LOGS_DIR/basic_per_node_x_crash.err

../common/check_no_patterns_found.pl "$RE_SEGFAULT" < $LOGS_DIR/basic_per_node_x_crash.err
PERF_EXIT_STATUS=$?

print_results $PERF_EXIT_STATUS 0 "--per-node -x crash"
(( TEST_RESULT += $? ))



# print overall results
print_overall_results "$TEST_RESULT"
exit $?
