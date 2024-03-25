#!/bin/bash

#
#	test_basic of perf_top test
#	Author: Benjamin Salon <bsalon@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf top command.
#
#

# include working environment
. ../common/init.sh

TEST_RESULT=0


### help message

if [ "$PARAM_GENERAL_HELP_TEXT_CHECK" = "y" ]; then
	# test that a help message is shown and looks reasonable
	$CMD_PERF top --help > $LOGS_DIR/basic_helpmsg.log
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "PERF-TOP" "NAME" "SYNOPSIS" "DESCRIPTION" "OPTIONS" "INTERACTIVE PROMPTING KEYS" "OVERHEAD CALCULATION" "SEE ALSO" < $LOGS_DIR/basic_helpmsg.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "all-cpus" "cpu" "delay" "event" "group" "group-sort-idx" "freq" "pid" "uid" "hide_kernel_symbols" "hide_user_symbols" "sort" "fields" < $LOGS_DIR/basic_helpmsg.log
	../common/check_all_patterns_found.pl "show-nr-samples" "show-total-period" "dsos" "comms" "symbols" "-g" "ignore-callees" "percent-limit" "percentage" "hierarchy" "switch-on" "switch-off" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "help message"
fi


consider_skipping $RUNMODE_EXPERIMENTAL

if ! should_support_expect_script; then
        print_overall_skipped
        exit 0
fi


##### tui output

### basic execution

# exit

expect tui_basic_exit.exp "$CMD_PERF" "" > $LOGS_DIR/basic_basic_exit.log 2> $LOGS_DIR/basic_basic_exit.err
PERF_EXIT_CODE=$?

CHECK_EXIT_CODE=$([ "$PERF_EXIT_CODE" -le 1 ] && echo "0" || echo "1")

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "tui output :: basic execution :: exit"
(( TEST_RESULT += $? ))


# help

expect tui_basic_help.exp "$CMD_PERF" "" > $LOGS_DIR/basic_basic_help.log 2> $LOGS_DIR/basic_basic_help.err
PERF_EXIT_CODE=$?

CHECK_EXIT_CODE=$([ "$PERF_EXIT_CODE" -le 1 ] && echo "0" || echo "1")

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "tui output :: basic execution :: help"
(( TEST_RESULT += $? ))


# nonexistent filter

expect tui_basic_non_existent_filter.exp "$CMD_PERF" "" > $LOGS_DIR/basic_basic_empty_search.log 2> $LOGS_DIR/basic_basic_empty_search.err
PERF_EXIT_CODE=$?

CHECK_EXIT_CODE=$([ "$PERF_EXIT_CODE" -le 1 ] && echo "0" || echo "1")

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "tui output :: basic execution :: nonexistent filter"
(( TEST_RESULT += $? ))


### selecting CPU with max frequency

# exit

expect tui_basic_exit.exp "$CMD_PERF" "-C1 -Fmax" > $LOGS_DIR/basic_cpu_exit.log 2> $LOGS_DIR/basic_cpu_exit.err
PERF_EXIT_CODE=$?

CHECK_EXIT_CODE=$([ "$PERF_EXIT_CODE" -le 1 ] && echo "0" || echo "1")

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "tui output :: selecting cpu :: exit"
(( TEST_RESULT += $? ))


# help

expect tui_basic_help.exp "$CMD_PERF" "-C1 -Fmax" > $LOGS_DIR/basic_cpu_help.log 2> $LOGS_DIR/basic_cpu_help.err
PERF_EXIT_CODE=$?

CHECK_EXIT_CODE=$([ "$PERF_EXIT_CODE" -le 1 ] && echo "0" || echo "1")

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "tui output :: selecting cpu :: help"
(( TEST_RESULT += $? ))


# nonexistent filter

expect tui_basic_non_existent_filter.exp "$CMD_PERF" "-C1 -Fmax" > $LOGS_DIR/basic_cpu_empty_search.log 2> $LOGS_DIR/basic_cpu_empty_search.err
PERF_EXIT_CODE=$?

CHECK_EXIT_CODE=$([ "$PERF_EXIT_CODE" -le 1 ] && echo "0" || echo "1")

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "tui output :: selecting cpu :: nonexistent filter"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
