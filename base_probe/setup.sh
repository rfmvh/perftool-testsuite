#
#	setup.sh of perf probe test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		We need to clean-up all the previously added probes
#		FIXME
#
#

# include working environment
. ../common/settings.sh
. ../common/patterns.sh
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0`

make -c examples

print_results $? 0 "building examples"
exit $?
