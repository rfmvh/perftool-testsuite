#
#	cleanup.sh of perf report test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#

THIS_TEST_NAME=`basename $0`

find . -name \*.log | xargs rm
find . -name \*.err | xargs rm

rm -f perf.data*
RM_EXIT_CODE=$?

print_results $RM_EXIT_CODE 0 "clean-up perf.data file and logs"
exit $?
