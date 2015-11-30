#
#	cleanup.sh of perf stat test
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

find . -name \*.log | xargs -r rm
test -d hw && rmdir hw
test -d hwcache && rmdir hwcache
test -d hv24x7 && rmdir hv_24x7
test -d intel_uncore && rmdir intel_uncore
print_overall_results 0
exit 0
