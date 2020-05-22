#!/bin/bash

#
#       test_set of perf_config test
#       Author: Benjamin Salon <bsalon@redhat.com>
#
#       Description:
#
#               This test tests functionality of setting a variable of perf config command.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


### get all variable names

$CMD_PERF config --help > $LOGS_DIR/set_help.log 2> /dev/null
PERF_EXIT_CODE=$?

sed '1,/Variables/d' < $LOGS_DIR/set_help.log > $LOGS_DIR/set_help_variables.log 2> /dev/null
CHECK_EXIT_CODE=$?

BEGIN_SPACE=`grep "colors\.\*" < $LOGS_DIR/set_help_variables.log | grep -o [[:space:]]* 2> /dev/null`

grep "^$BEGIN_SPACE\w" < $LOGS_DIR/set_help_variables.log | tr -d ' ' | tr ',' '\n' | grep "\.\w" > $LOGS_DIR/set_all.log 2> /dev/null
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "getting all variable names"
(( TEST_RESULT += $? ))


# save config file before tests
touch $HOME/.perfconfig
mv $HOME/.perfconfig $CURRENT_TEST_DIR/.config_before


### set all variables to default value

for VAR in `cat $LOGS_DIR/set_all.log`; do
	VARSET=`grep $VAR < $CURRENT_TEST_DIR/no_default.txt 2> /dev/null`
	if [ $? -ne 0 ]; then
		VARSET="$VAR=default"
	fi

	# set the variable
	$CMD_PERF config --user $VARSET
	PERF_EXIT_CODE=$?

	$CMD_PERF config --user --list > $LOGS_DIR/set_all_set.log
	(( PERF_EXIT_CODE += $? ))

	# check if the variable is set
	grep -q $VARSET < $LOGS_DIR/set_all_set.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "setting $VAR variable"
	(( TEST_RESULT += $? ))
done


# restore the config file
mv $CURRENT_TEST_DIR/.config_before $HOME/.perfconfig


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
