#!/bin/bash

#
#	test_basic of perf_record test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf record command.
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
	$CMD_PERF record --help > $LOGS_DIR/basic_helpmsg.log
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "PERF-RECORD" "NAME" "SYNOPSIS" "DESCRIPTION" "OPTIONS" "SEE ALSO" < $LOGS_DIR/basic_helpmsg.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "all-cpus" "verbose" "quiet" "stat" "data" "timestamp" "pid" "tid" "no-samples" "raw-samples" "no-buildid-cache" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "cgroup" "branch-any" "branch-filter" "per-thread" "transaction" "delay" "weight" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "help message"
fi


### basic record

# test that perf record is even working
rm -f $CURRENT_TEST_DIR/perf.data
$CMD_PERF record -o $CURRENT_TEST_DIR/perf.data ls $CURRENT_TEST_DIR > /dev/null 2> $LOGS_DIR/basic_basic.err
PERF_EXIT_CODE=$?

# check the perf record output
../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/basic_basic.err
CHECK_EXIT_CODE=$?
../common/check_errors_whitelisted.pl "stderr-whitelist.txt" < $LOGS_DIR/basic_basic.err
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "basic record"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
