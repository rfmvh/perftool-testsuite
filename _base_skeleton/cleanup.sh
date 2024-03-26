#!/bin/bash

#
#	cleanup.sh of SKELETON test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		FIXME
#
#

. ../common/init.sh

if [ -n "$PERFSUITE_RUN_DIR" ]; then
	print_overall_skipped
	exit 0
fi

print_overall_results 0
exit 0
