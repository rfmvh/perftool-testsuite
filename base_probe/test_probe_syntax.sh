#!/bin/bash

#
#	test_probe_syntax of perf_probe test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests adding of probes specified by some more
#	advanced expressions (see man page section "PROBE SYNTAX":
#
# Probe points are defined by following syntax.
#
# 1) Define event based on function name
#	[EVENT=]FUNC[@SRC][:RLN|+OFFS|%return|;PTN] [ARG ...]
#
# 2) Define event based on source file with line number
#	[EVENT=]SRC:ALN [ARG ...]
#
# 3) Define event based on source file with lazy pattern
#	[EVENT=]SRC;PTN [ARG ...]
#
#
#		This testcase checks whether the above mentioned
#	expression formats are accepted correctly by perf-probe.
#

# include working environment
. ../common/init.sh

TEST_RESULT=0

TEST_PROBE="vfs_read"

if ! check_kprobes_available; then
	print_overall_skipped
	exit 0
fi

clear_all_probes


### custom named probe

# when "new_name=" prefix is given, the probe should be named according to it
$CMD_PERF probe myprobe=$TEST_PROBE 2> $LOGS_DIR/probe_syntax_custom_name_add.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "Added new events?:" "probe:myprobe" "on $TEST_PROBE" < $LOGS_DIR/probe_syntax_custom_name_add.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "custom named probe :: add"
(( TEST_RESULT += $? ))

# the custom name should appear in the probe list
$CMD_PERF probe -l > $LOGS_DIR/probe_syntax_custom_name_list.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "\s*probe:myprobe(?:_\d+)?\s+\(on $TEST_PROBE(?:[:\+]\d+)?@.+\)" < $LOGS_DIR/probe_syntax_custom_name_list.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "custom named probe :: list"
(( TEST_RESULT += $? ))

# the custom named probe should be usable
$CMD_PERF stat -e probe:myprobe\* -o $LOGS_DIR/probe_syntax_custom_name_use.log -- cat /proc/uptime > /dev/null
PERF_EXIT_CODE=$?

REGEX_STAT_HEADER="\s*Performance counter stats for \'cat /proc/uptime\':"
REGEX_STAT_VALUES="\s*\d+\s+probe:myprobe"
# the value should be greater than 1
REGEX_STAT_VALUES_NONZERO="\s*[1-9][0-9]*\s+probe:myprobe"
REGEX_STAT_TIME="\s*$RE_NUMBER\s+seconds (?:time elapsed|user|sys)"
../common/check_all_lines_matched.pl "$REGEX_STAT_HEADER" "$REGEX_STAT_VALUES" "$REGEX_STAT_TIME" "$RE_LINE_COMMENT" "$RE_LINE_EMPTY" < $LOGS_DIR/probe_syntax_custom_name_use.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_STAT_HEADER" "$REGEX_STAT_VALUES_NONZERO" "$REGEX_STAT_TIME" < $LOGS_DIR/probe_syntax_custom_name_use.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "custom named probe :: use"
(( TEST_RESULT += $? ))

clear_all_probes


### various syntax forms

# the probe point can be specified many ways
VALID_PATTERNS_BY_FUNCTION="vfs_read@fs/read_write.c vfs_read:11@fs/read_write.c vfs_read@fs/read_write.c:11 vfs_read%return"
for desc in $VALID_PATTERNS_BY_FUNCTION; do
	! ( $CMD_PERF probe -f --add $desc 2>&1 | grep -q "Invalid argument" )
	CHECK_EXIT_CODE=$?

	print_results 0 $CHECK_EXIT_CODE "various syntax forms :: $desc"
	(( TEST_RESULT += $? ))
done

clear_all_probes

# the 'test.c:29' format is better to test with userspace probes,
# since the absolute line numbers in the code does not change
! ( $CMD_PERF probe -x $CURRENT_TEST_DIR/examples/test --add test.c:29 2>&1 | grep -q "Invalid argument" )
CHECK_EXIT_CODE=$?

print_results 0 $CHECK_EXIT_CODE "various syntax forms :: test.c:29"
(( TEST_RESULT += $? ))

# function name with retval in the userspace code
! ( $CMD_PERF probe -x $CURRENT_TEST_DIR/examples/test --add 'some_normal_function%return $retval' 2>&1 | grep -q "Invalid argument" )
CHECK_EXIT_CODE=$?

print_results 0 $CHECK_EXIT_CODE "various syntax forms :: func%return \$retval"
(( TEST_RESULT += $? ))

clear_all_probes


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
