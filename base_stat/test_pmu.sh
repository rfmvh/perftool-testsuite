#!/bin/bash

#
#	test_pmu of perf_stat test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#	    This test tests hardware events marked as "PMU" by perf stat.
#	These events depend highly on particular CPU used, while the "hw"
#	events are a subset of them with some level of abstraction.
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

if [ ! "$PARAM_STAT_ALL_PMU_EVENTS" == "y" ]; then
	print_overall_skipped
	exit 0
fi

EVENTS_TO_TEST=`$CMD_PERF list --no-desc pmu | grep "Kernel PMU event" | grep -v -e offcore -e msr | awk '{print $1}' | egrep '^.' | tr '\n' ' '`
if [ -z "$EVENTS_TO_TEST" ]; then
	if [ "$TEST_IGNORE_MISSING_PMU" = "y" ]; then
		print_overall_skipped
		exit 0
	else
		if should_support_pmu; then
			print_results 1 1 "PMU support not found despite being expected (no pmu events)"
			print_overall_results 1
			exit $?
		else
			print_overall_skipped
			exit 0
		fi
	fi
fi

# FIXME test -e pmu.log && rm -f pmu.log

test -d $LOGS_DIR/pmu || mkdir $LOGS_DIR/pmu

# free the potentially seized counter
disable_nmi_watchdog_if_exists


#### testing hardware events

for event in $EVENTS_TO_TEST; do
	logfile=`echo $event | tr '/' '_'`
	$CMD_PERF stat -a -e $event -o $LOGS_DIR/pmu/$logfile.log --append -x';' -- $CMD_BASIC_SLEEP 2> /dev/null
	PERF_EXIT_CODE=$?
	REGEX_LINES="$RE_NUMBER;[\w;]+$event;$RE_NUMBER;100\.00"
	../common/check_all_patterns_found.pl "$REGEX_LINES" < $LOGS_DIR/pmu/$logfile.log
	CHECK_EXIT_CODE=$?
	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "event $event"
	(( TEST_RESULT += $? ))
done

restore_nmi_watchdog_if_needed

# print overall results
print_overall_results "$TEST_RESULT"
exit $?

# FIXME we should test the numbers
