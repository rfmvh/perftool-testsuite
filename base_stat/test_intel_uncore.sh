#
#	test_intel_uncore of perf_stat test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests support of uncore events
#
#

# include working environment
. ../common/settings.sh
. ../common/patterns.sh
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0`
TEST_RESULT=0

EVENTS_TO_TEST=`$CMD_PERF list | grep "uncore" | awk '{print $1}' | tr '\n' ' '`
if [ -z "$EVENTS_TO_TEST" ]; then
	print_overall_skipped
	exit 0
fi

test -d intel_uncore || mkdir intel_uncore


#### testing Intel uncore events

for event in $EVENTS_TO_TEST; do
	EVENT_NAME=`echo $event | tr '/' '_' | tr ',' '-'`
	$CMD_PERF stat -a -e $event -o intel_uncore/$EVENT_NAME.log -x';' -- $CMD_QUICK_SLEEP
	PERF_EXIT_CODE=$?

	REGEX_LINES="$RE_NUMBER;[^;]*;$RE_EVENT_ANY;$RE_NUMBER;100\.00"
	../common/check_all_patterns_found.pl "$REGEX_LINES" < intel_uncore/$EVENT_NAME.log
	CHECK_EXIT_CODE=$?
	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "event $event"
	(( TEST_RESULT += $? ))
done


# print overall resutls
print_overall_results "$TEST_RESULT"
exit $?
