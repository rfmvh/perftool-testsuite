#!/bin/bash

#
#	setup.sh of perf mem test
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

# skip the testcase if $PERFSUITE_RUN_DIR is set, since we
# cannot guarantee not writting into the current tree (we
# miss '-o' option in 'perf mem record'
if [ -n "$PERFSUITE_RUN_DIR" ]; then
	print_overall_skipped
	exit 0
fi

make -s -C examples
print_results $? 0 "building the example code"
TEST_RESULT=$?

print_overall_results $TEST_RESULT
exit $?
