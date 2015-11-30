#
#	setup.sh of perf buildid test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		FIXME - maybe the setup is not necessary
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`

# clear the cache
clear_buildid_cache

# record some perf.data
$CMD_PERF record -a -- $CMD_LONGER_SLEEP &> setup.log

print_overall_results $?
exit $?
