#!/bin/bash

#
#       test_basic of perf_sched test
#       Author: Benjamin Salon <bsalon@redhat.com>
#
#       Description:
#
#               This test tests basic functionality of perf sched command.
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
	$CMD_PERF sched --help > $LOGS_DIR/basic_helpmsg.log
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "PERF-SCHED" "NAME" "SYNOPSIS" "DESCRIPTION" "OPTIONS" "OPTIONS FOR PERF SCHED MAP" "OPTIONS FOR PERF SCHED TIMEHIST" "SEE ALSO" < $LOGS_DIR/basic_helpmsg.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "record" "latency" "map" "replay" "script" "timehist" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "help message"
fi


### basic execution

# record

$CMD_PERF sched record -a -o $CURRENT_TEST_DIR/perf.data -- $CMD_LONGER_SLEEP 2> $LOGS_DIR/basic_record.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/basic_record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "sched record"
(( TEST_RESULT += $? ))


# latency

$CMD_PERF sched latency -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_latency.log 2> $LOGS_DIR/basic_latency.err
PERF_EXIT_CODR=$?

REGEX_SEP="\s*\|\s*"
REGEX_HEADER_LINE="\s+Task${REGEX_SEP}Runtime ms${REGEX_SEP}Switches${REGEX_SEP}Average delay ms${REGEX_SEP}Maximum delay ms${REGEX_SEP}Maximum delay at${REGEX_SEP}"
REGEX_HEADER_UNDERLINE="-{100,}"
REGEX_DATA_LINE="\s+\S+$REGEX_SPR$RE_NUMBER ms$REGEX_SEP\d+${REGEX_SEP}avg:\s*($RE_NUMBER) ms${REGEX_SEP}max:\s*($RE_NUMBER) ms${REGEX_SEP}max at:\s+$RE_NUMBER s"
REGEX_TOTAL_LINE="\s+TOTAL:$REGEX_SEP$RE_NUMBER ms$REGEX_SEP\d+ \|"
REGEX_TOTAL_UNDERLINE="-{40,}"

../common/check_all_lines_matched.pl "^\s*$" "$REGEX_HEADER_LINE" "$REGEX_HEADER_UNDERLINE" "$REGEX_DATA_LINE" "$REGEX_TOTAL_LINE" "$REGEX_TOTAL_UNDERLINE" < $LOGS_DIR/basic_latency.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_HEADER_LINE" "$REGEX_HEADER_UNDERLINE" "$REGEX_TOTAL_LINE" "$REGEX_TOTAL_UNDERLINE" < $LOGS_DIR/basic_latency.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "sched latency"
(( TEST_RESULT += $? ))


# latency count check
cat $LOGS_DIR/basic_latency.log | cut -s -d'|' -f2-3 > $LOGS_DIR/basic_latency_count.log

COUNT_RUNTIME=`head -n -1 $LOGS_DIR/basic_latency_count.log | perl -ne 'BEGIN{$n=0;} {$n+=$1 if (/\s*([\d\.]+) ms \|\s*\d+/)} END{print "$n";}'`
RESULT_RUNTIME=`tail -n 1 $LOGS_DIR/basic_latency_count.log | perl -ne 'BEGIN{$n=0;} {$n+=$1 if (/\s*([\d\.]+) ms \|\s*\d+/)} END{print "$n";}'`

CHECK_EXIT_CODE=`perl -e 'print 0; print 1 if abs('$COUNT_RUNTIME' - '$RESULT_RUNTIME') > 0.005'`

print_results 0 $CHECK_EXIT_CODE "sched latency count check (|$COUNT_RUNTIME - $RESULT_RUNTIME| <= 0.005)"
(( TEST_RESULT += $? ))


# switches count check
COUNT_SWITCHES=`head -n -1 $LOGS_DIR/basic_latency_count.log | perl -ne 'BEGIN{$n=0;} {$n+=$1 if (/\s*[\d\.]+ ms \|\s*(\d+)/)} END{print "$n";}'`
RESULT_SWITCHES=`tail -n 1 $LOGS_DIR/basic_latency_count.log | perl -ne 'BEGIN{$n=0;} {$n+=$1 if (/\s*[\d\.]+ ms \|\s*(\d+)/)} END{print "$n";}'`

CHECK_EXIT_CODE=`perl -e 'print 0; print 1 if abs('$COUNT_SWITCHES' - '$RESULT_SWITCHES') > 0'`

print_results 0 $CHECK_EXIT_CODE "sched switches count check ($COUNT_SWITCHES == $RESULT_SWITCHES)"
(( TEST_RESULT += $? ))


# latency average <= maximum check
../common/check_row_value_sanity_growing.pl "$REGEX_DATA_LINE" < $LOGS_DIR/basic_latency.log
CHECK_EXIT_CODE=$?

print_results 0 $CHECK_EXIT_CODE "sched latency avg <= max check"
(( TEST_RESULT += $? ))


# replay

# easier load, so replay will not last so long
$CMD_PERF sched record -a -o $CURRENT_TEST_DIR/perf.data.new -- $CMD_SIMPLE > $LOGS_DIR/basic_replay_record.log 2> $LOGS_DIR/basic_replay_record.err
PERF_EXIT_CODE=$?

# perf sched replay might hit the casual open fd limits (1024 might be too little)
bump_fd_limit_if_needed

$CMD_PERF sched replay -i $CURRENT_TEST_DIR/perf.data.new > $LOGS_DIR/basic_replay.log 2> $LOGS_DIR/basic_replay.err
(( PERF_EXIT_CODE += $? ))

restore_fd_limit_if_needed

