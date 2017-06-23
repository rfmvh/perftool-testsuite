#!/bin/bash

#
#	cleanup.sh of perf stat test
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
test -d sw && rmdir sw
test -d hw && rmdir hw
test -d hwcache && rmdir hwcache
test -d hv24x7 && rmdir hv_24x7
test -d intel_uncore && rmdir intel_uncore
print_overall_results 0
exit 0
