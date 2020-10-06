#!/bin/bash

#
#	test_basic of perf_script test
#	Author: Benjamin Salon <bsalon@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of time options of perf script command.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

consider_skipping $RUNMODE_STANDARD

# record

$CMD_PERF record -a -o $CURRENT_TEST_DIR/perf.data -- $CMD_BASIC_SLEEP 2> $LOGS_DIR/time_record.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/time_record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "record"
(( TEST_RESULT += $? ))


### ns option

$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data --ns > $LOGS_DIR/time_script_ns.log 2> $LOGS_DIR/time_script_ns.err
PERF_EXIT_CODE=$?

REGEX_COMMAND="[\w#~\.\-\+\/: ]+"
REGEX_EVENT="[\w]+"
REGEX_SYMBOL="(?:[\w\.\@\&:<>*~, ]+\+$RE_ADDRESS|\[unknown\])"
REGEX_DSO="\((?:$RE_PATH_ABSOLUTE(?: \(deleted\))?|\[kernel\.kallsyms\]|\[\w+]|\[kernel\.vmlinux\][\w\.]*)\)"

REGEX_NS_SCRIPT_LINE="^\s*$REGEX_COMMAND\s+$RE_NUMBER\s+\[$RE_NUMBER\]\s+([0-9]+\.[0-9]{9}):\s+$RE_NUMBER\s*$RE_EVENT:\s+$RE_NUMBER_HEX\s+$REGEX_SYMBOL\s+$REGEX_DSO$"

../common/check_all_lines_matched.pl "$REGEX_NS_SCRIPT_LINE" < $LOGS_DIR/time_script_ns.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_NS_SCRIPT_LINE" < $LOGS_DIR/time_script_ns.log
(( CHECK_EXIT_CODE += $? ))
../common/check_timestamps.pl "$REGEX_NS_SCRIPT_LINE" < $LOGS_DIR/time_script_ns.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "ns option"
(( TEST_RESULT += $? ))


# ns option :: sample count check

N_SAMPLES=`perl -ne 'print "$1" if /\((\d+) samples\)/' $LOGS_DIR/time_record.log`

CNT=`wc -l < $LOGS_DIR/time_script_ns.log`

test $CNT -eq $N_SAMPLES
print_results 0 $? "ns option :: sample count check ($CNT == $N_SAMPLES)"
(( TEST_RESULT += $? ))


### time option

REGEX_SCRIPT_LINE="^\s*$REGEX_COMMAND\s+$RE_NUMBER\s+\[$RE_NUMBER\]\s+($RE_NUMBER):\s+$RE_NUMBER\s*$RE_EVENT:\s+$RE_NUMBER_HEX\s+$REGEX_SYMBOL\s+$REGEX_DSO$"

# time option :: 0%-10%

$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data --time 0%-10% > $LOGS_DIR/time_script_time_0-10.log 2> $LOGS_DIR/time_script_time_0-10.err
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_0-10.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_0-10.log
(( CHECK_EXIT_CODE += $? ))
../common/check_timestamps.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_0-10.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "time option :: 0%-10%"
(( TEST_RESULT += $? ))


# time option :: 80%-100%

$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data --time 80%-100% > $LOGS_DIR/time_script_time_80-100.log 2> $LOGS_DIR/time_script_time_80-100.err
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_80-100.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_80-100.log
(( CHECK_EXIT_CODE += $? ))
../common/check_timestamps.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_80-100.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "time option :: 80%-100%"
(( TEST_RESULT += $? ))


# time option :: 80%-100%,0%-10%

$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data --time 80%-100%,0%-10% > $LOGS_DIR/time_script_time_80-100_0-10.log 2> $LOGS_DIR/time_script_time_80-100_0-10.err
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_80-100_0-10.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_80-100_0-10.log
(( CHECK_EXIT_CODE += $? ))
../common/check_timestamps.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_80-100_0-10.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "time option :: 80%-100%,0%-10%"
(( TEST_RESULT += $? ))


# time option :: 80%-100%,0%-10% :: content comparison

cat $LOGS_DIR/time_script_time_0-10.log $LOGS_DIR/time_script_time_80-100.log > $LOGS_DIR/time_script_time_0-10_cat_80-100.log
CAT_EXIT_CODE=$?

cmp $LOGS_DIR/time_script_time_0-10_cat_80-100.log $LOGS_DIR/time_script_time_80-100_0-10.log &> $LOGS_DIR/time_script_time_80-100_0-10.cmp
CHECK_EXIT_CODE=$?

# we do not mind if one file has EOF at the end
! grep -q EOF < $LOGS_DIR/time_script_time_80-100_0-10.cmp
(( CHECK_EXIT_CODE -= $? ))

print_results $CAT_EXIT_CODE $CHECK_EXIT_CODE "time option :: 80%-100%,0%-10% :: content comparison"
(( TEST_RESULT += $? ))


# time option :: 10%/1

