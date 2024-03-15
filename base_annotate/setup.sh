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

# shellcheck disable=SC2034 # the variable is later used after the working environment is included
THIS_TEST_NAME=`basename $0 .sh`

if [ -n "$PERFSUITE_RUN_DIR" ]; then
	# when $PERFSUITE_RUN_DIR is set to something, all the logs and temp files will be placed there
	# --> the $PERFSUITE_RUN_DIR/perf_something/examples and $PERFSUITE_RUN_DIR/perf_something/logs
	#     dirs will be used for that
	test -d "$MAKE_TARGET_DIR" || mkdir -p "$MAKE_TARGET_DIR"
fi

make -s -C examples
print_results $? 0 "building the example code"
TEST_RESULT=$?

# record some data
$CMD_PERF record -o $CURRENT_TEST_DIR/perf.data $CURRENT_TEST_DIR/examples/load > /dev/null 2> $LOGS_DIR/setup_record.log
PERF_EXIT_CODE=$?

# check the perf record output sanity
../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" < $LOGS_DIR/setup_record.log
CHECK_EXIT_CODE=$?

../common/check_errors_whitelisted.pl "stderr-whitelist.txt" < $LOGS_DIR/setup_record.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "record data"
(( TEST_RESULT += $? ))

print_overall_results $TEST_RESULT
exit $?
