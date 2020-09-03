#!/bin/bash

#
#	test_basic of perf_timechart test
#	Author: Benjamin Salon <bsalon@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf timechart command.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

consider_skipping $RUNMODE_EXPERIMENTAL

# record some data

$CMD_PERF timechart record -- -o $CURRENT_TEST_DIR/perf.data -- $CMD_BASIC_SLEEP 2> $LOGS_DIR/highlight_record.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/highlight_record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "timechart record"
(( TEST_RESULT += $? ))


# timechart with highlight=$HIGHLIGHT

HIGHLIGHT=50000
$CMD_PERF timechart --highlight=$HIGHLIGHT -i $CURRENT_TEST_DIR/perf.data -o $LOGS_DIR/highlight_timechart.svg 2> $LOGS_DIR/highlight_timechart.log
PERF_EXIT_CODE=$?

REGEX_TIMEHIST_LINE="Written $RE_NUMBER seconds of trace to $LOGS_DIR/highlight_timechart\.svg\."

../common/check_all_patterns_found.pl "$REGEX_TIMEHIST_LINE" < $LOGS_DIR/highlight_timechart.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "timechart with highlight=$HIGHLIGHT"
(( TEST_RESULT += $? ))


# timechart with highlight :: highlight check

TITLE_LINE="<title>.*running\s*($RE_NUMBER)\s*us<\/title>"
RECT_LINE="<rect\s*x=\"$RE_NUMBER\"\s*width=\"$RE_NUMBER\"\s*y=\"$RE_NUMBER\"\s*height=\"$RE_NUMBER\"\s*class=\"(\w+)\"\/>"

# checking if the highlight option set highlight class
CHECK_EXIT_CODE=`perl -ne 'BEGIN{$n=0; $us=0; $class=""} {$n += 1 if ($class eq "sample" and $us > '$HIGHLIGHT'); $us = $1 if /^'$TITLE_LINE'$/; $class = "$1" if /^'$RECT_LINE'$/} END{print "$n";}' < $LOGS_DIR/highlight_timechart.svg`

print_results 0 $CHECK_EXIT_CODE "timechart with highlight=$HIGHLIGHT :: highlight check"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
