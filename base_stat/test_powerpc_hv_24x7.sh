#
#	test_powerpc_hv24x7 of perf_stat test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests hardware events by perf stat.
#
#

# include working environment
. ../common/settings.sh
. ../common/patterns.sh
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

EVENTS_TO_TEST=`$CMD_PERF list | grep "24x7" | grep "core" | awk '{print $1}' | tr '\n' ' '`
if [ -z "$EVENTS_TO_TEST" ]; then
	print_overall_skipped
	exit 0
fi

test -d hv_24x7 || mkdir hv_24x7

if [ "$PARAM_STAT_24x7_ALL_CORES" = "y" ]; then
	NPROC=`nproc`
	CORES_TO_TEST="`seq 0 $((NPROC-1))`"
else
	CORES_TO_TEST="0"
fi

#### testing hv_24x7 events

for event in $EVENTS_TO_TEST; do
	EVENT_NAME=`echo $event | awk -F',' '{print $1}' | awk -F'/' '{print $2}'`
	PERF_EXIT_CODE=0
	for core in $CORES_TO_TEST; do
		evt=`echo $event | sed "s/\?/$core/"`
		$CMD_PERF stat -a -e $evt -o hv_24x7/$EVENT_NAME.log --append -x';' -- $CMD_QUICK_SLEEP
		(( PERF_EXIT_CODE += $? ))
	done
	REGEX_LINES="$RE_NUMBER;+hv_24x7\/$EVENT_NAME,core=$RE_NUMBER\/;$RE_NUMBER;100\.00"
	../common/check_all_patterns_found.pl "$REGEX_LINES" < hv_24x7/$EVENT_NAME.log
	CHECK_EXIT_CODE=$?
	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "event $EVENT_NAME"
	(( TEST_RESULT += $? ))
done

# print overall resutls
print_overall_results "$TEST_RESULT"
exit $?



# FIXME we should test the numbers
# FIXME add lpar/vcpu events? maybe configurable
# FIXME "You have POWER8 LPAR, so I think you should have hv24x7 but you do not!" warning
