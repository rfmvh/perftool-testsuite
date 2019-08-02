#!/bin/bash

#
#	test_metrics of perf_stat test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#	    This test tests hardware event combinations, that are used in so-
#	called "metrics". For example, a metric "cpi" (cycles-per-instruction)
#	can be obtained by counting cycles and instructions at the same time
#	and calculating the ratio.
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

if [ ! "$PARAM_STAT_TEST_METRICS" == "y" ]; then
	print_overall_skipped
	exit 0
fi

METRICS_TO_TEST=`$CMD_PERF list metrics | grep -P '^  \w' | awk '{print $1}' | egrep '^.' | tr '\n' ' '`
if [ -z "$METRICS_TO_TEST" ]; then
	print_overall_skipped
	exit 0
fi

# FIXME test -e metric.log && rm -f metric.log

test -d $LOGS_DIR/metric || mkdir $LOGS_DIR/metric

# free the potentially seized counter
disable_nmi_watchdog_if_exists


#### testing hardware event metrics

for metric in $METRICS_TO_TEST; do
	logfile=`echo $metric | tr '/' '_'`
	$CMD_PERF stat -M $metric -o $LOGS_DIR/metric/$logfile.log --append -x';' -- $CMD_BASIC_SLEEP 2> /dev/null
	PERF_EXIT_CODE=$?
	REGEX_METRIC_LINE="$RE_NUMBER;.+;$RE_NUMBER;$metric"
	../common/check_all_patterns_found.pl "$REGEX_METRIC_LINE" < $LOGS_DIR/metric/$logfile.log
	CHECK_EXIT_CODE=$?
	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "metric $metric"
	(( TEST_RESULT += $? ))
done

restore_nmi_watchdog_if_needed

# print overall results
print_overall_results "$TEST_RESULT"
exit $?

# FIXME we should test the numbers
