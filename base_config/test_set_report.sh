#!/bin/bash

#
#       test_set_report of perf_config test
#       Author: Benjamin Salon <bsalon@redhat.com>
#
#       Description:
#
#               This test tests functionality of setting report variables of perf config command.
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

$CMD_PERF record -a -o $CURRENT_TEST_DIR/perf.data -- $CMD_SIMPLE 2> $LOGS_DIR/set_report_record.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/set_report_record.log
CHECK_EXIT_CODE=$?

$CMD_PERF report --stdio -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/set_report_report_no_cfg.log 2> $LOGS_DIR/set_report_report_no_cfg.err
(( PERF_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "general setup"
(( TEST_RESULT += $? ))


### report.sort_order variable

grep -q report.sort_order $LOGS_DIR/config_all_variables.log &> /dev/null
if [ $? -eq 0 ]; then
	# set the variable
	$CMD_PERF config --user report.sort_order=sym,dso
	PERF_EXIT_CODE=$?

	$CMD_PERF config --user --list > $LOGS_DIR/set_report_list.log 2> $LOGS_DIR/set_report_list.err
	(( PERF_EXIT_CODE += $? ))

	# check if the variable is set
	grep -q report.sort_order=sym,dso < $LOGS_DIR/set_report_list.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "setting report.sort_order variable"
	(( TEST_RESULT += $? ))


	# check if the variable changed sorting
	$CMD_PERF report --stdio -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/set_report_sort.log 2> $LOGS_DIR/set_report_sort.err
	PERF_EXIT_CODE=$?

	! cmp $LOGS_DIR/set_report_no_cfg.log $LOGS_DIR/set_report_sort.log 2> /dev/null
	CHECK_EXIT_CODE=$?

	REGEX_COMMENT_LINE="^#.*$"
	REGEX_DATA_LINE="\s*$RE_NUMBER%\s*\[[kH\.]\]\s*[\w\.]+\s*[\[\]\.\w]+"

	# only data line is important for us
	../common/check_all_lines_matched.pl "^\s*$" "$REGEX_COMMENT_LINE" "$REGEX_DATA_LINE" < $LOGS_DIR/set_report_sort.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "checking report.sort_order variable"
	(( TEST_RESULT += $? ))


	# set back to default
	$CMD_PERF config --user report.sort_order=comm,dso,symbol
else
	# variable is unsupported
	print_testcase_skipped "report.sort_order variable is unsupported"
fi


### report.percent-limit variable

PERCENTAGE=10

grep -q report.percent-limit $LOGS_DIR/config_all_variables.log &> /dev/null
if [ $? -eq 0 ]; then
	# set the variable
	$CMD_PERF config --user report.percent-limit=$PERCENTAGE
	PERF_EXIT_CODE=$?

	$CMD_PERF config --user --list > $LOGS_DIR/set_report_list.log 2> $LOGS_DIR/set_report_list.err
	(( PERF_EXIT_CODE += $? ))

	# check if the variable is set
	grep -q report.percent-limit=$PERCENTAGE < $LOGS_DIR/set_report_list.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "setting report.percent-limit variable"
	(( TEST_RESULT += $? ))


	# check if the variable changed percentage limit
	$CMD_PERF report --stdio -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/set_report_limit.log 2> $LOGS_DIR/set_report_limit.err
	PERF_EXIT_CODE=$?

	CHECK_EXIT_CODE=`perl -ne 'BEGIN{$n=0;} {$n+=1 if (/^\s*('$RE_NUMBER')%\s*\w+\s*/ and $1 < '$PERCENTAGE');} END{print "$n";}' < $LOGS_DIR/set_report_limit.log`

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "checking report.percent-limit variable"
	(( TEST_RESULT += $? ))


	# set back to default
	$CMD_PERF config --user report.percent-limit=0
else
	# variable is unsupported
	print_testcase_skipped "report.percent-limit variable is unsupported"
fi


### report.children variable

# record and report with call-graph option

$CMD_PERF record -a -g -o $CURRENT_TEST_DIR/perf.data -- $CMD_SIMPLE 2> $LOGS_DIR/set_report_record_cg.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/set_report_record_cg.log
CHECK_EXIT_CODE=$?

$CMD_PERF report --stdio -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/set_report_report_no_cfg_cg.log 2> $LOGS_DIR/set_report_report_no_cfg_cg.err
(( PERF_EXIT_CODE += $? ))

CHILDREN_PERCENTAGE=`perl -ne 'BEGIN{$n=0;} {$n+=$1 if /^\s*('$RE_NUMBER')%\s*'$RE_NUMBER'%\s*/;} END{print "$n";}' < $LOGS_DIR/set_report_report_no_cfg_cg.log`

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "setup for report.children variable"
(( TEST_RESULT += $? ))


grep -q report.children $LOGS_DIR/config_all_variables.log &> /dev/null
if [ $? -eq 0 ]; then
	# set the variable
	$CMD_PERF config --user report.children=false
	PERF_EXIT_CODE=$?

	$CMD_PERF config --user --list > $LOGS_DIR/set_report_list.log 2> $LOGS_DIR/set_report_list.err
	(( PREF_EXIT_CODE += $? ))

	# check if the variable is set
	grep -q report.children=false < $LOGS_DIR/set_report_list.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "setting report.children variable"
	(( TEST_RESULT += $? ))


	# check if there are no children percentages
	$CMD_PERF report --stdio -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/set_report_children.log 2> $LOGS_DIR/set_report_children.err
	PERF_EXIT_CODE=$?

	OVERHEAD_PERCENTAGE=`perl -ne 'BEGIN{$n=0;} {$n+=$1 if /^\s*('$RE_NUMBER')%\s*/;} END{print "$n";}' < $LOGS_DIR/set_report_children.log`

	CHECK_EXIT_CODE=`echo "$CHILDREN_PERCENTAGE < $OVERHEAD_PERCENTAGE" | bc`

	PRECISION=0.1
	ZERO=`echo $OVERHEAD_PERCENTAGE - 100 | bc | tr -d - | awk '{print $0" > '$PRECISION'"}' | bc`

	(( CHECK_EXIT_CODE += $ZERO ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "checking report.children variable"
	(( TEST_RESULT += $? ))
else
	# variable is unsupported
	print_testcase_skipped "report.children variable is unsupported"
fi


# restore the config file
mv $CURRENT_TEST_DIR/.config_before $HOME/.perfconfig


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
