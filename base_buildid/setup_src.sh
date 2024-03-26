#!/bin/bash

#
#	setup.sh of perf buildid test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This file is to be sourced in all the tests
#	that need it. This is because of the custom dir
#	for buildids.
#
#

# include working environment
. ../common/init.sh

# the test name needs to be reset here
# shellcheck disable=SC2034 # the variable is later used after the working environment is included
THIS_TEST_NAME="setup"

# clear the cache
clear_buildid_cache

# record some perf.data
$CMD_PERF --buildid-dir $BUILDIDDIR record -o $CURRENT_TEST_DIR/perf.data -a -- $CMD_LONGER_SLEEP &> $LOGS_DIR/setup.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" < $LOGS_DIR/setup.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "creating perf.data and buildid-cache"

print_overall_results $?
(( TEST_RESULT += $? ))
