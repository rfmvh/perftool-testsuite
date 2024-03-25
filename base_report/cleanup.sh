#!/bin/bash

#
#	cleanup.sh of perf report test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#

# include working environment
. ../common/init.sh

if [ -n "$PERFSUITE_RUN_DIR" ]; then
	print_overall_skipped
	exit 0
fi

find . -name \*.log -print0 | xargs -r -0 rm
find . -name \*.err -print0 | xargs -r -0 rm
rm -r header_tar
rm -f perf.data*
RM_EXIT_CODE=$?

print_overall_results $RM_EXIT_CODE
exit $?
