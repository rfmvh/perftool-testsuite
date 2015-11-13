#
#	cleanup.sh of perf annotate test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#

# include working environment
. ../common/settings.sh
. ../common/patterns.sh
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`

make -C examples clean

find . -name \*.log | xargs rm
find . -name \*.err | xargs rm
rm -f perf.data

print_results 0 0 "clean-up logs"
exit $?
