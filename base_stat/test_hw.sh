#!/bin/bash

#
#	test_hw of perf_stat test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests hardware events by perf stat.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

EVENTS_TO_TEST=`$CMD_PERF list hw | grep "Hardware event" | awk '{print $1}' | egrep '^.' | tr '\n' ' '`
if [ -z "$EVENTS_TO_TEST" ]; then
	if [ "$TEST_IGNORE_MISSING_PMU" = "y" ]; then
		print_overall_skipped
		exit 0
	else
		if should_support_pmu; then
			print_results 1 1 "PMU support not found despite being expected (no hw events)"
			print_overall_results 1
			exit $?
		else
			print_overall_skipped
			exit 0
		fi
	fi
fi

# FIXME test -e hw.log && rm -f hw.log

test -d $LOGS_DIR/hw || mkdir $LOGS_DIR/hw

# free the potentially seized counter
disable_nmi_watchdog_if_exists


#### testing hardware events

for event in $EVENTS_TO_TEST; do
	$CMD_PERF stat -a -e $event -o $LOGS_DIR/hw/$event.log --append -x';' -- $CMD_BASIC_SLEEP
	PERF_EXIT_CODE=$?
	REGEX_LINES="$RE_NUMBER;+(?:\w+\/)?$event\/?;$RE_NUMBER;100\.00"
	../common/check_all_patterns_found.pl "$REGEX_LINES" < $LOGS_DIR/hw/$event.log
	CHECK_EXIT_CODE=$?
	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "event $event"
	(( TEST_RESULT += $? ))
done


#### testing kernel vs userspace

if ! [[ "$MY_ARCH" =~ ppc64.* ]]; then
	# remove some events that does not make sense to test like this
	EVENTS_TO_TEST=${EVENTS_TO_TEST/ref-cycles/}
	EVENTS_TO_TEST=${EVENTS_TO_TEST/stalled-cycles-backend/}
	EVENTS_TO_TEST=${EVENTS_TO_TEST/stalled-cycles-frontend/}

	DEVICES=`ls -d /sys/devices/cpu* | perl -pe 's#/sys/devices/##g'`

	for dev in $DEVICES; do
	    # check if all events can separate kernel/userspace
	    # and whether the results fit into the "ku = k + u" formula
	    for event in $EVENTS_TO_TEST; do
		$CMD_PERF stat -e "{$dev/$event:k/,$dev/$event:u/,$dev/$event:ku/}" -o $LOGS_DIR/hw/$dev-$event--ku.log -x';' -a -- $CMD_SIMPLE
		PERF_EXIT_CODE=$?
		../common/check_ku_sum.pl < $LOGS_DIR/hw/$dev-$event--ku.log
		CHECK_EXIT_CODE=$?
		print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "k+u=ku check :: event $dev/$event/"
		(( TEST_RESULT += $? ))
	    done
	done
else
	print_testcase_skipped "k+u=ku check"
fi

restore_nmi_watchdog_if_needed

# print overall results
print_overall_results "$TEST_RESULT"
exit $?



# FIXME we should test the numbers
# FIXME we should be able to blacklist events on some archs (<not supported> is OK (SND, IVB))
