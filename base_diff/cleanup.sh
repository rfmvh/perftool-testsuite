#!/bin/bash

#
#	cleanup.sh of perf diff test
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
find . -name \*.log -print0 | xargs -r -0 rm
find . -name \*.err -print0 | xargs -r -0 rm
rm -f perf.data*

print_overall_results 0
exit $?
