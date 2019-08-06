#!/bin/bash

#
#	test_scripts of perf_script test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests all available scripts shipped with perf.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


#### sanity test all scripts shipped with perf

AVAILABLE_SCRIPTS=`$CMD_PERF script -l | awk '{print $1}'`

for scr in $AVAILABLE_SCRIPTS; do
	if [ ! -f $CURRENT_TEST_DIR/subtest__$scr.sh ]; then
		print_testcase_skipped "script $scr"
		continue
	fi
	. $CURRENT_TEST_DIR/subtest__$scr.sh
done


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
