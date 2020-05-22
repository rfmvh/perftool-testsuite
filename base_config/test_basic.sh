#!/bin/bash

#
#	test_basic of perf_config test
#	Author: Benjamin Salon <bsalon@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf config command.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


### help message

if [ "$PARAM_GENERAL_HELP_TEXT_CHECK" = "y" ]; then
	# test that a help message is shown and looks reasonable
	$CMD_PERF config --help > $LOGS_DIR/basic_helpmsg.log 2> /dev/null
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "PERF-CONFIG" "NAME" "SYNOPSIS" "DESCRIPTION" "OPTIONS" "CONFIGURATION FILE" "SEE ALSO" < $LOGS_DIR/basic_helpmsg.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "--list" "--user" "--system" "Variables" "config" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "help message"
fi


### --list option

$CMD_PERF config --list > $LOGS_DIR/basic_list.log 2> /dev/null
PERF_EXIT_CODE=$?

if [ -s $LOGS_DIR/basic_list.log ]; then
	# test that config looks reasonable
	REGEX_CONFIG_LINE="\w+\.\w+\s*=\s*\w+"

	../common/check_all_lines_matched.pl "^\s*$" "$REGEX_CONFIG_LINE" < $LOGS_DIR/basic_list.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "$REGEX_CONFIG_LINE" < $LOGS_DIR/basic_list.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "--list option"
	(( TEST_RESULT += $? ))
else
	# there is no config
	print_testcase_skipped "--list option :: no config"
fi


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
