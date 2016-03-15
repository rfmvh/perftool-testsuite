#!/bin/bash

#
#	cleanup.sh of perf buildid test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

if [ ! -n "$PERFSUITE_RUN_DIR" ]; then
	remove_buildid_cache
	find . -name \*.log | xargs -r rm
	find . -name \*.err | xargs -r rm
	test -e perf.data && rm -rf perf.data
else
	mv "$BUILDIDDIR" "$PERFSUITE_RUN_DIR/perf_buildid-cache/"
fi

print_overall_results 0
exit $?
