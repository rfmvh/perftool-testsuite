#!/bin/bash

#
#	test_scripts of perf_script test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests all available scripts shipped with perf.
#
#

# include working environment
. ../common/init.sh

TEST_RESULT=0

consider_skipping $RUNMODE_EXPERIMENTAL

#### sanity test all scripts shipped with perf

AVAILABLE_SCRIPTS=`$CMD_PERF script -l | perl -ne 'print "$1 " if /^\s\s([\w\-]+)\s/'`

if [ $# -ge 1 ]; then
	# if there are args, consider them as substrings of names of scripts we want to run
	# e.g. `./test_scripts.sh rw` should run "rwtop", "rw-by-pid" and "rw-by-file"
	# --> perf does this in a similar way with tests (see perf-test)
	TESTED_SCRIPTS=""
	while test -n "$1"; do
		TESTED_SCRIPTS="$TESTED_SCRIPTS `echo "$AVAILABLE_SCRIPTS" | tr ' ' '\n' | grep "$1"`"
		shift
	done
	# squash dups if any
	TESTED_SCRIPTS=`echo $TESTED_SCRIPTS | tr ' ' '\n' | sort -u | tr '\n' ' '`
else
	# without arguments, run all
	TESTED_SCRIPTS="$AVAILABLE_SCRIPTS"
fi

for scr in $TESTED_SCRIPTS; do
	if [ ! -f $CURRENT_TEST_DIR/subtest__$scr.sh ]; then
		print_testcase_skipped "script $scr"
		continue
	fi
	# shellcheck source=/dev/null
	. $CURRENT_TEST_DIR/subtest__$scr.sh
done


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
