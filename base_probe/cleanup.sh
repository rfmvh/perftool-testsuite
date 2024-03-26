#!/bin/bash

#
#	cleanup.sh of perf probe test
#	Author: Michael Petlan <mpetlan@redhat.com>
#	Author: Masami Hiramatsu <masami.hiramatsu.pt@hitachi.com>
#
#

# include working environment
. ../common/init.sh

clear_all_probes
if [ ! -n "$PERFSUITE_RUN_DIR" ]; then
	find . -name \*.log -print0 | xargs -0 -r rm
	find . -name \*.err -print0 | xargs -0 -r rm
	rm -f perf.data*
	make -s -C examples clean
fi

print_overall_results 0
exit $?
