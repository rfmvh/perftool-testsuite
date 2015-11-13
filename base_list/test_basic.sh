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
. ../common/settings.sh
. ../common/patterns.sh
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


### help message

# test that a help message is shown and looks reasonable
$CMD_PERF list --help > basic_helpmsg.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "PERF-LIST" "NAME" "SYNOPSIS" "DESCRIPTION" "EVENT MODIFIERS" "RAW HARDWARE" "PARAMETERIZED EVENTS" "OPTIONS" "SEE ALSO" "NOTES" < basic_helpmsg.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "perf\-list \- List all symbolic event types" < basic_helpmsg.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
(( TEST_RESULT += $? ))


### basic execution

# test that perf list is even working
$CMD_PERF list > basic_basic.log 2> basic_basic.err
PERF_EXIT_CODE=$?

REGEX_LINE_HEADER="List of pre-defined events"
REGEX_LINE_BASIC="\s*$RE_EVENT_ANY\s+(?:OR\s+$RE_EVENT_ANY\s+)?\[.*event.*\]"
REGEX_LINE_BREAKPOINT="\s*mem:<addr>.*\s+\[Hardware breakpoint\]"
REGEX_LINE_RAW="\[Raw hardware event descriptor\]"
REGEX_LINE_AUX="see \'man perf\-list\' on how to encode it"
../common/check_all_lines_matched.pl "$RE_LINE_EMPTY" "$REGEX_LINE_HEADER" "$REGEX_LINE_BASIC" "$REGEX_LINE_BREAKPOINT" "$REGEX_LINE_RAW" "$REGEX_LINE_AUX" < basic_basic.log
CHECK_EXIT_CODE=$?
test ! -s basic_basic.err
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
	$CMD_PERF list $i > basic_$j.log
	PERF_EXIT_CODE=$?

	../common/check_all_lines_matched.pl "$REGEX_LINE_HEADER" "$RE_LINE_EMPTY" "${outputs[$i]}" < basic_$j.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "list $i"
	(( TEST_RESULT += $? ))
done


# print overall resutls
print_overall_results "$TEST_RESULT"
exit $?
