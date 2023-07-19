#!/bin/bash

#
#	cleanup.sh of perf_version test
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

print_overall_results 0
exit 0
