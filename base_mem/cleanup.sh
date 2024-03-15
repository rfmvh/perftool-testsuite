#!/bin/bash

#
#	cleanup.sh of perf mem test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#

# include working environment
. ../common/init.sh

if [ -n "$PERFSUITE_RUN_DIR" ]; then
	print_overall_skipped
	exit 0
fi

make -s -C examples clean

find . -name \*.log | xargs -r rm
find . -name \*.err | xargs -r rm
rm -f perf.data*
RM_EXIT_CODE=$?

print_overall_results $RM_EXIT_CODE
exit $?
