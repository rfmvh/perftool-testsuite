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


### hwcache + tracepoint

# in some version of kernel, these two types of events did not work together
EVENT_HWCACHE=`$CMD_PERF list hwcache | grep "Hardware cache event" | awk '{print $1}' | head -n 1`
EVENT_TRACEPOINT=`$CMD_PERF list tracepoint | grep "Tracepoint event" | awk '{print $1}' | head -n 1`
if [ -z "$EVENT_HWCACHE" -o -z "$EVENT_TRACEPOINT" ]; then
	print_testcase_skipped "hwcache + tracepoint :: record"
	print_testcase_skipped "hwcache + tracepoint :: evlist"
else
	$CMD_PERF record -e $EVENT_HWCACHE -e $EVENT_TRACEPOINT -o $CURRENT_TEST_DIR/perf.data -a $CMD_LONGER_SLEEP 2> $LOGS_DIR/basic_hwcache_tracepoint_record.err
	PERF_EXIT_CODE=$?

	# check the perf record output
	../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/basic_hwcache_tracepoint_record.err
	CHECK_EXIT_CODE=$?
	../common/check_errors_whitelisted.pl "stderr-whitelist.txt" < $LOGS_DIR/basic_hwcache_tracepoint_record.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "hwcache + tracepoint :: record"
	(( TEST_RESULT += $? ))


	# check the events recorded
	$CMD_PERF evlist -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_hwcache_tracepoint_evlist.log
	PERF_EXIT_CODE=$?

	# check the events used
	../common/check_all_patterns_found.pl "$EVENT_HWCACHE" "$EVENT_TRACEPOINT" < $LOGS_DIR/basic_hwcache_tracepoint_evlist.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "hwcache + tracepoint :: evlist"
	(( TEST_RESULT += $? ))
fi


### BUG: perf record -k mono crashes with perf.data stream redirected to stdout

# when perf record detects that stdout is piped, it puts the data there instead of to perf.data
# when there is '-k mono' option, it used to segfault
# this testcase tests, whether the segfault is fixed
sh -c "$CMD_PERF record -k mono -- true | cat" > $LOGS_DIR/basic_kmono_crash.out 2> $LOGS_DIR/basic_kmono_crash.err

../common/check_no_patterns_found.pl "Segmentation fault" "SIGSEGV" "core" "dumped" "segfault" < $LOGS_DIR/basic_kmono_crash.err
PERF_EXIT_STATUS=$?

print_results $PERF_EXIT_STATUS 0 "-k mono crash"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
