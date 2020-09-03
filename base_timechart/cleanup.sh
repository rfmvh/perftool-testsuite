#!/bin/bash

#
#	cleanup.sh of perf_kmem test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		FIXME
#
#

. ../common/init.sh
. ./settings.sh

if [ -n "$PERFSUITE_RUN_DIR" ]; then
	print_overall_skipped
	exit 0
fi

find . -name \*.log | xargs -r rm
find . -name \*.err | xargs -r rm
find . -name \*.svg | xargs -r rm
find . -name \*.diff | xargs -r rm
rm -f perf.data*

print_overall_results 0
exit 0
