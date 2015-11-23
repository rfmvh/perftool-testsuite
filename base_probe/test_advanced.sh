#
#	test_advanced.sh of perf_probe test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This testcase tries some more advanced probes, capturing
#	values of variables, registers etc. The perf-script tool is
#	used for processing the results.
#
#

# include working environment
. ../common/settings.sh
. ../common/patterns.sh
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

clear_all_probes


### function argument probing:: add

$CMD_PERF probe -x examples/advanced --add 'isprime a' > advanced_funcargs_add.log 2>&1
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "probe_advanced:isprime" < advanced_funcargs_add.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "function argument probing :: add"
(( TEST_RESULT += $? ))


### function argument probing :: use

# perf record should catch samples including the argument's value
$CMD_PERF record -e 'probe_advanced:isprime' examples/advanced > /dev/null 2> advanced_funcargs_record.log
PERF_EXIT_CODE=$?

# perf record should catch exactly 9 samples
../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "9 samples" < advanced_funcargs_record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "function argument probing :: record"
(( TEST_RESULT += $? ))

# perf script should report the function calls with the correct arg values
$CMD_PERF script > advanced_funcargs_script.log
PERF_EXIT_CODE=$?

# perf report should report exact sample counts
REGEX_SCRIPT_LINE="\s*advanced\s+$RE_NUMBER\s+\[$RE_NUMBER\]\s+$RE_NUMBER:\s+probe_advanced:isprime:\s+\($RE_NUMBER\) a=$RE_NUMBER"
../common/check_all_lines_matched.pl "$REGEX_SCRIPT_LINE" < advanced_funcargs_script.log
CHECK_EXIT_CODE=$?

../common/check_exact_pattern_order.pl "a=2" "a=3" "a=4" "a=5" "a=6" "a=7" "a=13" "a=17" "a=19" < advanced_funcargs_script.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "function argument probing :: script"
(( TEST_RESULT += $? ))


clear_all_probes


# print overall resutls
print_overall_results "$TEST_RESULT"
exit $?
