#!/bin/bash

#
#	setup.sh of perf diff test
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

# record some data 1
$CMD_PERF record -o $CURRENT_TEST_DIR/perf.data.1 $CURRENT_TEST_DIR/examples/load > /dev/null 2> $LOGS_DIR/setup_record_1.log
PERF_EXIT_CODE=$?

# check the perf record output sanity
../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" < $LOGS_DIR/setup_record_1.log
CHECK_EXIT_CODE=$?

../common/check_errors_whitelisted.pl "stderr-whitelist.txt" < $LOGS_DIR/setup_record_1.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "record data #1"
(( TEST_RESULT += $? ))


# record some data 2
$CMD_PERF record -o $CURRENT_TEST_DIR/perf.data.2 $CURRENT_TEST_DIR/examples/load 21 > /dev/null 2> $LOGS_DIR/setup_record_2.log
PERF_EXIT_CODE=$?

# check the perf record output sanity
../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" < $LOGS_DIR/setup_record_2.log
CHECK_EXIT_CODE=$?

../common/check_errors_whitelisted.pl "stderr-whitelist.txt" < $LOGS_DIR/setup_record_2.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "record data #2"
(( TEST_RESULT += $? ))

print_overall_results $TEST_RESULT
exit $?
