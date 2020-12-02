#!/bin/bash

#
#	test_basic of perf_script test
#	Author: Benjamin Salon <bsalon@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf script command.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

consider_skipping $RUNMODE_STANDARD

### help message

if [ "$PARAM_GENERAL_HELP_TEXT_CHECK" = "y" ]; then
	# test that a help message is shown and looks reasonable
	$CMD_PERF script --help > $LOGS_DIR/basic_helpmsg.log
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "PERF-SCRIPT" "NAME" "SYNOPSIS" "DESCRIPTION" "OPTIONS" "SEE ALSO" < $LOGS_DIR/basic_helpmsg.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "record" "report" "scripts" "list" "fields" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "help message"
fi


# record

$CMD_PERF record -a -o $CURRENT_TEST_DIR/perf.data -- $CMD_BASIC_SLEEP 2> $LOGS_DIR/basic_record.err &
PERF_PID=$!
wait $PERF_PID
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/basic_record.err
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "record"
(( TEST_RESULT += $? ))


# script

$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_script.log 2> $LOGS_DIR/basic_script.err
PERF_EXIT_CODE=$?

REGEX_COMMAND="[\w#~\-\+\.\/: ]+"
REGEX_EVENT="[\w]+"
REGEX_SYMBOL="(?:[\w\.@:<>*~, ]+\+$RE_ADDRESS|\[unknown\])"
REGEX_DSO="\((?:$RE_PATH_ABSOLUTE(?: \(deleted\))?|\[kernel\.kallsyms\]|\[unknown\]|\[vdso\]|\[kernel\.vmlinux\][\.\w]*)\)"

REGEX_BASIC_SCRIPT_LINE="^\s*$REGEX_COMMAND\s+$RE_NUMBER\s+\[$RE_NUMBER\]\s+($RE_NUMBER):\s+$RE_NUMBER\s*$RE_EVENT:\s+$RE_NUMBER_HEX\s+$REGEX_SYMBOL\s+$REGEX_DSO$"

../common/check_all_lines_matched.pl "$REGEX_BASIC_SCRIPT_LINE" < $LOGS_DIR/basic_script.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_BASIC_SCRIPT_LINE" < $LOGS_DIR/basic_script.log
(( CHECK_EXIT_CODE += $? ))
../common/check_timestamps.pl "$REGEX_BASIC_SCRIPT_LINE" < $LOGS_DIR/basic_script.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script"
(( TEST_RESULT += $? ))


# script :: sample count check

N_SAMPLES=`perl -ne 'print "$1" if /\((\d+) samples\)/' $LOGS_DIR/basic_record.err`

CNT=`wc -l < $LOGS_DIR/basic_script.log`

test $CNT -eq $N_SAMPLES
print_results 0 $? "script :: sample count check ($CNT == $N_SAMPLES)"
(( TEST_RESULT += $? ))


# record :: small

$CMD_PERF record -o $CURRENT_TEST_DIR/perf_small.data -- $CMD_QUICK_SLEEP > $LOGS_DIR/basic_record_small.log 2> $LOGS_DIR/basic_record_small.err
PERF_EXIT_CODE=$?

COMMAND_NAME="sleep"

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2_TOLERANT_FILENAME" "perf_small.data" < $LOGS_DIR/basic_record_small.err
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "record :: small"
(( TEST_RESULT += $? ))


### basic script tests

$CMD_PERF script -i $CURRENT_TEST_DIR/perf_small.data > $LOGS_DIR/basic_script_small.log 2> $LOGS_DIR/basic_script_small.err
PERF_EXIT_CODE=$?

REGEX_BASIC_SMALL_SCRIPT_LINE="^\s*(?:perf|$COMMAND_NAME)\s+$RE_NUMBER\s+($RE_NUMBER):\s+$RE_NUMBER\s*$RE_EVENT:\s+$RE_NUMBER_HEX\s+$REGEX_SYMBOL\s+$REGEX_DSO$"

../common/check_all_lines_matched.pl "$REGEX_BASIC_SMALL_SCRIPT_LINE" < $LOGS_DIR/basic_script_small.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_BASIC_SMALL_SCRIPT_LINE" < $LOGS_DIR/basic_script_small.log
(( CHECK_EXIT_CODE += $? ))
../common/check_timestamps.pl "$REGEX_BASIC_SMALL_SCRIPT_LINE" < $LOGS_DIR/basic_script_small.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script :: small"
(( TEST_RESULT += $? ))