$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data --time 10%/1 > $LOGS_DIR/time_script_time_10_1.log 2> $LOGS_DIR/time_script_time_10_1.err
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_10_1.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_10_1.log
(( CHECK_EXIT_CODE += $? ))
../common/check_timestamps.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_10_1.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "time option :: 10%/1"
(( TEST_RESULT += $? ))


# time option :: 10%/1 :: content comparison

cmp $LOGS_DIR/time_script_time_0-10.log $LOGS_DIR/time_script_time_10_1.log &> $LOGS_DIR/time_script_time_10_1.cmp
CHECK_EXIT_CODE=$?

# we do not mind if one file has EOF at the end
! grep -q EOF < $LOGS_DIR/time_script_time_10_1.cmp
(( CHECK_EXIT_CODE -= $? ))

print_results 0 $CHECK_EXIT_CODE "time option :: 10%/1 :: content comparison"
(( TEST_RESULT += $? ))


# time option :: 10%/1,20%/5

$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data --time 10%/1,20%/5 > $LOGS_DIR/time_script_time_10_1_20_5.log 2> $LOGS_DIR/time_script_time_10_1_20_5.err
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_10_1_20_5.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_10_1_20_5.log
(( CHECK_EXIT_CODE += $? ))
../common/check_timestamps.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_10_1_20_5.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "time option :: 10%/1,20%/5"
(( TEST_RESULT += $? ))


# time option :: 10%/1,20%/5 :: content comparison

cmp $LOGS_DIR/time_script_time_80-100_0-10.log $LOGS_DIR/time_script_time_10_1_20_5.log &> $LOGS_DIR/time_script_time_10_1_20_5.cmp
CHECK_EXIT_CODE=$?

# we do not mind if one file has EOF at the end
! grep -q EOF < $LOGS_DIR/time_script_time_10_1_20_5.cmp
(( CHECK_EXIT_CODE -= $? ))

print_results 0 $CHECK_EXIT_CODE "time option :: 10%/1,20%/5 :: content comparison"
(( TEST_RESULT += $? ))


LOWER_SAMPLE_NUM=`echo $N_SAMPLES / 3 | bc`
UPPER_SAMPLE_NUM=`echo $LOWER_SAMPLE_NUM \* 2 | bc`
LOWER_TIME_BOUND=`sed "${LOWER_SAMPLE_NUM}q;d" $LOGS_DIR/time_script_ns.log | perl -ne 'print "$1" if /'"$REGEX_SCRIPT_LINE"'/' | xargs printf "%.6f" | tr ',' '.'`
UPPER_TIME_BOUND=`sed "${UPPER_SAMPLE_NUM}q;d" $LOGS_DIR/time_script_ns.log | perl -ne 'print "$1" if /'"$REGEX_SCRIPT_LINE"'/' | xargs printf "%.6f" | tr ',' '.'`

# time option :: lower, ($LOWER_TIME_BOUND,)

$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data --time $LOWER_TIME_BOUND, > $LOGS_DIR/time_script_time_low.log 2> $LOGS_DIR/time_script_time_low.err
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_low.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_low.log
(( CHECK_EXIT_CODE += $? ))
../common/check_timestamps.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_low.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "time option :: lower_bound, ($LOWER_TIME_BOUND,)"
(( TEST_RESULT += $? ))


# time option :: lower_bound, ($LOWER_TIME_BOUND,) :: bound check

CHECK_EXIT_CODE=`perl -ne 'BEGIN{$n=0;} {$n+=1 if (/'"$REGEX_SCRIPT_LINE"'/ and $1 < '$LOWER_TIME_BOUND');} END{print "$n";}' $LOGS_DIR/time_script_time_low.log`
print_results 0 $CHECK_EXIT_CODE "time option :: lower_bound, ($LOWER_TIME_BOUND,) :: bound check"
(( TEST_RESULT += $? ))


# time option :: ,upper_bound (,$UPPER_TIME_BOUND)

$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data --time ,$UPPER_TIME_BOUND > $LOGS_DIR/time_script_time_up.log 2> $LOGS_DIR/time_script_time_up.err
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_up.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_up.log
(( CHECK_EXIT_CODE += $? ))
../common/check_timestamps.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_up.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "time option :: ,upper_bound (,$UPPER_TIME_BOUND)"
(( TEST_RESULT += $? ))


# time option :: ,upper_bound ($UPPER_TIME_BOUND,) :: bound check

CHECK_EXIT_CODE=`perl -ne 'BEGIN{$n=0;} {$n+=1 if (/'"$REGEX_SCRIPT_LINE"'/ and $1 > '$UPPER_TIME_BOUND');} END{print "$n";}' $LOGS_DIR/time_script_time_up.log`
print_results 0 $CHECK_EXIT_CODE "time option :: ,upper_bound (,$UPPER_TIME_BOUND) :: bound check"
(( TEST_RESULT += $? ))


# time option :: lower_bound,upper_bound ($LOWER_TIME_BOUND,$UPPER_TIME_BOUND)

