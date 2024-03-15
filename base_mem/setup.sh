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

if [ -n "$PERFSUITE_RUN_DIR" ]; then
	# when $PERFSUITE_RUN_DIR is set to something, all the logs and temp files will be placed there
	# --> the $PERFSUITE_RUN_DIR/perf_something/examples and $PERFSUITE_RUN_DIR/perf_something/logs
	#     dirs will be used for that
	test -d "$MAKE_TARGET_DIR" || mkdir -p "$MAKE_TARGET_DIR"
fi

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
