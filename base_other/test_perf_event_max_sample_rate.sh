#!/bin/bash

#
#	test_perf_event_max_sample_rate of other perf_tests
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests perf_event_max_sample_rate setting if perf_cpu_time_max_percent
#	disables changing of it.
#
#

# include working environment
. ../common/init.sh

TEST_RESULT=0

MAX_PERCENT="/proc/sys/kernel/perf_cpu_time_max_percent"
MAX_PERCENT_BACKUP=`cat $MAX_PERCENT`
MAX_PERCENT_SANE_VALUE=25

MAX_SAMPLE_RATE="/proc/sys/kernel/perf_event_max_sample_rate"
MAX_SAMPLE_RATE_BACKUP=`cat $MAX_SAMPLE_RATE`


### changing enabled

echo $MAX_PERCENT_SANE_VALUE > $MAX_PERCENT
VALUES="28000 $MAX_SAMPLE_RATE_BACKUP"
EXP_RESULT=0  # PASS
for val in $VALUES; do
	echo $val > $MAX_SAMPLE_RATE 2> $LOGS_DIR/perf_event_max_sample_rate_$MAX_PERCENT_SANE_VALUE.err
	# shellcheck disable=SC2320 # the '$?' refers to the echo command on purpose
	test $? -eq $EXP_RESULT
	WRITE_EXIT_CODE=$?

	test "`cat $MAX_SAMPLE_RATE`" -eq $val
	CHECK_EXIT_CODE=$?

	print_results $WRITE_EXIT_CODE $CHECK_EXIT_CODE "changes enabled (perf_cpu_time_max_percent = $MAX_PERCENT_SANE_VALUE): $val"
	(( TEST_RESULT += $? ))
done


### changing disabled

EXP_RESULT=1
SOME_VALUE=$(( MAX_SAMPLE_RATE_BACKUP / 2 ))
for val in 0 100; do
	# set MAX_PERCENT to a value that prevents MAX_SAMPLE_RATE changes
	echo $val > $MAX_PERCENT
	# shellcheck disable=SC2320 # the '$?' refers to the echo command on purpose
	WRITE_EXIT_CODE=$?

	# the following attempt of changing MAX_SAMPLE_RATE should fail:
	echo $SOME_VALUE > $MAX_SAMPLE_RATE 2> $LOGS_DIR/perf_event_max_sample_rate_$val.err
	# shellcheck disable=SC2320 # the '$?' refers to the echo command on purpose
	test $? -eq $EXP_RESULT
	(( WRITE_EXIT_CODE += $? ))

	# check that there was an error message
	../common/check_all_lines_matched.pl "write error: Invalid argument" < $LOGS_DIR/perf_event_max_sample_rate_$val.err
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "write error: Invalid argument" < $LOGS_DIR/perf_event_max_sample_rate_$val.err
	(( CHECK_EXIT_CODE += $? ))

	# we also need to check that the value of $MAX_SAMPLE_RATE did not change
	test "`cat $MAX_SAMPLE_RATE`" -eq $MAX_SAMPLE_RATE_BACKUP
	(( CHECK_EXIT_CODE += $? ))
	test "`cat $MAX_SAMPLE_RATE`" -ne $SOME_VALUE
	(( CHECK_EXIT_CODE += $? ))

	print_results $WRITE_EXIT_CODE $CHECK_EXIT_CODE "changes disabled (perf_cpu_time_max_percent = $val): $SOME_VALUE"
	(( TEST_RESULT += $? ))
done


# restore original values
echo $MAX_PERCENT_BACKUP > $MAX_PERCENT
echo $MAX_SAMPLE_RATE_BACKUP > $MAX_SAMPLE_RATE

# print overall results
print_overall_results "$TEST_RESULT"
exit $?
