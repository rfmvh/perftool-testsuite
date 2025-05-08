#!/bin/bash

#
#	test_hwcache of perf_stat test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests hardware events by perf stat.
#
#

# include working environment
. ../common/init.sh

TEST_RESULT=0

EVENTS_TO_TEST=`$CMD_PERF list hwcache | grep -P "^\s{2}\w" | awk '{print $3}' | egrep '^.' | tr '\n' ' '`
if [ -z "$EVENTS_TO_TEST" ]; then
	if [ "$TEST_IGNORE_MISSING_PMU" = "y" ]; then
		print_overall_skipped
		exit 0
	else
		if should_support_pmu; then
			print_results 1 1 "PMU support not found despite being expected (no hwcache events)"
			print_overall_results 1
			exit $?
		else
			print_overall_skipped
			exit 0
		fi
	fi
fi

test -d $LOGS_DIR/hwcache || mkdir $LOGS_DIR/hwcache

# FIXME test -e hw.log && rm -f hw.log

# free the potentially seized counter
disable_nmi_watchdog_if_exists


#### testing hardware cache events

for event in $EVENTS_TO_TEST; do
	log_name=`echo $event | awk -F'/' '{print $(NF-1)}'`
	$CMD_PERF stat -a -e $event -o $LOGS_DIR/hwcache/$log_name.log --append -x';' -- $CMD_BASIC_SLEEP
	PERF_EXIT_CODE=$?
	REGEX_LINES="$RE_NUMBER;+(?:\w+\/)?$event\/?;$RE_NUMBER;100\.00"
	../common/check_all_patterns_found.pl "$REGEX_LINES" < $LOGS_DIR/hwcache/$event.log
	CHECK_EXIT_CODE=$?
	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "event $event"
	(( TEST_RESULT += $? ))
done


#### testing kernel vs userspace

# remove some events that does not make sense to test like this
#EVENTS_TO_TEST=${EVENTS_TO_TEST/stalled-cycles-frontend/}

if false; then # THIS IS DISABLED,
# --> there's probably a bug in perf due to which the event modifiers are not printed in the
# results in case of hwcache events
for event in $EVENTS_TO_TEST; do
	$CMD_PERF stat -e $event:k -e $event:u -e $event:ku -o $LOGS_DIR/hwcache/$event--ku.log -x';' -- $CMD_SIMPLE
	PERF_EXIT_CODE=$?
	../common/check_ku_sum.pl < $LOGS_DIR/hwcache/$event--ku.log
	CHECK_EXIT_CODE=$?
	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "k+u=ku check :: event $event"
	(( TEST_RESULT += $? ))
done
fi

restore_nmi_watchdog_if_needed

# print overall results
print_overall_results "$TEST_RESULT"
exit $?



# FIXME we should test the numbers
# FIXME we should be able to blacklist events on some archs (<not supported> is OK (SNB, IVB))
