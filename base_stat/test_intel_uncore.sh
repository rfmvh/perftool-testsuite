#!/bin/bash

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
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

EVENTS_TO_TEST=`$CMD_PERF list --no-desc uncore | grep -P "^\s\sunc" | grep -v uncore_frequency | awk '{print $1}' | tr '\n' ' '`
if [ -z "$EVENTS_TO_TEST" ]; then
	if should_support_intel_uncore; then
		print_results 1 1 "uncore support not found despite being expected"
		print_overall_results 1
		exit 1
	else
		print_overall_skipped
		exit 0
	fi
fi

test -d $LOGS_DIR/intel_uncore || mkdir $LOGS_DIR/intel_uncore


# this is because we need to allow some cboxes to be unsupported
NUMBER_SUPPORTED_CBOXES=0

#### testing Intel uncore events

for event in $EVENTS_TO_TEST; do
	EVENT_NAME=`echo $event | tr '/' '_' | tr ',' '-'`
	touch $LOGS_DIR/intel_uncore/$EVENT_NAME.log
	$CMD_PERF stat -a -e $event -o $LOGS_DIR/intel_uncore/$EVENT_NAME.log -x';' -- $CMD_QUICK_SLEEP 2> $LOGS_DIR/intel_uncore/$EVENT_NAME.err
	PERF_EXIT_CODE=$?

	REGEX_LINES="$RE_NUMBER;[^;]*;$RE_EVENT_UNCORE;$RE_NUMBER;100\.00"
	../common/check_all_patterns_found.pl "$REGEX_LINES" < $LOGS_DIR/intel_uncore/$EVENT_NAME.log
	CHECK_EXIT_CODE=$?

	# allow some cboxes to be <not supported> if the first cbox is OK
	echo $EVENT_NAME | grep -q cbox
	if [ $? -eq 0 ]; then
		# cbox
		if [ $CHECK_EXIT_CODE -eq 0 ]; then
			(( NUMBER_SUPPORTED_CBOXES++ ))
			print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "event $event"
			(( TEST_RESULT += $? ))
		else
			if [ $NUMBER_SUPPORTED_CBOXES -gt 0 ]; then
				# there already has been a supported cbox --> waive this fail (SKIP)
				print_testcase_skipped "event $event"
			else
				# there has been no supported cbox yet --> FAIL
				print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "event $event"
				(( TEST_RESULT += $? ))
			fi
		fi
	else
		# other events
		print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "event $event"
		(( TEST_RESULT += $? ))
	fi
done


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
