#!/bin/bash

#
#       test_set_trace of perf_config test
#       Author: Benjamin Salon <bsalon@redhat.com>
#
#       Description:
#
#               This test tests functionality of setting trace variables of perf config command.
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


### regexes

REGEX_CONTINUED="\.{3}\s*\[continued\]:\s+\w+\(\)\)"
REGEX_DURATION="\(\s*$RE_NUMBER\s*ms\)"
REGEX_EMPTY_DURATION="\(\s+\)"
REGEX_COMMAND="ls\/\d+"
REGEX_ARG="[\w\|\/\.<>-]+"
REGEX_FUNCTION_ARGS="\w+\((?:\w+:\s+$REGEX_ARG, )*(?:\w+:\s+$REGEX_ARG\s*)?\)"
REGEX_FUNCTION_NO_ARGS="\w+\((?:$REGEX_ARG, )*(?:$REGEX_ARG\s*)?\)"
REGEX_RESULT="(?:(?:0x$RE_NUMBER_HEX)|(?:\-?$RE_NUMBER))"


### trace.args_alignment variable

ALIGNMENT=150

grep -q trace.args_alignment $LOGS_DIR/config_all_variables.log &> /dev/null
if [ $? -eq 0 ]; then
	# set the variable
	$CMD_PERF config --user trace.args_alignment=$ALIGNMENT
	PERF_EXIT_CODE=$?

	$CMD_PERF config --user --list > $LOGS_DIR/set_trace_alignment_list.log 2> $LOGS_DIR/set_trace_alignment_list.err
	(( PERF_EXIT_CODE += $? ))

	# check if the variable is set
	grep -q trace.args_alignment=$ALIGNMENT < $LOGS_DIR/set_trace_alignment_list.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "setting trace.args_alignment variable"
	(( TEST_RESULT += $? ))


	# check if the variable changed the alignment
	$CMD_PERF trace ls > /dev/null 2> $LOGS_DIR/set_trace_alignment.log
	PERF_EXIT_CODE=$?

	CHECK_EXIT_CODE=`awk '{print length}' < $LOGS_DIR/set_trace_alignment.log | perl -ne 'BEGIN{$n=0;} {$n+=1 if ($_ < '$ALIGNMENT')} END{print "$n";}'`

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "checking trace.args_alignment variable - alignment"
	(( TEST_RESULT += $? ))

	REGEX_ALIGN_CONTINUED_LINE="\s*(?:\?|$RE_NUMBER)\s*$REGEX_EMPTY_DURATION:\s*$REGEX_COMMAND\s*$REGEX_CONTINUED\s*=\s*$REGEX_RESULT"
	REGEX_ALIGN_DATA_LINE="\s*$RE_NUMBER\s*$REGEX_DURATION:\s*$REGEX_COMMAND\s*$REGEX_FUNCTION_ARGS\s*=\s*$REGEX_RESULT"
	REGEX_ALIGN_EXIT_LINE="\s*$RE_NUMBER\s*$REGEX_EMPTY_DURATION:\s*$REGEX_COMMAND\s*exit_group\(\s*\)(?:\s*=\s*\?)?"

	../common/check_all_lines_matched.pl "$REGEX_ALIGN_CONTINUED_LINE" "$REGEX_ALIGN_DATA_LINE" "$REGEX_ALIGN_EXIT_LINE" "^\s*$" < $LOGS_DIR/set_trace_alignment.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "$REGEX_ALIGN_DATA_LINE" "$REGEX_ALIGN_EXIT_LINE" < $LOGS_DIR/set_trace_alignment.log
	(( CHECK_EXIT_CODE += $? ))

	print_results 0 $CHECK_EXIT_CODE "checking trace.args_alignment variable - output"
	(( TEST_RESULT += $? ))


	# set back to default
	$CMD_PERF config --user trace.args_alignment=70
else
	# variable is unsupported
	print_testcase_skipped "trace.args_alignment variable is unsupported"
fi


### trace.no_inherit variable

