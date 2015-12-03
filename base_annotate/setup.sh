#!/bin/bash

#
#	setup.sh of perf annotate test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		FIXME - build C program
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`

make -s -C examples
print_results $? 0 "building the example code"
TEST_RESULT=$?

# record some data
$CMD_PERF record examples/load > /dev/null 2> setup_record.log
PERF_EXIT_CODE=$?   

# check the perf record output
../common/check_all_lines_matched.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" < setup_record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "record data"
(( TEST_RESULT += $? ))

print_overall_results $TEST_RESULT
exit $?
