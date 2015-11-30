#
#	cleanup.sh of perf buildid test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`

find . -name \*.log | xargs -r rm
find . -name \*.err | xargs -r rm
test -e perf.data && rm -rf perf.data

print_results 0 0 "clean-up logs"
exit $?
