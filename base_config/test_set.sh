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


# save config file before tests
touch $HOME/.perfconfig
mv $HOME/.perfconfig $CURRENT_TEST_DIR/.config_before


### set all variables to default value

for VAR in `cat $LOGS_DIR/config_all_variables.log 2> /dev/null`; do
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
