#!/bin/bash

#
#	cleanup.sh of perf report test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`

find . -name \*.log | xargs -r rm
find . -name \*.err | xargs -r rm

rm -f perf.data*
RM_EXIT_CODE=$?

print_results $RM_EXIT_CODE 0 "clean-up perf.data file and logs"
exit $?
