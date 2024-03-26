#!/bin/bash

#
#       cleanup.sh of perf_kmem test
#       Author: Michael Petlan <mpetlan@redhat.com>
#
#       Description:
#               FIXME
#
#

. ../common/init.sh

if [ -n "$PERFSUITE_RUN_DIR" ]; then
        print_overall_skipped
        exit 0
fi

find . -name \*.log -print0 | xargs -r -0 rm
find . -name \*.err -print0 | xargs -r -0 rm
rm -f perf.data*

print_overall_results 0
exit 0
