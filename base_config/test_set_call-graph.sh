#!/bin/bash

#
#       test_set_call-graph of perf_config test
#       Author: Benjamin Salon <bsalon@redhat.com>
#
#       Description:
#
#               This test tests functionality of setting call-graph variables of perf config command.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


# save config file before tests
touch $HOME/.perfconfig
mv $HOME/.perfconfig $CURRENT_TEST_DIR/.config_before


### record and report without config

$CMD_PERF record -a -g -o $CURRENT_TEST_DIR/perf.data -- $CMD_SIMPLE 2> $LOGS_DIR/set_call-graph_record.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/set_call-graph_record.log
CHECK_EXIT_CODE=$?

$CMD_PERF report --stdio -i $CURRENT_TEST_DIR/perf.data 2> /dev/null | head -n -3 > $LOGS_DIR/set_call-graph_report_no_cfg.log 2> /dev/null
(( PERF_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "without config - setup"
(( TEST_RESULT += $? ))


### call-graph.sort-key variable

# set the variable
$CMD_PERF config --user call-graph.sort-key=address
PERF_EXIT_CODE=$?

$CMD_PERF config --user --list > $LOGS_DIR/set_call-graph_list.log
(( PERF_EXIT_CODE += $? ))

# check if the variable is set
grep -q call-graph.sort-key=address < $LOGS_DIR/set_call-graph_list.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "setting call-graph.sort-key variable"
(( TEST_RESULT += $? ))


# check if the variable changed sorting
$CMD_PERF report --stdio -i $CURRENT_TEST_DIR/perf.data 2> /dev/null | head -n -3 > $LOGS_DIR/set_call-graph_sort.log 2> /dev/null
PERF_EXIT_CODE=$?

! cmp $LOGS_DIR/set_call-graph_no_cfg.log $LOGS_DIR/set_call-graph_sort.log 2> /dev/null
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "checking call-graph.sort-key variable"
(( TEST_RESULT += $? ))


# set back to default
$CMD_PERF config --user call-graph.sort-key=function


### call-graph.threshold

PERCENTAGE=5

# set the variable
$CMD_PERF config --user call-graph.threshold=$PERCENTAGE
PERF_EXIT_CODE=$?

$CMD_PERF config --user --list > $LOGS_DIR/set_call-graph_list.log
(( PERF_EXIT_CODE += $? ))

# check if the variable is set
grep -q call-graph.threshold=5 < $LOGS_DIR/set_call-graph_list.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "setting call-graph.threshold variable"
(( TEST_RESULT += $? ))


# check if the variable changed percentage threshold
$CMD_PERF report --stdio -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/set_call-graph_threshold.log 2> /dev/null
PERF_EXIT_CODE=$?

CHECK_EXIT_CODE=`perl -ne 'BEGIN{$n=0;} {$n+=1 if (/--('$RE_NUMBER')%--'$RE_ADDRESS'/ and $1 < '$PERCENTAGE')} END{print "$n";}' < $LOGS_DIR/set_call-graph_threshold.log`

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "checking call-graph.threshold variable"
(( TEST_RESULT += $? ))


# set back to default
$CMD_PERF config --user call-graph.threshold=0.5


### call-graph.print-limit

# set the variable
$CMD_PERF config --user call-graph.print-limit=1
PERF_EXIT_CODE=$?

$CMD_PERF config --user --list > $LOGS_DIR/set_call-graph_list.log
(( PERF_EXIT_CODE += $? ))

# check if the variable is set
grep -q call-graph.print-limit=1 < $LOGS_DIR/set_call-graph_list.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "setting call-graph.print-limit variable"
(( TEST_RESULT += $? ))


$CMD_PERF report --stdio -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/set_call-graph_print-limit.log 2> /dev/null
PERF_EXIT_CODE=$?

# there should not be two events with percentage in the same depth
CHECK_EXIT_CODE=`perl -ne 'BEGIN{$n=0;$beg=0;} {$n+=1 if (/^([\s\|]+)\|?--'$RE_NUMBER'%--'$RE_EVENT_ANY'/ and $beg >= length($1)); $beg=0 if /^\s+'$RE_NUMBER'%/; $beg=length($1) if (/^([\s\|]+)\|?--'$RE_NUMBER'%--'$RE_EVENT_ANY'/ and $beg < length($1));} END{print "$n";}' < $LOGS_DIR/set_call-graph_print-limit.log`

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "checking call-graph.print-limit variable"
(( TEST_RESULT += $? ))


# restore the config file before tests
mv $CURRENT_TEST_DIR/.config_before $HOME/.perfconfig


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
