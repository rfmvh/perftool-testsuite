#!/bin/bash

#
#	setup.sh of perf_trace test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		FIXME
#
#

. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`

make -s -C examples
print_results $? 0 "building the example code"
TEST_RESULT=$?

print_overall_results $TEST_RESULT
exit $?
