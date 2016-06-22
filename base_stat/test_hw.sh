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
	print_overall_skipped
	exit 0
fi

# FIXME test -e hw.log && rm -f hw.log

test -d $LOGS_DIR/hw || mkdir $LOGS_DIR/hw


#### testing hardware events

for event in $EVENTS_TO_TEST; do
	$CMD_PERF stat -a -e $event -o $LOGS_DIR/hw/$event.log --append -x';' -- $CMD_BASIC_SLEEP
	PERF_EXIT_CODE=$?
	REGEX_LINES="$RE_NUMBER;+$event;$RE_NUMBER;100\.00"
	../common/check_all_patterns_found.pl "$REGEX_LINES" < $LOGS_DIR/hw/$event.log
	CHECK_EXIT_CODE=$?
	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "event $event"
	(( TEST_RESULT += $? ))
done


#### testing kernel vs userspace

# remove some events that does not make sense to test like this
EVENTS_TO_TEST=${EVENTS_TO_TEST/ref-cycles/}
EVENTS_TO_TEST=${EVENTS_TO_TEST/stalled-cycles-backend/}
EVENTS_TO_TEST=${EVENTS_TO_TEST/stalled-cycles-frontend/}

for event in $EVENTS_TO_TEST; do
	$CMD_PERF stat -e $event:k -e $event:u -e $event:ku -o $LOGS_DIR/hw/$event--ku.log -x';' -- $CMD_SIMPLE
	PERF_EXIT_CODE=$?
	../common/check_ku_sum.pl < $LOGS_DIR/hw/$event--ku.log
	CHECK_EXIT_CODE=$?
	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "k+u=ku check :: event $event"
	(( TEST_RESULT += $? ))
done


# print overall resutls
print_overall_results "$TEST_RESULT"
exit $?



# FIXME we should test the numbers
# FIXME we should be able to blacklist events on some archs (<not supported> is OK (SND, IVB))
