#!/bin/bash

#
#	setup.sh of perf archive test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		We need some sample data for perf-report testing
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME="setup"

# clear the cache
clear_buildid_cache

make -s -C examples
print_results $? 0 "building the example code"
TEST_RESULT=$?

$CMD_PERF --buildid-dir $BUILDIDDIR record -a -o $CURRENT_TEST_DIR/perf.data -- $CURRENT_TEST_DIR/examples/load > /dev/null 2> $LOGS_DIR/setup.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" < $LOGS_DIR/setup.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "prepare the perf.data file"

print_overall_results $?
(( TEST_RESULT += $? ))
