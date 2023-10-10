#!/bin/bash

#
#	test_basic of perf_version test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf version command.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


#### basic execution

# test that perf trace is working
$CMD_PERF version > $LOGS_DIR/basic_basic.log
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "perf version" < $LOGS_DIR/basic_basic.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "perf version \d" < $LOGS_DIR/basic_basic.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "basic execution"
(( TEST_RESULT += $? ))


#### invalid option

# BUG: perf version crashes with an invalid option
{ sh -c "$CMD_PERF version -t"; } > $LOGS_DIR/basic_invalid_opt.log 2> $LOGS_DIR/basic_invalid_opt.err
test $? -ne 139
PERF_EXIT_CODE=$?

../common/check_no_patterns_found.pl "$RE_SEGFAULT" < $LOGS_DIR/basic_invalid_opt.err
CHECK_EXIT_CODE=$?
#../common/check_all_patterns_found.pl "Error" "unknown switch" "Usage" "perf version" "build-options" < $LOGS_DIR/basic_invalid_opt.err
#(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "invalid option"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
