#!/bin/bash

#
#	test_basic of perf_list test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf list command.
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
	$CMD_PERF list --help > $LOGS_DIR/basic_helpmsg.log 2> $LOGS_DIR/basic_helpmsg.err
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "PERF-LIST" "NAME" "SYNOPSIS" "DESCRIPTION" "EVENT MODIFIERS" "RAW HARDWARE" "PARAMETERIZED EVENTS" "OPTIONS" "SEE ALSO" "NOTES" < $LOGS_DIR/basic_helpmsg.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "perf\-list \- List all symbolic event types" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "hw" "sw" "cache" "tracepoint" "metricgroup" "event_glob" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_no_patterns_found.pl "No manual entry for" < $LOGS_DIR/basic_helpmsg.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "help message"
fi


### basic execution

# test that perf list is even working
$CMD_PERF list > $LOGS_DIR/basic_basic.log 2> $LOGS_DIR/basic_basic.err
PERF_EXIT_CODE=$?

REGEX_LINE_HEADER="List of pre-defined events"
REGEX_LINE_BASIC="\s*$RE_EVENT_ANY\s+(?:OR\s+$RE_EVENT_ANY\s+)?\[.*event.*\]"
REGEX_LINE_BREAKPOINT="\s*mem:<addr>.*\s+\[Hardware breakpoint\]"
REGEX_LINE_RAW="\[Raw hardware event descriptor\]"
REGEX_LINE_AUX="see \'man perf\-list\' on how to encode it"
REGEX_LINE_PMU_GRP="^\w[\w\s\-]*\w:"
REGEX_LINE_PMU_EVENT="^\s\s$RE_EVENT_ANY"
REGEX_LINE_PMU_DESCR="^(?:\s{7}\[[^\]]+)|(?:\s{8}.+)"
../common/check_all_lines_matched.pl "$RE_LINE_EMPTY" "$REGEX_LINE_HEADER" "$REGEX_LINE_BASIC" "$REGEX_LINE_BREAKPOINT" "$REGEX_LINE_RAW" "$REGEX_LINE_AUX" \
		"$REGEX_LINE_PMU_GRP" "$REGEX_LINE_PMU_EVENT" "$REGEX_LINE_PMU_DESCR" < $LOGS_DIR/basic_basic.log
CHECK_EXIT_CODE=$?
test ! -s $LOGS_DIR/basic_basic.err
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "basic execution"
(( TEST_RESULT += $? ))


### listing event groups

# perf list can filter the list by keywords or group globals
declare -A outputs
outputs["hw"]="Hardware event"
outputs["sw"]="Software event"
outputs["cache"]="Hardware cache event"
outputs["tracepoint"]="Tracepoint event"
outputs["pmu"]="Kernel PMU event"
outputs["xfs:\*"]="^\s*xfs:"
outputs["kmem:\*"]="^\s*kmem:"
outputs["syscalls:\*"]="^\s*syscalls:sys"

for i in ${!outputs[@]}; do
	j=`echo $i | tr -d '\\\*:'`
	$CMD_PERF list $i > $LOGS_DIR/basic_$j.log
	PERF_EXIT_CODE=$?

	../common/check_all_lines_matched.pl "$REGEX_LINE_HEADER" "$RE_LINE_EMPTY" "${outputs[$i]}" "$REGEX_LINE_PMU_GRP" "$REGEX_LINE_PMU_EVENT" "$REGEX_LINE_PMU_DESCR" < $LOGS_DIR/basic_$j.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "list $i"
	(( TEST_RESULT += $? ))
done


### non-sense argument

# 'perf list somethingnonsense' caused segfault in 4.4-rc
$CMD_PERF list somethingnonsense &> $LOGS_DIR/basic_nonsense.log
PERF_EXIT_CODE=$?

../common/check_no_patterns_found.pl "SIGSEGV" "egmentation fault" < $LOGS_DIR/basic_nonsense.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "non-sense argument"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
