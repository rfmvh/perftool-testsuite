#!/bin/bash

#
#	setup.sh of perf config test
#	Author: Benjamin Salon <bsalon@redhat.com>
#
#	Description:
#
#		Create a file with all supported config variables
#
#


# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`

$CMD_PERF config --help 2> /dev/null | sed '1,/Variables/d' > $LOGS_DIR/config_man_variables.log
TEST_RESULT=$?

SPACES=`head -n 1 $LOGS_DIR/config_man_variables.log | grep -o ^[[:space:]]* 2> /dev/null`
(( TEST_RESULT += $? ))

grep "^$SPACES\w" $LOGS_DIR/config_man_variables.log | tr -d ' ' | tr ',' '\n' | grep "\w\.\w" > $LOGS_DIR/config_all_variables.log
(( TEST_RESULT += $? ))

print_overall_results $TEST_RESULT
exit $?
