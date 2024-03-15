#!/bin/bash

#
#	setup.sh of perf probe test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		We need to clean-up all the previously added probes
#		FIXME
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

make -s -C examples
print_results $? 0 "building examples"
TEST_RESULT=$?

print_overall_results $TEST_RESULT
exit $?
