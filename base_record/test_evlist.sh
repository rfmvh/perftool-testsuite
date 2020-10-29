#!/bin/bash

#
#	test_evlist of perf_record test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf evlist command,
#	which should show events used in a sampling session saved in perf.data
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


### help message

if [ "$PARAM_GENERAL_HELP_TEXT_CHECK" = "y" ]; then
	# test that a help message is shown and looks reasonable
	$CMD_PERF evlist --help > $LOGS_DIR/basic_helpmsg.log
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "PERF-EVLIST" "NAME" "SYNOPSIS" "DESCRIPTION" "OPTIONS" "SEE ALSO" < $LOGS_DIR/basic_helpmsg.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "input" "verbose" "freq" "group" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "help message"
fi


### sample frequency check

EVENT="cpu-cycles"
CYCLES_AVAIL=`$CMD_PERF list | grep "$EVENT"`
if [ -n "$CYCLES_AVAIL" ]; then
	for frq in 100 200 1000; do
		# make sure the frequency is not too low
		SAMPLE_RATE=`cat /proc/sys/kernel/perf_event_max_sample_rate`
		test $SAMPLE_RATE -lt 2000 && echo 25000 > /proc/sys/kernel/perf_event_max_sample_rate

		# record with frequency $frq
		$CMD_PERF record -a -e $EVENT -o $CURRENT_TEST_DIR/perf.data -F $frq -- $CMD_LONGER_SLEEP > $LOGS_DIR/evlist_freq_record_$frq.log 2> $LOGS_DIR/evlist_freq_record_$frq.err
		PERF_EXIT_CODE=$?

		../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2_TOLERANT" "perf.data" < $LOGS_DIR/evlist_freq_record_$frq.err
		CHECK_EXIT_CODE=$?

		print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "sample frequency check :: record with $frq"
		(( TEST_RESULT += $? ))

		# check $frq is in evlist output
		$CMD_PERF evlist -i $CURRENT_TEST_DIR/perf.data -F > $LOGS_DIR/evlist_freq_evlist_$frq.log
		PERF_EXIT_CODE=$?

		../common/check_all_patterns_found.pl "$EVENT:\s+sample_freq=$frq" < $LOGS_DIR/evlist_freq_evlist_$frq.log
		CHECK_EXIT_CODE=$?

		print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "sample frequency check :: evlist $frq"
		(( TEST_RESULT += $? ))
	done
else
	print_testcase_skipped "sample frequency check"
fi



### TODO verbose evlisting


### evlist with various events

EVENTS_TO_TEST=`$CMD_PERF list hw | grep "Hardware event" | awk '{print $1}' | egrep '^.' | tr '\n' ' '`
if [ -n "$EVENTS_TO_TEST" ]; then
	for event in $EVENTS_TO_TEST; do
		# record event
		$CMD_PERF record -e $event -o $CURRENT_TEST_DIR/perf.data -- $CMD_SIMPLE > $LOGS_DIR/evlist_record_$event.log 2> $LOGS_DIR/evlist_record_$event.err
		PERF_EXIT_CODE=$?

		../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2_TOLERANT" "perf.data" < $LOGS_DIR/evlist_record_$event.err
		CHECK_EXIT_CODE=$?

		print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "various events :: record $event"
		(( TEST_RESULT += $? ))

		# evlist it
		$CMD_PERF evlist -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/evlist_evlist_$event.log
		PERF_EXIT_CODE=$?

		../common/check_all_patterns_found.pl "$event" < $LOGS_DIR/evlist_evlist_$event.log
		CHECK_EXIT_CODE=$?
		../common/check_all_lines_matched.pl "$event" < $LOGS_DIR/evlist_evlist_$event.log
		(( CHECK_EXIT_CODE += $? ))

		print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "various events :: evlist $event"
		(( TEST_RESULT += $? ))
	done
else
	print_testcase_skipped "various events"
fi



### TODO multiple events at once


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
