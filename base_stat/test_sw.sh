#!/bin/bash

#
#	test_sw of perf_stat test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests software events by perf stat.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

EVENTS_TO_TEST=`$CMD_PERF list sw | grep "Software event" | awk '{print $1}' | egrep '^.' | tr '\n' ' '`
if [ -z "$EVENTS_TO_TEST" ]; then
	print_overall_skipped
	exit 0
fi

test -d $LOGS_DIR/sw || mkdir $LOGS_DIR/sw


#### testing software events

for event in $EVENTS_TO_TEST; do
	$CMD_PERF stat -a -e $event -o $LOGS_DIR/sw/$event.log --append -x';' -- $CMD_LONGER_SLEEP
	PERF_EXIT_CODE=$?
	REGEX_LINES="$RE_NUMBER;+$event;$RE_NUMBER;100\.00"
	../common/check_all_patterns_found.pl "$REGEX_LINES" < $LOGS_DIR/sw/$event.log
	CHECK_EXIT_CODE=$?
	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "event $event"
	(( TEST_RESULT += $? ))
done


#### testing kernel vs userspace

# remove some events that does not make sense to test like this
EVENTS_TO_TEST=${EVENTS_TO_TEST/cpu-clock/}
EVENTS_TO_TEST=${EVENTS_TO_TEST/task-clock/}

for event in $EVENTS_TO_TEST; do
	$CMD_PERF stat -e $event:k -e $event:u -e $event:ku -o $LOGS_DIR/sw/$event--ku.log -x';' -- $CMD_SIMPLE
	PERF_EXIT_CODE=$?
	../common/check_ku_sum.pl < $LOGS_DIR/sw/$event--ku.log
	CHECK_EXIT_CODE=$?
	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "k+u=ku check :: event $event"
	(( TEST_RESULT += $? ))
done


# print overall results
print_overall_results "$TEST_RESULT"
exit $?



# FIXME we should test the numbers
