#
#	test_tracepoints_definition.sh of perf_stat test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test checks the tracepoints for syntax
#	errors in definition. It takes a long time, so
#	that's why the test can be disabled by an option
#	in common/parametrization.sh
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

if [ ! "$PARAM_STAT_TRACEPOINT_EVENTS_SYNTAX" == "y" ]; then
	print_overall_skipped
	exit 0
fi

# remove old logs
find . -name tracepoints_def_\*.log | xargs -r rm

### check all the tracepoint events of all the available subsystems

SUBSYSTEMS=`$CMD_PERF list tracepoint | grep "Tracepoint event" | awk '{print $1}' | awk -F':' '{print $1}' | sort -u`
for subs in $SUBSYSTEMS; do
	TRACEPOINT_EVENTS=`$CMD_PERF list $subs:\* | grep "Tracepoint event" | awk '{print $1}' | tr '\n' ' '`
	PERF_EXIT_CODE=0
	for tp in $TRACEPOINT_EVENTS; do
		$CMD_PERF stat -e $tp -o /dev/stdout true > out 2> err
		(( PERF_EXIT_CODE += $? ))
		echo -n "$tp    is " >> tracepoints_def_$subs.log

		# check whether the event is supported when it is listed
		grep -qi "not supported" out
		test $? -eq 0 && echo -n "NOT SUPPORTED and " >> tracepoints_def_$subs.log || echo -n "supported and " >> tracepoints_def_$subs.log

		# check whether the event causes any warnings
		test -s err
		test $? -eq 0 && echo "CAUSES WARNINGS" >> tracepoints_def_$subs.log || echo "is defined correctly" >> tracepoints_def_$subs.log
	done

	# check for the results
	! grep -e "CAUSES WARNINGS" -e "NOT SUPPORTED" tracepoints_def_$subs.log
	print_results $PERF_EXIT_CODE $? "subsystem $subs"
	(( TEST_RESULT += $? ))
done

rm -f err out

print_overall_results "$TEST_RESULT"
exit $?
