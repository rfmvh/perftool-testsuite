#
#	cleanup.sh of perf_trace test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		FIXME
#
#

. ../common/init.sh
. ./settings.sh

find . -name \*.log | xargs -r rm
find . -name \*.err | xargs -r rm
rm -f perf.data*
print_overall_results 0
exit 0
