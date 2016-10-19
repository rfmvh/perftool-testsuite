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
. ./settings.sh

THIS_TEST_NAME="setup"

# clear the cache
clear_buildid_cache

# record some perf.data
$CMD_PERF --buildid-dir $BUILDIDDIR record -o $CURRENT_TEST_DIR/perf.data -a -- $CMD_LONGER_SLEEP &> $LOGS_DIR/setup.log
print_results $? 0 "creating perf.data and buildid-cache"

print_overall_results $?
(( TEST_RESULT += $? ))
