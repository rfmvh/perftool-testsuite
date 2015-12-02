#
#	test_buildid-list of perf buildid test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test checks whether the buildids captured by perf record
#	and listed by perf buildid-list from the perf.data file matches
#	reality. Some other checks of the tool are done too.
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

test -s perf.data || ./setup.sh


### help message

if [ "$PARAM_GENERAL_HELP_TEXT_CHECK" = "y" ]; then
	# test that a help message is shown and looks reasonable
	$CMD_PERF buildid-list --help > list_helpmsg.log
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "PERF-BUILDID-LIST" "NAME" "SYNOPSIS" "DESCRIPTION" "OPTIONS" "SEE ALSO" < list_helpmsg.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "perf\-buildid\-list \- List the buildids in a perf\.data file" < list_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "help message"
fi

### buildids check

# test that perf list is even working
$CMD_PERF buildid-list > list_basic.log 2> list_basic.err
PERF_EXIT_CODE=$?

# output sanity checks
REGEX_LINE_BASIC="\w{40}\s+$RE_PATH"
../common/check_all_lines_matched.pl "$REGEX_LINE_BASIC" < list_basic.log
CHECK_EXIT_CODE=$?
test ! -s basic_basic.err
(( CHECK_EXIT_CODE += $? ))

# output semantics check
../common/check_buildids_vs_files.pl < list_basic.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "buildids check"
(( TEST_RESULT += $? ))


### kernel buildid

# the --kernel option should print the buildid of the running kernel
$CMD_PERF buildid-list --kernel > list_kernel.log
PERF_EXIT_CODE=$?

# check whether the buildid is printed
../common/check_all_lines_matched.pl "\w{40}" < list_kernel.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "kernel buildid"
(( TEST_RESULT += $? ))


# print overall resutls
print_overall_results "$TEST_RESULT"
exit $?
