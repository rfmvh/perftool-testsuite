#
#	test_basic of perf_probe test
#	Author: Michael Petlan <mpetlan@redhat.com>
#	Author: Masami Hiramatsu <masami.hiramatsu.pt@hitachi.com>
#
#	Description:
#
#		This test tests basic functionality of perf probe command.
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


### help message

if [ "$PARAM_GENERAL_HELP_TEXT_CHECK" = "y" ]; then
	# test that a help message is shown and looks reasonable
	$CMD_PERF probe --help > basic_helpmsg.log
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "PERF-PROBE" "NAME" "SYNOPSIS" "DESCRIPTION" "OPTIONS" "PROBE\s+SYNTAX" "PROBE\s+ARGUMENT" "LINE\s+SYNTAX" < basic_helpmsg.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "LAZY\s+MATCHING" "FILTER\s+PATTERN" "EXAMPLES" "SEE\s+ALSO" < basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "vmlinux" "module=" "source=" "verbose" "quiet" "add=" "del=" "list.*EVENT" "line=" "vars=" "externs" < basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "no-inlines" "funcs.*FILTER" "filter=FILTER" "force" "dry-run" "max-probes" "exec=" "demangle-kernel" < basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "help message"
fi


### usage message

# without any args perf-probe should print usage
$CMD_PERF probe 2> basic_usage.log

../common/check_all_patterns_found.pl "usage" "perf probe" "verbose" "quiet" "add" "del" "force" "line" "vars" "externs" "range" < basic_usage.log
CHECK_EXIT_CODE=$?

print_results 0 $CHECK_EXIT_CODE "usage message"
(( TEST_RESULT += $? ))


### quiet switch

# '--quiet' should mute all output
$CMD_PERF probe --quiet --add vfs_read > basic_quiet01.log 2> basic_quiet01.err
PERF_EXIT_CODE=$?
$CMD_PERF probe --quiet --list > basic_quiet02.log 2> basic_quiet02.err
(( PERF_EXIT_CODE += $? ))
$CMD_PERF probe --quiet --del vfs_read > basic_quiet03.log 2> basic_quiet03.err
(( PERF_EXIT_CODE += $? ))

test `cat basic_quiet*log basic_quiet*err | wc -l` -eq 0
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "quiet switch"
(( TEST_RESULT += $? ))


# print overall resutls
print_overall_results "$TEST_RESULT"
exit $?
