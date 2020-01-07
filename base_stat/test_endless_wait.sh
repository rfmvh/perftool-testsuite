#!/bin/bash

#
#	test_endless_wait of perf_stat test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test checks whether perf-stat gets stuck by a child process.
#	Tests what the following linux commit fixes:
#
#	commit 8a99255a50c0b4c2a449b96fd8d45fcc8d72c701
#	Author: Jin Yao <yao.jin@linux.intel.com>
#	Date:   Thu Jan 3 15:40:45 2019 +0800
#	perf stat: Fix endless wait for child process
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

consider_skipping $RUNMODE_STANDARD

### perf does not get stuck

# the exec_perf.sh should take 2 seconds and not 4
sh -c "time $CURRENT_TEST_DIR/auxiliary/exec_perf.sh" 2> $LOGS_DIR/endless_wait.log

REGEX_REAL_TIME_BAD="^real\s+0m`echo $CMD_DOUBLE_LONGER_SLEEP | cut -d' ' -f2`"
REGEX_REAL_TIME_GOOD="^real\s+0m`echo $CMD_LONGER_SLEEP | cut -d' ' -f2`"
REGEX_RESULT_LINE="\s+$RE_NUMBER\s+$RE_NUMBER\s+msec\s+cpu-clock"

../common/check_no_patterns_found.pl "$REGEX_REAL_TIME_BAD" < $LOGS_DIR/endless_wait.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_REAL_TIME_GOOD" "$REGEX_RESULT_LINE" < $LOGS_DIR/endless_wait.log
(( CHECK_EXIT_CODE += $? ))

print_results 0 $CHECK_EXIT_CODE "perf does not get stuck"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
