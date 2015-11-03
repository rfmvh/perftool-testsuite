#
#	test_line_semantics of perf_probe test
#	Author: Masami Hiramatsu <masami.hiramatsu.pt@hitachi.com>
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test checks whether the semantic errors of line option's
#		arguments are properly reported.
#

# include working environment
. ../common/settings.sh
. ../common/patterns.sh
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0`
TEST_RESULT=0


### acceptable --line descriptions

# testing acceptance of valid patterns for the '--line' option
VALID_PATTERNS="func func:10 func:0-10 func:2+10 func@source.c func@source.c:1 source.c:1 source.c:1+1 source.c:1-10"
for desc in $VALID_PATTERNS; do
	! ( $CMD_PERF probe --line $desc 2>&1 | grep -q "Semantic error" )
	CHECK_EXIT_CODE=$?

	print_results 0 $CHECK_EXIT_CODE "acceptable descriptions :: $desc"
	(( TEST_RESULT += $? ))
done


### unacceptable --line descriptions

# testing handling of invalid patterns for the '--line' option
INVALID_PATTERNS="func:foo func:1-foo func:1+foo func;lazy\*pattern"
for desc in $INVALID_PATTERNS; do
	$CMD_PERF probe --line $desc 2>&1 | grep -q "Semantic error"
	CHECK_EXIT_CODE=$?

	print_results 0 $CHECK_EXIT_CODE "unacceptable descriptions :: $desc"
	(( TEST_RESULT += $? ))
done


# print overall resutls
print_overall_results "$TEST_RESULT"
exit $?
