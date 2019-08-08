#!/bin/bash

#
#	test_overhead of perf_record test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tries how perf record behaves under a heavier load.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

# skip if not running in EXPERIMENTAL runmode
consider_skipping $RUNMODE_EXPERIMENTAL


# cause some load
for i in `seq 1 $MY_CPUS_ONLINE`; do
	$CURRENT_TEST_DIR/examples/load 99999 > /dev/null &
done


#### systemwide basic with loaded system

$CMD_PERF record -o $CURRENT_TEST_DIR/perf.data.1 -a 2> $LOGS_DIR/overhead_systemwide.log &
PERF_PID=$!
$CMD_VERY_LONG_SLEEP
kill -SIGINT $PERF_PID &> $LOGS_DIR/overhead_systemwide_kill.log
PERF_EXIT_CODE=$?
! wait $PERF_PID
(( PERF_EXIT_CODE += $? ))

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" < $LOGS_DIR/overhead_systemwide.log
CHECK_EXIT_CODE=$?

../common/check_no_patterns_found.pl "No such process" < $LOGS_DIR/overhead_systemwide_kill.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "systemwide basic"
(( TEST_RESULT += $? ))


#### systemwide basic with loaded system - report

$CMD_PERF report --stdio -i $CURRENT_TEST_DIR/perf.data.1 > $LOGS_DIR/overhead_systemwide_report.log 2> $LOGS_DIR/overhead_systemwide_report.err
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "function_a" "function_b" "function_F" < $LOGS_DIR/overhead_systemwide_report.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "systemwide basic report"
(( TEST_RESULT += $? ))


#### systemwide with loaded system with callgraph fp

if should_test_callgraph_fp; then
	#### systemwide with loaded system with callgraph fp
	$CMD_PERF record -g --call-graph fp -o $CURRENT_TEST_DIR/perf.data.2 -a 2> $LOGS_DIR/overhead_systemwide_callgraph_fp.log &
	PERF_PID=$!
	$CMD_VERY_LONG_SLEEP
	kill -SIGINT $PERF_PID &> $LOGS_DIR/overhead_systemwide_kill_callgraph_fp.log
	PERF_EXIT_CODE=$?
	! wait $PERF_PID
	(( PERF_EXIT_CODE += $? ))

	../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" < $LOGS_DIR/overhead_systemwide_callgraph_fp.log
	CHECK_EXIT_CODE=$?

	../common/check_no_patterns_found.pl "No such process" < $LOGS_DIR/overhead_systemwide_kill_callgraph_fp.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "systemwide with call-graph fp"
	(( TEST_RESULT += $? ))


	#### systemwide with loaded system with callgraph fp -- report

	$CMD_PERF report --stdio -g -i $CURRENT_TEST_DIR/perf.data.2 > $LOGS_DIR/overhead_systemwide_callgraph_fp_report.log 2> $LOGS_DIR/overhead_systemwide_callgraph_fp_report.err
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "function_a" "function_b" "function_F" < $LOGS_DIR/overhead_systemwide_callgraph_fp_report.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "systemwide with call-graph fp report"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "systemwide with call-graph fp"
fi


#### systemwide with loaded system with callgraph dwarf

if should_test_callgraph_dwarf; then
	#### systemwide with loaded system with callgraph dwarf
	$CMD_PERF record -g --call-graph dwarf -a -o $CURRENT_TEST_DIR/perf.data.3 2> $LOGS_DIR/overhead_systemwide_callgraph_dwarf.log &
	PERF_PID=$!
	$CMD_VERY_LONG_SLEEP
	kill -SIGINT $PERF_PID &> $LOGS_DIR/overhead_systemwide_kill_callgraph_dwarf.log
	PERF_EXIT_CODE=$?
	! wait $PERF_PID
	(( PERF_EXIT_CODE += $? ))

	../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" < $LOGS_DIR/overhead_systemwide_callgraph_dwarf.log
	CHECK_EXIT_CODE=$?

	../common/check_no_patterns_found.pl "No such process" < $LOGS_DIR/overhead_systemwide_kill_callgraph_dwarf.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "systemwide with call-graph dwarf"
	(( TEST_RESULT += $? ))


	#### systemwide with loaded system with callgraph dwarf -- report

	$CMD_PERF report --stdio -g -i $CURRENT_TEST_DIR/perf.data.3 > $LOGS_DIR/overhead_systemwide_callgraph_dwarf_report.log 2> $LOGS_DIR/overhead_systemwide_callgraph_dwarf_report.err
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "function_a" "function_b" "function_F" < $LOGS_DIR/overhead_systemwide_callgraph_dwarf_report.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "systemwide with call-graph dwarf report"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "systemwide with call-graph dwarf"
fi

# kill the load processes if there is still some
LOAD_PIDS=`pidof load`
kill $LOAD_PIDS &> /dev/null
! wait $LOAD_PIDS &> /dev/null
sleep 3
test -z "`pidof load`" || kill -9 $LOAD_PIDS &> /dev/null
test -z "`pidof load`"
CHECK_EXIT_CODE=$?

print_results 0 $CHECK_EXIT_CODE "killing all the load"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
