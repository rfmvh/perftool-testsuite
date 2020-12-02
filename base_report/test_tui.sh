#!/bin/bash

#
#	test_tui of perf_report test
#	Author: Benjamin Salon <bsalon@redhat.com>
#
#	Description:
#
#		This test tests TUI interface of perf report command.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

consider_skipping $RUNMODE_EXPERIMENTAL

if ! should_support_expect_script; then
	print_overall_skipped
fi


# record

$CMD_PERF record -o $CURRENT_TEST_DIR/perf.data -- $CMD_SIMPLE > $LOGS_DIR/tui_record_simple.log 2> $LOGS_DIR/tui_record_simple.err
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/tui_record_simple.err
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "record"
(( TEST_RESULT += $? ))


### tui tests

# nonexistent filter

N_SAMPLES_SIMPLE=`perl -ne 'print "$1" if /\((\d+) samples\)/' $LOGS_DIR/tui_record_simple.err`

expect tui_report_non_existent_filter.exp "$CMD_PERF" "$LOGS_DIR/perf.data" "(?:$CMD_SIMPLE|perf)" "$N_SAMPLES_SIMPLE" > $LOGS_DIR/tui_empty_search.log 2> $LOGS_DIR/tui_empty_search.err
TUI_EXIT_CODE=$?

CHECK_EXIT_CODE=$([ "$TUI_EXIT_CODE" -le 1 ] && echo "0" || echo "1")

print_results $TUI_EXIT_CODE $CHECK_EXIT_CODE "tui tests :: nonexistent filter"
(( TEST_RESULT += $? ))


# exit

expect tui_report_exit.exp "$CMD_PERF" "$LOGS_DIR/perf.data" "(?:$CMD_SIMPLE|perf)" "$N_SAMPLES_SIMPLE" > $LOGS_DIR/tui_exit.log 2> $LOGS_DIR/tui_exit.err
TUI_EXIT_CODE=$?

CHECK_EXIT_CODE=$([ "$TUI_EXIT_CODE" -le 1 ] && echo "0" || echo "1")

print_results $TUI_EXIT_CODE $CHECK_EXIT_CODE "tui tests :: exit"
(( TEST_RESULT += $? ))


# --stdio compare

$CMD_PERF report --stdio -i $LOGS_DIR/perf.data | grep "^[^#]" | sed 's/\s\s*/ /g' | sed 's/^\s//g' | sed -r 's/(\[|\])/\\\1/g' > $LOGS_DIR/tui_report_stdio.log 2> $LOGS_DIR/tui_report_stdio.err
PERF_EXIT_CODE=$?

expect tui_report_stdio_compare.exp "$CMD_PERF" "$LOGS_DIR/perf.data" "$LOGS_DIR/tui_report_stdio.log" "$N_SAMPLES_SIMPLE" > $LOGS_DIR/tui_stdio_compare.log 2> $LOGS_DIR/tui_stdio_compare.err
TUI_EXIT_CODE=$?

CHECK_EXIT_CODE=$([ "$TUI_EXIT_CODE" -le 1 ] && echo "0" || echo "1")

print_results $TUI_EXIT_CODE $CHECK_EXIT_CODE "tui tests :: --stdio compare"
(( TEST_RESULT += $? ))


# help

expect tui_report_help.exp "$CMD_PERF" "$LOGS_DIR/perf.data" "(?:$CMD_SIMPLE|perf)" "$N_SAMPLES_SIMPLE" > $LOGS_DIR/tui_help.log 2> $LOGS_DIR/tui_help.err
TUI_EXIT_CODE=$?

CHECK_EXIT_CODE=$([ "$TUI_EXIT_CODE" -le 1 ] && echo "0" || echo "1")

print_results $TUI_EXIT_CODE $CHECK_EXIT_CODE "tui tests :: help"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results $TEST_RESULT
exit $?
