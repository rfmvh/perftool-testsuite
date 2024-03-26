#!/bin/bash

#
#	test_perf_cpu_time_max_percent of other perf_tests
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests if perf_event_perf_cpu_time_max_percent can
#	be set to values 0-100 only.
#
#

# include working environment
. ../common/init.sh

TEST_RESULT=0

VARIABLE="/proc/sys/kernel/perf_cpu_time_max_percent"
VARIABLE_BACKUP=`cat $VARIABLE`


### correct values

VALUES="0 1 10 25 51 99 100"
EXP_RESULT=0  # PASS
for val in $VALUES; do
	echo $val > $VARIABLE 2> $LOGS_DIR/perf_cpu_time_max_percent_$val.err
	# shellcheck disable=SC2320 # the '$?' refers to the echo command on purpose
	test $? -eq $EXP_RESULT
	WRITE_EXIT_CODE=$?

	test "`cat $VARIABLE`" -eq $val
	VERIFICATION_EXIT_CODE=$?

	print_results $WRITE_EXIT_CODE $VERIFICATION_EXIT_CODE "correct values: $val"
	(( TEST_RESULT += $? ))
done


### incorrect values

VALUES="-1 101 255 256 1025"
EXP_RESULT=1  # FAIL
for val in $VALUES; do
	echo $val > $VARIABLE 2> $LOGS_DIR/perf_cpu_time_max_percent_$val.err
	# shellcheck disable=SC2320 # the '$?' refers to the echo command on purpose
	test $? -eq $EXP_RESULT
	WRITE_EXIT_CODE=$?

	../common/check_all_lines_matched.pl "write error: Invalid argument" < $LOGS_DIR/perf_cpu_time_max_percent_$val.err
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "write error: Invalid argument" < $LOGS_DIR/perf_cpu_time_max_percent_$val.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $WRITE_EXIT_CODE $CHECK_EXIT_CODE "incorrect values: $val"
	(( TEST_RESULT += $? ))
done


# restore original value
echo $VARIABLE_BACKUP > $VARIABLE


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
