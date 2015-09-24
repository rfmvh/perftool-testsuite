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
. ../common/settings.sh
. ../common/patterns.sh
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0`
TEST_RESULT=0

#### basic execution

# test that perf stat is even working
$CMD_PERF stat $CMD_SIMPLE 2> 01.log
PERF_EXIT_CODE=$?

REGEX_HEADER="\s*Performance counter stats for 'true':"
REGEX_LINES="\s*"$RE_NUMBER"\s+"$RE_EVENT"\s+#\s+"$RE_NUMBER"%?.*"
../common/check_all_patterns_found.pl "$REGEX_HEADER" "$REGEX_LINES" < 01.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "basic execution"
(( TEST_RESULT += $? ))


#### some options

# test some basic options that they change the behaviour
$CMD_PERF stat -i -a -c -r 3 -o /dev/stdout -- $CMD_BASIC_SLEEP > 02.log
PERF_EXIT_CODE=$?

REGEX_HEADER="^\s*Performance counter stats for '(sleep [\d\.]+|system wide)' \(3 runs\):"
REGEX_LINES="\s*"$RE_NUMBER"\s+"$RE_EVENT"\s+#\s+"$RE_NUMBER"%?.*\s*"$RE_NUMBER"%?.*"
REGEX_FOOTER="^\s*"$RE_NUMBER" seconds time elapsed.*"
../common/check_all_patterns_found.pl "$REGEX_HEADER" "$REGEX_LINES" "$REGEX_FOOTER" < 02.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "some options"
(( TEST_RESULT += $? ))


#### CSV output

# with -x'<SEPARATOR>' perf stat should produce a CSV output
$CMD_PERF stat -x';' -o /dev/stdout -a -- sleep 0.1 > 03.log
PERF_EXIT_CODE=$?

REGEX_LINES="^"$RE_NUMBER";+"$RE_EVENT
REGEX_UNSUPPORTED_LINES="^<not supported>;+"$RE_EVENT
../common/check_all_lines_matched.pl "$REGEX_LINES" "$REGEX_UNSUPPORTED_LINES" "$RE_LINE_EMPTY" "$RE_LINE_COMMENT" < 03.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "CSV output"
(( TEST_RESULT += $? ))


# print overall resutls
print_overall_results "$TEST_RESULT"
exit $?
