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
	$CMD_PERF stat -a -e $event -o $LOGS_DIR/sw/$event.log --append -x';' -- $CMD_LONGER_SLEEP 2> $LOGS_DIR/test_sw.err
	PERF_EXIT_CODE=$?
	REGEX_LINES="$RE_NUMBER;+$event;$RE_NUMBER;100\.00"
	test -e $LOGS_DIR/sw/$event.log && ../common/check_all_patterns_found.pl "$REGEX_LINES" < $LOGS_DIR/sw/$event.log
	CHECK_EXIT_CODE=$?
	if [ $TESTLOG_VERBOSITY -ge 2 -a $PERF_EXIT_CODE -ne 0 ]; then
		cat $LOGS_DIR/test_sw.err
	fi
	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "event $event"
	(( TEST_RESULT += $? ))
done


#### testing kernel vs userspace

# remove some events that does not make sense to test like this
EVENTS_TO_TEST=${EVENTS_TO_TEST/cpu-clock/}
EVENTS_TO_TEST=${EVENTS_TO_TEST/task-clock/}

for event in $EVENTS_TO_TEST; do
	$CMD_PERF stat -e $event:k -e $event:u -e $event:ku -o $LOGS_DIR/sw/$event--ku.log -x';' -- $CMD_SIMPLE 2> $LOGS_DIR/test_sw.err
	PERF_EXIT_CODE=$?
	test -e $LOGS_DIR/sw/$event--ku.log && ../common/check_ku_sum.pl < $LOGS_DIR/sw/$event--ku.log
	CHECK_EXIT_CODE=$?
	if [ $TESTLOG_VERBOSITY -ge 2 -a $PERF_EXIT_CODE -ne 0 ]; then
		cat $LOGS_DIR/test_sw.err
	fi
	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "k+u=ku check :: event $event"
	(( TEST_RESULT += $? ))
done


rm -f $LOGS_DIR/test_sw.err

# print overall results
print_overall_results "$TEST_RESULT"
exit $?



# FIXME we should test the numbers
