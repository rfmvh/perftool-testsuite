#!/bin/bash

#
#	test_field_tod of perf_script test
#	Author: Benjamin Salon <bsalon@redhat.com>
#
#	Description:
#
#		This test tests functionality of tod field of perf script command.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

consider_skipping $RUNMODE_EXPERIMENTAL

if ! should_support_tod_field; then
	print_overall_skipped
	exit 0
fi


# record

TIMESTAMP_BEFORE_RECORD=`date +%s%N`

$CMD_PERF record -a -k CLOCK_MONOTONIC -o $CURRENT_TEST_DIR/perf.data -- $CMD_QUICK_SLEEP 2> $LOGS_DIR/field_tod_record.err
PERF_EXIT_CODE=$?

TIMESTAMP_AFTER_RECORD=`date +%s%N`

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/field_tod_record.err
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "record"
(( TEST_RESULT += $? ))


### testing tod field

# script

$CMD_PERF script -F+tod -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/field_tod_script.log 2> $LOGS_DIR/field_tod_script.err
PERF_EXIT_CODE=$?

REGEX_COMMAND="[\w#~\-\+\.\/: ]+"
REGEX_EVENT="[\w]+"
REGEX_SYMBOL="(?:[\w\.@:<>*~, ]+\+$RE_ADDRESS|\[unknown\])"
REGEX_DSO="\((?:$RE_PATH_ABSOLUTE(?: \(deleted\))?|\[kernel\.kallsyms\]|\[unknown\]|\[vdso\]|\[kernel\.vmlinux\][\.\w]*)\)"

REGEX_FIELD_TOD_SCRIPT_LINE="^\s*$REGEX_COMMAND\s+$RE_NUMBER\s+\[$RE_NUMBER\]\s+$RE_DATE_YYYYMMDD\s+$RE_TIME\.$RE_NUMBER\s+($RE_NUMBER):\s+$RE_NUMBER\s*$RE_EVENT:\s+$RE_NUMBER_HEX\s+$REGEX_SYMBOL\s+$REGEX_DSO$"

../common/check_all_lines_matched.pl "$REGEX_FIELD_TOD_SCRIPT_LINE" < $LOGS_DIR/field_tod_script.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_FIELD_TOD_SCRIPT_LINE" < $LOGS_DIR/field_tod_script.log
(( CHECK_EXIT_CODE += $? ))
../common/check_timestamps.pl "$REGEX_FIELD_TOD_SCRIPT_LINE" < $LOGS_DIR/field_tod_script.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script"
(( TEST_RESULT += $? ))


# script :: sample count check

N_SAMPLES=`perl -ne 'print "$1" if /\((\d+) samples\)/' $LOGS_DIR/field_tod_record.err`

CNT=`wc -l < $LOGS_DIR/field_tod_script.log`

test $CNT -eq $N_SAMPLES
print_results 0 $? "script :: samples count check ($CNT == $N_SAMPLES)"
(( TEST_RESULT += $? ))


# time range :: lower bound

FIRST_DATE_TIME=`tail -n 1 $LOGS_DIR/field_tod_script.log | perl -ne 'print "$1" if /\s+\['$RE_NUMBER'\]\s+('$RE_DATE_YYYYMMDD'\s+'$RE_TIME'\.'$RE_NUMBER')/'`

FIRST_TIMESTAMP=`date -d "$FIRST_DATE_TIME" +%s%N`

test $TIMESTAMP_BEFORE_RECORD -le $FIRST_TIMESTAMP
CHECK_EXIT_CODE=$?

test $FIRST_TIMESTAMP -le $TIMESTAMP_AFTER_RECORD
(( CHECK_EXIT_CODE += $? ))

print_results 0 $CHECK_EXIT_CODE "time range :: lower bound ($TIMESTAMP_BEFORE_RECORD <= $FIRST_TIMESTAMP <= $TIMESTAMP_AFTER_RECORD)"
(( TEST_RESULT += $? ))


# time range :: upper bound

LAST_DATE_TIME=`tail -n 1 $LOGS_DIR/field_tod_script.log | perl -ne 'print "$1" if /\s+\['$RE_NUMBER'\]\s+('$RE_DATE_YYYYMMDD'\s+'$RE_TIME'\.'$RE_NUMBER')/'`

LAST_TIMESTAMP=`date -d "$LAST_DATE_TIME" +%s%N`

test $TIMESTAMP_BEFORE_RECORD -le $LAST_TIMESTAMP
CHECK_EXIT_CODE=$?

test $LAST_TIMESTAMP -le $TIMESTAMP_AFTER_RECORD
(( CHECK_EXIT_CODE += $? ))

print_results 0 $CHECK_EXIT_CODE "time range :: upper bound ($TIMESTAMP_BEFORE_RECORD <= $LAST_TIMESTAMP <= $TIMESTAMP_AFTER_RECORD)"
(( TEST_RESULT += $? ))


### delta times

# pick dates and times
perl -ne 'print "$1\n" if /\s+\['$RE_NUMBER'\]\s+('$RE_DATE_YYYYMMDD'\s+'$RE_TIME'\.'$RE_NUMBER')/' < $LOGS_DIR/field_tod_script.log > $LOGS_DIR/field_tod_dates_times.log
CMD_EXIT_CODE=$?

# create nanosecond deltas from dates and times
LAST_TIMESTAMP=$(date -d "`head -n 1 $LOGS_DIR/field_tod_dates_times.log`" +%s%N)
while read date_time; do
	CURRENT_TIMESTAMP=`date -d "$date_time" +%s%N`
	echo $CURRENT_TIMESTAMP - $LAST_TIMESTAMP | bc
	LAST_TIMESTAMP=$CURRENT_TIMESTAMP
done < $LOGS_DIR/field_tod_dates_times.log > $LOGS_DIR/field_tod_counted_deltas_ns.log

# pick timestamps
perl -ne 'print "$1\n" if /\s+'$RE_DATE_YYYYMMDD'\s+'$RE_TIME'\.'$RE_NUMBER'\s+('$RE_NUMBER'):/' < $LOGS_DIR/field_tod_script.log > $LOGS_DIR/field_tod_timestamps.log
(( CMD_EXIT_CODE += $? ))

# create nanosecond deltas from script output
LAST_TIME_FIELD=$(echo `head -n 1 $LOGS_DIR/field_tod_timestamps.log` \* 1000000000 | bc)
while read timestamps; do
	CURRENT_TIME_FIELD=`echo "$timestamps" \* 1000000000 | bc`
	echo $CURRENT_TIME_FIELD - $LAST_TIME_FIELD | bc
	LAST_TIME_FIELD=$CURRENT_TIME_FIELD
done < $LOGS_DIR/field_tod_timestamps.log > $LOGS_DIR/field_tod_real_deltas_ns.log

# create deltas subtractions
pr -m -t -s" - " $LOGS_DIR/field_tod_counted_deltas_ns.log $LOGS_DIR/field_tod_real_deltas_ns.log > $LOGS_DIR/field_tod_deltas_subtractions.log
(( CMD_EXIT_CODE += $? ))

# compare counted and real deltas
CHECK_EXIT_CODE=0
while read equation; do
	RESULT=`echo $equation | bc | tr -d -`
	# we can accept small impreciseness
	ZERO=`echo $RESULT \> 1000 | bc`
	(( CHECK_EXIT_CODE += $ZERO ))
done < $LOGS_DIR/field_tod_deltas_subtractions.log

print_results $CMD_EXIT_CODE $CHECK_EXIT_CODE "delta times :: wrong deltas count (0 == $CHECK_EXIT_CODE)"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results $TEST_RESULT
exit $?
