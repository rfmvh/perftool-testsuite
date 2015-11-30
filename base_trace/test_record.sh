#
#	test_record of perf_trace test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests the sampling mode of perf-trace.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


#### basic execution

# test that perf trace record is working
$CMD_PERF trace record $CMD_QUICK_SLEEP 2> record_basic_record.log
PERF_EXIT_CODE=$?
$CMD_PERF report --stdio > record_basic_report.log 2> record_basic_report.err
(( PERF_EXIT_CODE += $? ))

# check the perf record output
../common/check_all_lines_matched.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" < record_basic_record.log
CHECK_EXIT_CODE=$?
# check the perf report output
../common/check_all_lines_matched.pl "$RE_LINE_REPORT_CONTENT" "$RE_LINE_EMPTY" "$RE_LINE_COMMENT" < record_basic_report.log
(( CHECK_EXIT_CODE += $? ))
# check that the perf report stderr is empty
test ! -s record_basic_report.err
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "basic execution - record"
(( TEST_RESULT += $? ))


# print overall resutls
print_overall_results "$TEST_RESULT"
exit $?