# script :: sample count check

N_SAMPLES=`perl -ne 'print "$1" if /\((\d+) samples\)/' $LOGS_DIR/basic_record_small.err`

CNT=`wc -l < $LOGS_DIR/basic_script_small.log`

test $CNT -eq $N_SAMPLES
print_results 0 $? "script :: small :: sample count check ($CNT == $N_SAMPLES)"
(( TEST_RESULT += $? ))


# script :: latency

$CMD_PERF script --Latency -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_script_latency.log 2> $LOGS_DIR/basic_script_latency.err
PERF_EXIT_CODE=$?

REGEX_LATENCY_SCRIPT_LINE="^\s*$REGEX_COMMAND\s+$RE_NUMBER\s+$RE_NUMBER\s+($RE_NUMBER):\s+$RE_NUMBER\s*$RE_EVENT:\s+$RE_NUMBER_HEX\s+$REGEX_SYMBOL\s+$REGEX_DSO$"

../common/check_all_lines_matched.pl "$REGEX_LATENCY_SCRIPT_LINE" < $LOGS_DIR/basic_script_latency.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_LATENCY_SCRIPT_LINE" < $LOGS_DIR/basic_script_latency.log
(( CHECK_EXIT_CODE += $? ))
../common/check_timestamps.pl "$REGEX_LATENCY_SCRIPT_LINE" < $LOGS_DIR/basic_script_latency.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script :: latency"
(( TEST_RESULT += $? ))


# script :: latency :: sample count check

N_SAMPLES=`perl -ne 'print "$1" if /\((\d+) samples\)/' $LOGS_DIR/basic_record.err`

CNT=`wc -l < $LOGS_DIR/basic_script_latency.log`

test $CNT -eq $N_SAMPLES
print_results 0 $? "script :: latency :: sample count check ($CNT == $N_SAMPLES)"
(( TEST_RESULT += $? ))


# script :: cpu

$CMD_PERF script --cpu 0 -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_script_cpu.log 2> $LOGS_DIR/basic_script_cpu.err
PERF_EXIT_CODE=$?

REGEX_CPU_0_SCRIPT_LINE="^\s*$REGEX_COMMAND\s+$RE_NUMBER\s+\[000\]\s+($RE_NUMBER):\s+$RE_NUMBER\s*$RE_EVENT:\s+$RE_NUMBER_HEX\s+$REGEX_SYMBOL\s+$REGEX_DSO$"

../common/check_all_lines_matched.pl "$REGEX_CPU_0_SCRIPT_LINE" < $LOGS_DIR/basic_script_cpu.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_CPU_0_SCRIPT_LINE" < $LOGS_DIR/basic_script_cpu.log
(( CHECK_EXIT_CODE += $? ))
../common/check_timestamps.pl "$REGEX_CPU_0_SCRIPT_LINE" < $LOGS_DIR/basic_script_cpu.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script :: cpu"
(( TEST_RESULT += $? ))


# script :: cpu :: sample count check

CNT=`wc -l < $LOGS_DIR/basic_script_cpu.log`

test $CNT -le $N_SAMPLES
print_results 0 $? "script :: cpu :: sample count check ($CNT <= $N_SAMPLES)"
(( TEST_RESULT += $? ))


### script :: comms

# script :: comms :: one value

REGEX_PERF_COMM_SCRIPT_LINE="^\s*perf\s+$RE_NUMBER\s+\[$RE_NUMBER\]\s+($RE_NUMBER):\s+$RE_NUMBER\s*$RE_EVENT:\s+$RE_NUMBER_HEX\s+$REGEX_SYMBOL\s+$REGEX_DSO$"
REGEX_SLEEP_COMM_SCRIPT_LINE="^\s*sleep\s+$RE_NUMBER\s+\[$RE_NUMBER\]\s+($RE_NUMBER):\s+$RE_NUMBER\s*$RE_EVENT:\s+$RE_NUMBER_HEX\s+$REGEX_SYMBOL\s+$REGEX_DSO$"
REGEX_COMMAND_NAME_COMM_SCRIPT_LINE="^\s*$COMMAND_NAME\s+$RE_NUMBER\s+\[$RE_NUMBER\]\s+($RE_NUMBER):\s+$RE_NUMBER\s*$RE_EVENT:\s+$RE_NUMBER_HEX\s+$REGEX_SYMBOL\s+$REGEX_DSO$"

