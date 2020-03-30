#!/bin/bash

#
#	cleanup.sh of perf_data test
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
rm -f perf.data*
rm -rf $LOGS_DIR/converted_ctf
rm -rf $LOGS_DIR/converted_all_ctf

print_overall_results 0
exit 0
