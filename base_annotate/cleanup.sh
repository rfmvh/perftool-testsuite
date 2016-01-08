#!/bin/bash

#
#	cleanup.sh of perf annotate test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`

make -s -C examples clean

find . -name \*.log | xargs -r rm
find . -name \*.err | xargs -r rm
rm -f perf.data*

print_results 0 0 "clean-up logs"
exit $?