grep -q trace.no_inherit $LOGS_DIR/config_all_variables.log &> /dev/null
if [ $? -eq 0 ]; then
	# set the variable
	$CMD_PERF config --user trace.no_inherit=true
	PERF_EXIT_CODE=$?

	$CMD_PERF config --user --list > $LOGS_DIR/set_trace_inherit_list.log 2> $LOGS_DIR/set_trace_inherit_list.err
	(( PERF_EXIT_CODE += $? ))

	# check if the variable is set
	grep -q trace.no_inherit=true < $LOGS_DIR/set_trace_inherit_list.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "setting trace.no_inherit variable"
	(( TEST_RESULT += $? ))


	# check if perf trace shows the comm/pid field
	$CMD_PERF trace ls > /dev/null 2> $LOGS_DIR/set_trace_inherit.log
	PERF_EXIT_CODE=$?

	REGEX_INHERIT_CONTINUED_LINE="\s*(?:\?|$RE_NUMBER)\s*$REGEX_EMPTY_DURATION:\s*$REGEX_CONTINUED\s*=\s*$REGEX_RESULT"
	REGEX_INHERIT_DATA_LINE="\s*$RE_NUMBER\s*$REGEX_DURATION:\s*$REGEX_FUNCTION_ARGS\s*=\s*$REGEX_RESULT"
	REGEX_INHERIT_EXIT_LINE="\s*$RE_NUMBER\s*$REGEX_EMPTY_DURATION:\s*exit_group\(\s*\)(?:\s*=\s*\?)?"

	../common/check_all_lines_matched.pl "$REGEX_INHERIT_CONTINUED_LINE" "$REGEX_INHERIT_DATA_LINE" "$REGEX_INHERIT_EXIT_LINE" "^\s*$" < $LOGS_DIR/set_trace_inherit.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "$REGEX_INHERIT_DATA_LINE" "$REGEX_INHERIT_EXIT_LINE" < $LOGS_DIR/set_trace_inherit.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "checking trace.no_inherit variable"
	(( TEST_RESULT += $? ))


	# set back to default
	$CMD_PERF config --user trace.no_inherit=false
else
	# variable is unsupported
	print_testcase_skipped "trace.no_inherit variable is unsupported"
fi


### trace.show_arg_names variable

grep -q trace.show_arg_names $LOGS_DIR/config_all_variables.log &> /dev/null
if [ $? -eq 0 ]; then
	# set the variable
	$CMD_PERF config --user trace.show_arg_names=false
	PERF_EXIT_CODE=$?

	$CMD_PERF config --user --list > $LOGS_DIR/set_trace_arg_names_list.log 2> $LOGS_DIR/set_trace_arg_names_list.err
	(( PERF_EXIT_CODE += $? ))

	# check if the variable is set
	grep -q trace.show_arg_names=false < $LOGS_DIR/set_trace_arg_names_list.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "setting trace.show_arg_names variable"
	(( TEST_RESULT += $? ))


	# check if perf trace shows function arguments
	$CMD_PERF trace ls > /dev/null 2> $LOGS_DIR/set_trace_arg_names.log
	PERF_EXIT_CODE=$?

	REGEX_ARG_NAMES_CONTINUED_LINE="\s*(?:\?|$RE_NUMBER)\s*$REGEX_EMPTY_DURATION:\s*$REGEX_COMMAND\s*$REGEX_CONTINUED\s*=\s*$REGEX_RESULT"
	REGEX_ARG_NAMES_DATA_LINE="\s*$RE_NUMBER\s*$REGEX_DURATION:\s*$REGEX_COMMAND\s*$REGEX_FUNCTION_NO_ARGS\s*=\s*$REGEX_RESULT"
	REGEX_ARG_NAMES_EXIT_LINE="\s*$RE_NUMBER\s*$REGEX_EMPTY_DURATION:\s*$REGEX_COMMAND\s*exit_group\((?:0|\s*)?\)(?:\s*=\s*\?)?"

	../common/check_all_lines_matched.pl "$REGEX_ARG_NAMES_CONTINUED_LINE" "$REGEX_ARG_NAMES_DATA_LINE" "$REGEX_ARG_NAMES_EXIT_LINE" "^\s*$" < $LOGS_DIR/set_trace_arg_names.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "$REGEX_ARG_NAMES_DATA_LINE" "$REGEX_ARG_NAMES_EXIT_LINE" < $LOGS_DIR/set_trace_arg_names.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "checking trace.show_arg_names variable"
	(( TEST_RESULT += $? ))


	# set back to default
	$CMD_PERF config --user trace.show_arg_names=true
else
	# variable is unsupported
	print_testcase_skipped "trace.show_arg_names variable is unsupported"
fi


### trace.show_duration variable