REGEX_PERF_COMM_SMALL_SCRIPT_LINE="^\s*perf\s+$RE_NUMBER\s+($RE_NUMBER):\s+$RE_NUMBER\s*$RE_EVENT:\s+$RE_NUMBER_HEX\s+$REGEX_SYMBOL\s+$REGEX_DSO$"
REGEX_COMMAND_NAME_COMM_SMALL_SCRIPT_LINE="^\s*$COMMAND_NAME\s+$RE_NUMBER\s+($RE_NUMBER):\s+$RE_NUMBER\s*$RE_EVENT:\s+$RE_NUMBER_HEX\s+$REGEX_SYMBOL\s+$REGEX_DSO$"

$CMD_PERF script -c perf -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_script_comms_one.log 2> $LOGS_DIR/basic_script_comms_one.err
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$REGEX_PERF_COMM_SCRIPT_LINE" < $LOGS_DIR/basic_script_comms_one.log
CHECK_EXIT_CODE=$?
../common/check_timestamps.pl "$REGEX_PERF_COMM_SCRIPT_LINE" < $LOGS_DIR/basic_script_comms_one.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script :: comms :: one value"
(( TEST_RESULT += $? ))


# script :: comms :: more values

$CMD_PERF script -c perf,sleep -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_script_comms_more.log 2> $LOGS_DIR/basic_script_comms_more.err
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$REGEX_PERF_COMM_SCRIPT_LINE" "$REGEX_SLEEP_COMM_SCRIPT_LINE" < $LOGS_DIR/basic_script_comms_more.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "(?:$REGEX_PERF_COMM_SCRIPT_LINE|$REGEX_SLEEP_COMM_SCRIPT_LINE)" < $LOGS_DIR/basic_script_comms_more.log
(( CHECK_EXIT_CODE += $? ))
../common/check_timestamps.pl "$REGEX_BASIC_SCRIPT_LINE" < $LOGS_DIR/basic_script_comms_more.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script :: comms :: more values"
(( TEST_RESULT += $? ))


# script :: comms :: nonexisting value

$CMD_PERF script -c nonexisting -i $CURRENT_TEST_DIR/perf_small.data > $LOGS_DIR/basic_script_comms_nonexisting.log 2> $LOGS_DIR/basic_script_comms_nonexisting.err
PERF_EXIT_CODE=$?

! test -s $LOGS_DIR/basic_script_comms_nonexisting.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script :: comms :: nonexiting value"
(( TEST_RESULT += $? ))


# script :: comms :: all applicable values

$CMD_PERF script -c perf,$COMMAND_NAME -i $CURRENT_TEST_DIR/perf_small.data > $LOGS_DIR/basic_script_comms_all.log 2> $LOGS_DIR/basic_script_comms_all.err
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$REGEX_PERF_COMM_SMALL_SCRIPT_LINE" "$REGEX_COMMAND_NAME_COMM_SMALL_SCRIPT_LINE" < $LOGS_DIR/basic_script_comms_all.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "(?:$REGEX_PERF_COMM_SMALL_SCRIPT_LINE|$REGEX_COMMAND_NAME_COMM_SMALL_SCRIPT_LINE)" < $LOGS_DIR/basic_script_comms_all.log
(( CHECK_EXIT_CODE += $? ))
../common/check_timestamps.pl "$REGEX_BASIC_SMALL_SCRIPT_LINE" < $LOGS_DIR/basic_script_comms_all.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script :: comms :: all applicable values"
(( TEST_RESULT += $? ))


# script :: comms :: all applicable values :: count check

N_SAMPLES=`perl -ne 'print "$1" if /\((\d+) samples\)/' $LOGS_DIR/basic_record_small.err`

CNT=`wc -l < $LOGS_DIR/basic_script_comms_all.log`

test $CNT -eq $N_SAMPLES
print_results 0 $? "script :: comms :: all applicable values :: sample count check ($CNT == $N_SAMPLES)"
(( TEST_RESULT += $? ))