REGEX_RUN_MEAS="run measurement overhead: \d+ nsecs"
REGEX_SLEEP_MEAS="sleep measurement overhead: \d+ nsecs"
REGEX_RUN_TEST="the run test took \d+ nsecs"
REGEX_SLEEP_TEST="the sleep test took \d+ nsecs"
REGEX_RUN_EV="nr_run_events:\s+\d+"
REGEX_SLEEP_EV="nr_sleep_events:\s+\d+"
REGEX_WAKE_EV="nr_wakeup_events:\s+\d+"
REGEX_TARGET_LESS_WAKE="target-less wakeups:  \d+"
REGEX_MULTI_TARGET_WAKE="multi-target wakeups: \d+"
REGEX_RUN_ATOMS="run atoms optimized: \d+"

# above regexes should be stored here
cat $LOGS_DIR/basic_replay.log | grep -v task | grep -A 0 \-{50,} | head -n -1 > $LOGS_DIR/basic_replay_head.log 2> /dev/null
CHECK_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$REGEX_RUN_MEAS" "$REGEX_SLEEP_MEAS" "$REGEX_RUN_TEST" "$REGEX_SLEEP_TEST" "$REGEX_RUN_EV" "$REGEX_SLEEP_EV" "$REGEX_WAKE_EV" "$REGEX_TARGET_LESS_WAKE" "$REGEX_MULTI_TARGET_WAKE" "$REGEX_RUN_ATOMS" < $LOGS_DIR/basic_replay_head.log
(( CHECK_EXIT_CODE += $? ))
../common/check_all_patterns_found.pl "$REGEX_RUN_MEAS" "$REGEX_SLEEP_MEAS" "$REGEX_RUN_TEST" "$REGEX_SLEEP_TEST" "$REGEX_RUN_EV" "$REGEX_SLEEP_EV" "$REGEX_WAKE_EV" < $LOGS_DIR/basic_replay_head.log
(( CHECK_EXIT_CODE += $? ))

REGEX_TASK_LINE="task\s+\d+ \(\s*[\w-\:\. ]+:\s+\d+\), nr_events: \d+"
REGEX_DATA_UNDERLINE="-{50,}"
REGEX_ONE_TEST_LINE="#\d+\s+: $RE_NUMBER, ravg: $RE_NUMBER, cpu: $RE_NUMBER \/ $RE_NUMBER"

# without header
cat $LOGS_DIR/basic_replay.log | grep 'task\|\-\-\-\|#' > $LOGS_DIR/basic_replay_data.log 2> /dev/null
(( CHECK_EXIT_CODE += $? ))

../common/check_all_lines_matched.pl "$REGEX_TASK_LINE" "$REGEX_DATA_UNDERLINE" "$REGEX_ONE_TEST_LINE"  < $LOGS_DIR/basic_replay_data.log
(( CHECK_EXIT_CODE += $? ))
../common/check_all_patterns_found.pl "$REGEX_TASK_LINE" "$REGEX_DATA_UNDERLINE" "$REGEX_ONE_TEST_LINE" < $LOGS_DIR/basic_replay_data.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "sched replay"
(( TEST_RESULT += $? ))

# count check of nr_events
CNT=0
for WHAT in "nr_run_events:" "nr_sleep_events:" "nr_wakeup_events:" "target-less\swakeups:" "multi-target\swakeups:"; do
	(( CNT += `perl -ne 'BEGIN{$n=0;} {$n+=$1 if (/'$WHAT'\s+(\d+)/);} END{print "$n";}' < $LOGS_DIR/basic_replay_head.log` ))
done

NR_EVENTS=`perl -ne 'BEGIN{$n=0;} {$n+=$1 if (/task\s+\d+ \(\s*[\w-\:\. ]+:\s+\d+\), nr_events: (\d+)/);} END{print "$n";}' < $LOGS_DIR/basic_replay.log`

test $CNT -eq $NR_EVENTS
print_results 0 $? "sched replay count check ($CNT == $NR_EVENTS)"
(( TEST_RESULT += $? ))


# script

$CMD_PERF sched script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_sched_script.log 2> $LOGS_DIR/basic_sched_script.err
PERF_EXIT_CODE=$?

$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_script.log 2> $LOGS_DIR/basic_script.err
(( PERF_EXIT_CODE += $? ))

# it is aliased to perf script
cmp $LOGS_DIR/basic_sched_script.log $LOGS_DIR/basic_script.log &> /dev/null
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "sched script"
(( TEST_RESULT += $? ))


# map

$CMD_PERF sched map -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_map.log 2> $LOGS_DIR/basic_map.err
PERF_EXIT_CODE=$?

REGEX_ALL_CPUS_LINE="\s+(?: \.  | \w{2} |    |\*\.  |\*\w{2} )+\s+\d+\.\d+ secs (?:(?:\w{2}|\. ) => [\w\-:\/~ #]+)?"

../common/check_all_lines_matched.pl "$REGEX_ALL_CPUS_LINE" < $LOGS_DIR/basic_map.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_ALL_CPUS_LINE" < $LOGS_DIR/basic_map.log
(( CHECK_EXIT_CODE += $? ))

# --cpu option
$CMD_PERF sched map --cpu 0 -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_map_cpu.log 2> $LOGS_DIR/basic_map_cpu.err
(( PERF_EXIT_CODE += $? ))

REGEX_ONE_CPU_LINE="\s+(?:\.|\w{2})|\*(?:\.|\w{2})\s+\d+\.\d+ secs (?:(?:\. |\w{2}) => [\w\-:\/~ #]+:\d+)?"

../common/check_all_lines_matched.pl "^\s+$" "$REGEX_ONE_CPU_LINE" < $LOGS_DIR/basic_map_cpu.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "sched map"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