grep -q trace.show_duration $LOGS_DIR/config_all_variables.log &> /dev/null
if [ $? -eq 0 ]; then
	# set the variable
	$CMD_PERF config --user trace.show_duration=false
	PERF_EXIT_CODE=$?

	$CMD_PERF config --user --list > $LOGS_DIR/set_trace_duration_list.log 2> $LOGS_DIR/set_trace_duration_list.err
	(( PERF_EXIT_CODE += $? ))

	# check if the variable is set
	grep -q trace.show_duration=false < $LOGS_DIR/set_trace_duration_list.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "setting trace.show_duration variable"
	(( TEST_RESULT += $? ))


	# check if perf trace shows duration field
	$CMD_PERF trace ls > /dev/null 2> $LOGS_DIR/set_trace_duration.log
	PERF_EXIT_CODE=$?

	REGEX_DURATION_CONTINUED_LINE="\s*(?:\?|$RE_NUMBER)\s*$REGEX_COMMAND\s*$REGEX_CONTINUED\s*=\s*$REGEX_RESULT"
	REGEX_DURATION_DATA_LINE="\s*$RE_NUMBER\s*$REGEX_COMMAND\s*$REGEX_FUNCTION_ARGS\s*=\s*$REGEX_RESULT"
	REGEX_DURATION_EXIT_LINE="\s*$RE_NUMBER\s*$REGEX_COMMAND\s*exit_group\(\s*\)(?:\s*=\s*\?)?"

	../common/check_all_lines_matched.pl "$REGEX_DURATION_CONTINUED_LINE" "$REGEX_DURATION_DATA_LINE" "$REGEX_DURATION_EXIT_LINE" "^\s*$" < $LOGS_DIR/set_trace_duration.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "$REGEX_DURATION_DATA_LINE" "$REGEX_DURATION_EXIT_LINE" < $LOGS_DIR/set_trace_duration.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "checking trace.show_duration variable"
	(( TEST_RESULT += $? ))


	# set back to default
	$CMD_PERF config --user trace.show_duration=true
else
	# variable is unsupported
	print_testcase_skipped "trace.show_duration variable is unsupported"
fi


### trace.show_timestamp variable

grep -q trace.show_timestamp $LOGS_DIR/config_all_variables.log &> /dev/null
if [ $? -eq 0 ]; then
	# set the variable
	$CMD_PERF config --user trace.show_timestamp=false
	PERF_EXIT_CODE=$?

	$CMD_PERF config --user --list > $LOGS_DIR/set_trace_timestamp_list.log 2> $LOGS_DIR/set_trace_timestamp_list.err
	(( PERF_EXIT_CODE += $? ))

	# check if the variable is set
	grep -q trace.show_timestamp=false < $LOGS_DIR/set_trace_timestamp_list.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "setting trace.show_timestamp variable"
	(( TEST_RESULT += $? ))


	# check if perf trace shows timestamp field
	$CMD_PERF trace ls > /dev/null 2> $LOGS_DIR/set_trace_timestamp.log
	PERF_EXIT_CODE=$?

	REGEX_TIMESTAMP_CONTINUED_LINE="\s*$REGEX_EMPTY_DURATION:\s*$REGEX_COMMAND\s*$REGEX_CONTINUED\s*=\s*$REGEX_RESULT"
	REGEX_TIMESTAMP_DATA_LINE="\s*$REGEX_DURATION:\s*$REGEX_COMMAND\s*$REGEX_FUNCTION_ARGS\s*=\s*$REGEX_RESULT"
	REGEX_TIMESTAMP_EXIT_LINE="\s*$REGEX_EMPTY_DURATION:\s*$REGEX_COMMAND\s*exit_group\(\s*\)(?:\s*=\s*\?)?"

	../common/check_all_lines_matched.pl "$REGEX_TIMESTAMP_CONTINUED_LINE" "$REGEX_TIMESTAMP_DATA_LINE" "$REGEX_TIMESTAMP_EXIT_LINE" "^\s*$" < $LOGS_DIR/set_trace_timestamp.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "$REGEX_TIMESTAMP_DATA_LINE" "$REGEX_TIMESTAMP_EXIT_LINE" < $LOGS_DIR/set_trace_timestamp.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "checking trace.show_timestamp variable"
	(( TEST_RESULT += $? ))
else
	# variable is unsupported
	print_testcase_skipped "trace.show_timestamp variable is unsupported"
fi


# restore the config file
mv $CURRENT_TEST_DIR/.config_before $HOME/.perfconfig


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