$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data --time $LOWER_TIME_BOUND,$UPPER_TIME_BOUND > $LOGS_DIR/time_script_time_low_up.log 2> $LOGS_DIR/time_script_time_low_up.err
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_low_up.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_low_up.log
(( CHECK_EXIT_CODE += $? ))
../common/check_timestamps.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_time_low_up.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "time option :: lower_bound,upper_bound ($LOWER_TIME_BOUND,$UPPER_TIME_BOUND)"
(( TEST_RESULT += $? ))


# time option :: lower_bound,upper_bound ($LOWER_TIME_BOUND,$UPPER_TIME_BOUND) :: bound check

CHECK_EXIT_CODE=`perl -ne 'BEGIN{$n=0;} {$n+=1 if (/'"$REGEX_SCRIPT_LINE"'/ and $1 < '$LOWER_TIME_BOUND' or $1 > '$UPPER_TIME_BOUND');} END{print "$n";}' $LOGS_DIR/time_script_time_low_up.log`
print_results 0 $CHECK_EXIT_CODE "time option :: lower_bound,upper_bound ($LOWER_TIME_BOUND,$UPPER_TIME_BOUND) :: bound check"
(( TEST_RESULT += $? ))


### reltime option

if ! should_support_reltime_option; then
	print_testcase_skipped "reltime option"
else
	# reltime option

	$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data --reltime > $LOGS_DIR/time_script_reltime.log 2> $LOGS_DIR/time_script_reltime.err
	PERF_EXIT_CODE=$?

	../common/check_all_lines_matched.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_reltime.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_reltime.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_timestamps.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_reltime.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "reltime option"
	(( TEST_RESULT += $? ))


	# reltime option :: sample count check

	CNT=`wc -l < $LOGS_DIR/time_script_reltime.log`

	test $CNT -eq $N_SAMPLES
	print_results 0 $? "reltime option :: sample count check ($CNT == $N_SAMPLES)"
	(( TEST_RESULT += $? ))


	# reltime option :: first line zero time

	REGEX_ZERO_TIME_SCRIPT_LINE="^\s*$REGEX_COMMAND\s+$RE_NUMBER\s+\[$RE_NUMBER\]\s+(0\.0+):\s+$RE_NUMBER\s*$RE_EVENT:\s+$RE_NUMBER_HEX\s+$REGEX_SYMBOL\s+$REGEX_DSO$"

	head -n 1 $LOGS_DIR/time_script_reltime.log | ../common/check_all_patterns_found.pl "$REGEX_ZERO_TIME_SCRIPT_LINE"
	CHECK_EXIT_CODE=$?

	print_results 0 $CHECK_EXIT_CODE "reltime option :: first line zero time"
	(( TEST_RESULT += $? ))
fi


### deltatime option

if ! should_support_deltatime_option; then
	print_testcase_skipped "deltatime option"
else
	# deltatime option

	$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data --deltatime > $LOGS_DIR/time_script_deltatime.log 2> $LOGS_DIR/time_script_deltatime.err
	PERF_EXIT_CODE=$?

	../common/check_all_lines_matched.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_deltatime.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/time_script_deltatime.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "deltatime option"
	(( TEST_RESULT += $? ))


	# deltatime option :: sample count check

	CNT=`wc -l < $LOGS_DIR/time_script_deltatime.log`

	test $CNT -eq $N_SAMPLES
	print_results 0 $? "deltatime option :: sample count check ($CNT == $N_SAMPLES)"
	(( TEST_RESULT += $? ))


	# deltatime option :: wrong deltas count

	# deltatime option delta times
	tr -s ' ' < $LOGS_DIR/time_script_deltatime.log | cut -d'[' -f2 | cut -d' ' -f2 | tr -d ':' > $LOGS_DIR/time_script_deltatime_deltas.log

	perl -ne 'BEGIN{$last=0;} {print "$1 - $last\n" if /['$RE_NUMBER']\s+('$RE_NUMBER'):/; $last=$1 if /['$RE_NUMBER']\s+('$RE_NUMBER'):/;}' $LOGS_DIR/time_script_reltime.log > $LOGS_DIR/time_script_deltas_subtractions.log

	# count delta times from reltime option times
	while read equation; do
		echo $equation | bc
	done < $LOGS_DIR/time_script_deltas_subtractions.log > $LOGS_DIR/time_script_deltas.log

	pr -m -t -s" - " $LOGS_DIR/time_script_deltatime_deltas.log $LOGS_DIR/time_script_deltas.log > $LOGS_DIR/time_script_deltatime_subtractions.log
	PR_EXIT_CODE=$?

	CHECK_EXIT_CODE=0
	while read equation; do
		RESULT=`echo $equation | bc | tr -d -`
		# we can accept small impreciseness
		ZERO=`echo $RESULT \> 0.000001 | bc`
		(( CHECK_EXIT_CODE += $ZERO ))
	done < $LOGS_DIR/time_script_deltatime_subtractions.log

	print_results $PR_EXIT_CODE $CHECK_EXIT_CODE "deltatime option :: wrong deltas count (0 == $CHECK_EXIT_CODE)"
	(( TEST_RESULT += $? ))
fi


print_overall_results $TEST_RESULT
exit $?
