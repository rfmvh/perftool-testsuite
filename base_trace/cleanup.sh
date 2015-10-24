#
#	cleanup.sh of perf_trace test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		FIXME
#
#

. ../common/settings.sh
. ../common/patterns.sh
. ../common/init.sh
. ./settings.sh

find . -name \*.log | xargs rm
find . -name \*.err | xargs rm
rm -f perf.data*
print_overall_results 0
exit 0
