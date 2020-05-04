#!/bin/bash

#
#	test_intel_pt of perf_record test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests Intel Processor Trace functionality. The event intel_pt//
#	available on newer Intel CPUs is able to trace all function calls a program
#	issues during its execution. The example "load" has a function_F() that calls
#	function_a() and function_b(). The number of calls of each function should be
#	equal to number of returns (of course) and equal for both of te functions. It
#	is also true that it should be all equal to a sum of an arithmetic row from 1
#	to N-1 for any N (should be 55 for N=11). Using this, we can verify that the
#	intel_pt// event actually traces all the function calls and does not miss any.
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


# perf-list does not show intel_pt// event support
if ! should_support_intel_pt; then
	print_overall_skipped
	exit 0
fi

# parameter for examples/load (just a "random" number, can be user-adjusted)
N=11
# calculate expected number of function calls based on $NO (basically it is an arithmetic row sum)
EXPECTED=$(echo `seq $(( N - 1 ))` | perl -lpe "()=m{\\s(?{\$_+=\$'})}g")


### record PT data
rm -f $CURRENT_TEST_DIR/perf.data
$CMD_PERF record -e intel_pt//u -o $CURRENT_TEST_DIR/perf.data $CURRENT_TEST_DIR/examples/load $N > /dev/null 2> $LOGS_DIR/intelpt_record.err
PERF_EXIT_CODE=$?

# check the perf record output
../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2_TOLERANT" "perf.data" < $LOGS_DIR/intelpt_record.err
CHECK_EXIT_CODE=$?
../common/check_errors_whitelisted.pl "stderr-whitelist.txt" < $LOGS_DIR/intelpt_record.err
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "record PT data"
(( TEST_RESULT += $? ))


### script --itrace
$CMD_PERF script --itrace=be -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/intelpt_script.log
PERF_EXIT_CODE=$?

# check perf script output
REGEX_SCRIPT_LINE="^\s*load\s+$RE_NUMBER\s+\[$RE_NUMBER\]\s+$RE_NUMBER:\s+$RE_NUMBER\s+$RE_EVENT\s+$RE_NUMBER_HEX\s+.*$"
REGEX_CBR_HEADER="cbr:\s+cbr:\s+$RE_NUMBER\s+freq:\s+$RE_NUMBER\s+MHz"
../common/check_all_lines_matched.pl "$REGEX_SCRIPT_LINE" "$REGEX_CBR_HEADER" < $LOGS_DIR/intelpt_script.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "main" "printf" "function_a" "function_b" "function_F" < $LOGS_DIR/intelpt_script.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script --itrace"
(( TEST_RESULT += $? ))


### data sanity
FUNC_A_CALLS=`perl -ne 'print if /function_F.* => .* function_a/' < $LOGS_DIR/intelpt_script.log | wc -l`
FUNC_A_RETNS=`perl -ne 'print if /function_a.* => .* function_F/' < $LOGS_DIR/intelpt_script.log | wc -l`
FUNC_B_CALLS=`perl -ne 'print if /function_F.* => .* function_b/' < $LOGS_DIR/intelpt_script.log | wc -l`
FUNC_B_RETNS=`perl -ne 'print if /function_b.* => .* function_F/' < $LOGS_DIR/intelpt_script.log | wc -l`

test $FUNC_A_CALLS -eq $EXPECTED
print_results 0 $? "data sanity :: function_a call count ($FUNC_A_CALLS == $EXPECTED)"
(( TEST_RESULT += $? ))

test $FUNC_A_RETNS -eq $EXPECTED
print_results 0 $? "data sanity :: function_a return count ($FUNC_A_RETNS == $EXPECTED)"
(( TEST_RESULT += $? ))

test $FUNC_B_CALLS -eq $EXPECTED
print_results 0 $? "data sanity :: function_b call count ($FUNC_B_CALLS == $EXPECTED)"
(( TEST_RESULT += $? ))

test $FUNC_B_RETNS -eq $EXPECTED
print_results 0 $? "data sanity :: function_b return count ($FUNC_B_RETNS == $EXPECTED)"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