### script :: pid / tid
for PID_TID in "pid" "tid"; do
	# script :: pid/tid :: one value

	$CMD_PERF script --$PID_TID=$PERF_PID -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_script_${PID_TID}_one.log 2> $LOGS_DIR/basic_script_${PID_TID}_one.err
	PERF_EXIT_CODE=$?

	../common/check_all_lines_matched.pl "$REGEX_PERF_COMM_SCRIPT_LINE" < $LOGS_DIR/basic_script_${PID_TID}_one.log
	CHECK_EXIT_CODE=$?
	../common/check_timestamps.pl "$REGEX_PERF_COMM_SCRIPT_LINE" < $LOGS_DIR/basic_script_${PID_TID}_one.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script :: $PID_TID :: one value"
	(( TEST_RESULT += $? ))


	# script :: pid/tid :: more values

	SLEEP_PID="`grep -P "$REGEX_SLEEP_COMM_SCRIPT_LINE" < $LOGS_DIR/basic_script.log | head -n 1 | awk '{print $2}'`"

	$CMD_PERF script --$PID_TID=$PERF_PID,${SLEEP_PID:-"1234567890"} -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_script_${PID_TID}_more.log 2> $LOGS_DIR/basic_script_${PID_TID}_more.err
	PERF_EXIT_CODE=$?

	../common/check_all_lines_matched.pl "$REGEX_PERF_COMM_SCRIPT_LINE" "$REGEX_SLEEP_COMM_SCRIPT_LINE" < $LOGS_DIR/basic_script_${PID_TID}_more.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "(?:$REGEX_PERF_COMM_SCRIPT_LINE|$REGEX_SLEEP_COMM_SCRIPT_LINE)" < $LOGS_DIR/basic_script_${PID_TID}_more.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_timestamps.pl "$REGEX_BASIC_SCRIPT_LINE" < $LOGS_DIR/basic_script_${PID_TID}_more.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script :: $PID_TID :: more values"
	(( TEST_RESULT += $? ))


	# script :: pid/tid :: nonexisting value

	$CMD_PERF script --$PID_TID=1234567890 -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_script_${PID_TID}_nonexisting.log 2> $LOGS_DIR/basic_script_${PID_TID}_nonexisting.err
	PERF_EXIT_CODE=$?

	! test -s $LOGS_DIR/basic_script_${PID_TID}_nonexisting.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script :: $PID_TID :: nonexiting value"
	(( TEST_RESULT += $? ))


	# script :: pid/tid :: all applicable values

	PERF_SMALL_PID="`grep -P "$REGEX_PERF_COMM_SMALL_SCRIPT_LINE" < $LOGS_DIR/basic_script_small.log | head -n 1 | awk '{print $2}'`"
	COMMAND_NAME_PID="`grep -P "$REGEX_COMMAND_NAME_COMM_SMALL_SCRIPT_LINE" < $LOGS_DIR/basic_script_small.log | head -n 1 | awk '{print $2}'`"

	if [ $COMMAND_NAME_PID -eq $PERF_SMALL_PID ] 2> /dev/null; then
		COMMAND_NAME_PID=1234567890
	fi

	$CMD_PERF script --$PID_TID=$PERF_SMALL_PID,$COMMAND_NAME_PID -i $CURRENT_TEST_DIR/perf_small.data > $LOGS_DIR/basic_script_${PID_TID}_all.log 2> $LOGS_DIR/basic_script_${PID_TID}_all.err
	PERF_EXIT_CODE=$?

	../common/check_all_lines_matched.pl "$REGEX_PERF_COMM_SMALL_SCRIPT_LINE" "$REGEX_COMMAND_NAME_COMM_SMALL_SCRIPT_LINE" < $LOGS_DIR/basic_script_${PID_TID}_all.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "(?:$REGEX_PERF_COMM_SMALL_SCRIPT_LINE|$REGEX_COMMAND_NAME_COMM_SMALL_SCRIPT_LINE)" < $LOGS_DIR/basic_script_${PID_TID}_all.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_timestamps.pl "$REGEX_BASIC_SMALL_SCRIPT_LINE" < $LOGS_DIR/basic_script_${PID_TID}_all.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script :: $PID_TID :: all applicable values"
	(( TEST_RESULT += $? ))


	# script :: pid/tid :: all applicable values :: count check

	CNT=`wc -l < $LOGS_DIR/basic_script_${PID_TID}_all.log`

	test $CNT -eq $N_SAMPLES
	print_results 0 $? "script :: $PID_TID :: all applicable values :: sample count check ($CNT == $N_SAMPLES)"
	(( TEST_RESULT += $? ))
done


print_overall_results $TEST_RESULT
exit $?
