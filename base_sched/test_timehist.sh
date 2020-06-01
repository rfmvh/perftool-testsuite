#!/bin/bash

#
#       test_timehist of perf_sched test
#       Author: Benjamin Salon <bsalon@redhat.com>
#
#       Description:
#
#               This test tests functionality of perf sched timehist command.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


# record
$CMD_PERF sched record -a -o $CURRENT_TEST_DIR/perf.data -- $CMD_BASIC_SLEEP 2> /dev/null
PERF_EXIT_CODE=$?


# no options

$CMD_PERF sched -i $CURRENT_TEST_DIR/perf.data timehist > $LOGS_DIR/timehist_general.log 2> /dev/null
(( PERF_EXIT_CODE += $? ))

REGEX_HEADER_LINE="\s+time\s+cpu\s+task name\s+wait time\s+sch delay\s+run time"
REGEX_HEADER_NOTES="\s+\[tid\/pid\]\s+\(msec\)\s+\(msec\)\s+\(msec\)"
REGEX_HEADER_UNDERLINE="[ -]{75,}"
REGEX_DATA_LINE="\s*$RE_NUMBER\s+\[\d+\]\s+[\w~<>\[\]\/ \+:#-]+\s+$RE_NUMBER\s+$RE_NUMBER\s+$RE_NUMBER"

../common/check_all_lines_matched.pl "$REGEX_HEADER_LINE" "$REGEX_HEADER_NOTES" "$REGEX_HEADER_UNDERLINE" "$REGEX_DATA_LINE" < $LOGS_DIR/timehist_general.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_HEADER_LINE" "$REGEX_HEADER_NOTES" "$REGEX_HEADER_UNDERLINE" "$REGEX_DATA_LINE" < $LOGS_DIR/timehist_general.log

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "no options"
(( TEST_RESULT += $? ))


# --pid and --tid option

# tid and pid can be the same [pidtid] or different [pid/tid]
REGEX_TMP_PERF=`cat $LOGS_DIR/timehist_general.log | grep -o 'perf\[.*\]' | head -n 1`
if echo "$REGEX_TMP_PERF" | grep -q /; then
	REGEX_PERF_PID_TID=`echo "$REGEX_TMP_PERF" | grep -o '[0-9]*\/[0-9]*'`
	REGEX_PERF_PID=`echo "$REGEX_PERF_PID_TID" | grep -o '^[0-9]*'`
	REGEX_PERF_TID=`echo "$REGEX_PERF_PID_TID" | grep -o '[0-9]*$'`
else
	REGEX_PERF_PID=`echo "$REGEX_TMP_PERF" | grep -o [0-9]*`
	REGEX_PERF_TID=$REGEX_PERF_PID
	REGEX_PERF_PID_TID=$REGEX_PERF_PID
fi

REGEX_TMP_SLEEP=`cat $LOGS_DIR/timehist_general.log | grep -o 'sleep\[.*\]' | head -n 1`
if echo "$REGEX_TMP_SLEEP" | grep -q /; then
	REGEX_SLEEP_PID_TID=`echo "$REGEX_TMP_SLEEP" | grep -o '[0-9]*\/[0-9]*'`
	REGEX_SLEEP_PID=`echo "$REGEX_SLEEP_PID_TID" | grep -o '^[0-9]*'`
	REGEX_SLEEP_TID=`echo "$REGEX_SLEEP_PID_TID" | grep -o '[0-9]*$'`
else
	REGEX_SLEEP_PID=`echo "$REGEX_TMP_SLEEP" | grep -o [0-9]*`
	REGEX_SLEEP_TID=$REGEX_SLEEP_PID
	REGEX_SLEEP_PID_TID=$REGEX_SLEEP_PID
fi

REGEX_IDLE_LINE="\s*$RE_NUMBER\s+\[\d+\]\s+<idle>\s+$RE_NUMBER\s+$RE_NUMBER\s+$RE_NUMBER"
REGEX_PERF_LINE="\s*$RE_NUMBER\s+\[\d+\]\s+perf\[$REGEX_PERF_PID_TID\]\s+$RE_NUMBER\s+$RE_NUMBER\s+$RE_NUMBER"
REGEX_SLEEP_LINE="\s*$RE_NUMBER\s+\[\d+\]\s+sleep\[$REGEX_SLEEP_PID_TID\]\s+$RE_NUMBER\s+$RE_NUMBER\s+$RE_NUMBER"

# 0 is pid for idle
$CMD_PERF sched -i $CURRENT_TEST_DIR/perf.data timehist --pid=0,$REGEX_PERF_PID,$REGEX_SLEEP_PID > $LOGS_DIR/timehist_pid.log 2> /dev/null
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$REGEX_HEADER_LINE" "$REGEX_HEADER_NOTES" "$REGEX_HEADER_UNDERLINE" "$REGEX_IDLE_LINE" "$REGEX_PERF_LINE" "$REGEX_SLEEP_LINE" < $LOGS_DIR/timehist_pid.log
CHECK_EXIT_CODE=$?

# 0 is tid for idle
$CMD_PERF sched -i $CURRENT_TEST_DIR/perf.data timehist --tid=0,$REGEX_PERF_TID,$REGEX_SLEEP_TID > $LOGS_DIR/timehist_tid.log 2> /dev/null
(( PERF_EXIT_CODE += $? ))

../common/check_all_patterns_found.pl "$REGEX_HEADER_LINE" "$REGEX_HEADER_NOTES" "$REGEX_HEADER_UNDERLINE" "$REGEX_IDLE_LINE" "$REGEX_PERF_LINE" "$REGEX_SLEEP_LINE" < $LOGS_DIR/timehist_tid.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "--pid and --tid"
(( TEST_RESULT += $? ))


# -s (summary) option

$CMD_PERF sched -i $CURRENT_TEST_DIR/perf.data timehist -s > $LOGS_DIR/timehist_summary.log 2> /dev/null
PERF_EXIT_CODE=$?

REGEX_S_HEADER_LINE="\s+comm\s+parent\s+sched-in\s+run-time\s+min-run\s+avg-run\s+max-run\s+stddev\s+migrations"
REGEX_S_HEADER_NOTES="\s+\(count\)\s+\(msec\)\s+\(msec\)\s+\(msec\)\s+\(msec\)\s+%"
REGEX_S_HEADER_UNDERLINE="-{100,}"
REGEX_S_DATA_LINE="\s+[\w~\/ \+:#-]+(?:\[-1\]|\[\d+(?:\/\d+)?\])\s+(?:-1|\d+)\s+\d+\s+$RE_NUMBER\s+$RE_NUMBER\s+$RE_NUMBER\s+$RE_NUMBER\s+$RE_NUMBER\s+\d+"
REGEX_S_SLEEP_LINE="\s+sleep\[\d+(?:\/\d+)?\]\s+\d+\s+\d+\s+$RE_NUMBER\s+$RE_NUMBER\s+$RE_NUMBER\s+$RE_NUMBER\s+$RE_NUMBER\s+\d+"

REGEX_S_IDLE="\s+CPU\s+\d+ idle for\s+$RE_NUMBER\s+msec\s+\(\s*$RE_NUMBER%\)|\s+CPU\s+\d+\s+idle entire time window"
REGEX_S_UNIQ="\s+Total number of unique tasks: \d+"
REGEX_S_SWITCH="\s*Total number of context switches: \d+"
REGEX_S_RUN_T="\s+Total run time \(msec\):\s+$RE_NUMBER"
REGEX_S_SCHED_T="\s+Total scheduling time \(msec\):\s+$RE_NUMBER\s+\(x\s*\d+\)"

../common/check_all_lines_matched.pl "^\s*$" "Runtime summary" "$REGEX_S_HEADER_LINE" "$REGEX_S_HEADER_NOTES" "$REGEX_S_HEADER_UNDERLINE" "$REGEX_S_DATA_LINE"\
 "Terminated tasks:" "$REGEX_S_SLEEP_LINE" "Idle stats:" "$REGEX_S_IDLE" "$REGEX_S_UNIQ" "$REGEX_S_SWITCH" "$REGEX_S_RUN_T" "$REGEX_S_SCHED_T" < $LOGS_DIR/timehist_summary.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "Runtime summary" "$REGEX_S_HEADER_LINE" "$REGEX_S_HEADER_NOTES" "$REGEX_S_HEADER_UNDERLINE" "$REGEX_S_DATA_LINE" "Terminated tasks:" "Idle stats:"\
 "$REGEX_S_IDLE" "$REGEX_S_UNIQ" "$REGEX_S_SWITCH" "$REGEX_S_RUN_T" "$REGEX_S_SCHED_T" < $LOGS_DIR/timehist_summary.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "--summary"
(( TEST_RESULT += $? ))


# unique tasks count check
UNIQUE_TASKS=`perl -ne 'BEGIN{$n=0;} {$n=$1 if (/\s+Total number of unique tasks: (\d+)/)} END{print "$n";}' < $LOGS_DIR/timehist_summary.log`
CNT=`perl -ne 'BEGIN{$n=0;} {$n+=1 if (/\s+[\w~\/ \+:#-]+(?:\[-1\]|\[\d+(?:\/\d+)?\])\s+(?:-1|\d+)\s+\d+\s+[\d\.]+\s+[\d\.]+\s+[\d\.]+\s+[\d\.]+\s+[\d\.]+\s+\d+/);} END{print "$n";}' < $LOGS_DIR/timehist_summary.log`

test $UNIQUE_TASKS -eq $CNT
print_results 0 $? "--summary unique tasks count check ($UNIQUE_TASKS == $CNT)"
(( TEST_RESULT += $? ))

# min <= avg <= max <= total runtime compare check
CHECK_EXIT_CODE=`perl -ne 'BEGIN{$n=0;} {$n+=1 if (/\s+[\w~\/ \+:#-]+(?:\[-1\]|\[\d+(?:\/\d+)?\])\s+(?:-1|\d+)\s+\d+\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)\s+[\d\.]+\s+\d+/ and ($2 > $3 or $3 > $4 or $4 > $1));} END{print "$n";}' < $LOGS_DIR/timehist_summary.log`

print_results 0 $CHECK_EXIT_CODE "--summary runtime inequalities check ($CHECK_EXIT_CODE wrong inequalities)"
(( TEST_RESULT += $? ))


# -S (with summary) option

$CMD_PERF sched -i $CURRENT_TEST_DIR/perf.data timehist -S > $LOGS_DIR/timehist_with-summary.log 2> /dev/null
PERF_EXIT_CODE=$?

# should be the same as with -s option
grep -B 1 -A `wc -l < $LOGS_DIR/timehist_with-summary.log` 'Runtime summary' < $LOGS_DIR/timehist_with-summary.log > $LOGS_DIR/timehist_with-summary_summ.log 2> /dev/null
CHECK_EXIT_CODE=$?

# should be the same as with no options
grep -B `wc -l < $LOGS_DIR/timehist_with-summary.log` 'Runtime summary' < $LOGS_DIR/timehist_with-summary.log | head -n -2 > $LOGS_DIR/timehist_with-summary_all.log 2> /dev/null
(( CHECK_EXIT_CODE += $? ))

cmp $LOGS_DIR/timehist_summary.log $LOGS_DIR/timehist_with-summary_summ.log &> /dev/null
(( CHECK_EXIT_CODE += $? ))

cmp $LOGS_DIR/timehist_general.log $LOGS_DIR/timehist_with-summary_all.log &> /dev/null
(( CHECK_EXIT_CODE += $? ))

../common/check_all_patterns_found.pl "$REGEX_HEADER_LINE" "$REGEX_HEADER_NOTES" "$REGEX_HEADER_UNDERLINE" "$REGEX_DATA_LINE" "$REGEX_S_HEADER_LINE" "$REGEX_S_HEADER_NOTES" "$REGEX_S_HEADER_UNDERLINE" "$REGEX_S_DATA_LINE"\
 "Terminated tasks:" "Idle stats:" "$REGEX_S_IDLE" "$REGEX_S_UNIQ" "$REGEX_S_SWITCH" "$REGEX_S_RUN_T" "$REGEX_S_SCHED_T" < $LOGS_DIR/timehist_with-summary.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "--with-summary"
(( TEST_RESULT += $? ))


# -V (visual cpu) option

$CMD_PERF sched -i $CURRENT_TEST_DIR/perf.data timehist -V > $LOGS_DIR/timehist_visual.log 2> /dev/null
PERF_EXIT_CODE=$?

REGEX_V_HEADER_LINE="\s*time\s+cpu\s+[\da-f]+\s+task name\s+wait time\s+sch delay\s+run time"
REGEX_V_DATA_LINE="\s*$RE_NUMBER\s+\[\d+\]\s+s\s+[\w~\[\]\/ \+:#-]+\s+$RE_NUMBER\s+$RE_NUMBER\s+$RE_NUMBER"
REGEX_V_IDLE_LINE="\s*$RE_NUMBER\s+\[\d+\]\s+i\s+<idle>\s+$RE_NUMBER\s+$RE_NUMBER\s+$RE_NUMBER"

../common/check_all_lines_matched.pl "^\s*$" "$REGEX_V_HEADER_LINE" "$REGEX_HEADER_NOTES" "$REGEX_HEADER_UNDERLINE" "$REGEX_V_DATA_LINE" "$REGEX_V_IDLE_LINE" < $LOGS_DIR/timehist_visual.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_V_HEADER_LINE" "$REGEX_HEADER_NOTES" "$REGEX_HEADER_UNDERLINE" "$REGEX_V_DATA_LINE" "$REGEX_V_IDLE_LINE" < $LOGS_DIR/timehist_visual.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "--visual-cpu"
(( TEST_RESULT += $? ))


# -w (wakeups) option

$CMD_PERF sched -i $CURRENT_TEST_DIR/perf.data timehist -w > $LOGS_DIR/timehist_wakeups.log 2> /dev/null
PERF_EXIT_CODE=$?

REGEX_W_AWAKENED_LINE="\s*$RE_NUMBER\s+\[\d+\]\s+[\w~\[\]\/ \+:#-]+\s+awakened: [\w~\[\]\/ \+:#-]+"

../common/check_all_lines_matched.pl "^\s*$" "$REGEX_HEADER_LINE" "$REGEX_HEADER_NOTES" "$REGEX_HEADER_UNDERLINE" "$REGEX_DATA_LINE" "$REGEX_W_AWAKENED_LINE" < $LOGS_DIR/timehist_wakeups.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_HEADER_LINE" "$REGEX_HEADER_NOTES" "$REGEX_HEADER_UNDERLINE" "$REGEX_DATA_LINE" < $LOGS_DIR/timehist_wakeups.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "--wakeups"
(( TEST_RESULT += $? ))


# -M (migrations) option

$CMD_PERF sched -i $CURRENT_TEST_DIR/perf.data timehist -M > $LOGS_DIR/timehist_migration.log 2> /dev/null
PERF_EXIT_CODE=$?

REGEX_M_MIGRATED_LINE="\s*$RE_NUMBER\s+\[\d+\]\s+[\w~\[\]\/ \+:#-]+\s+migrated: [\w~\[\]\/ \+:#-]+"

../common/check_all_lines_matched.pl "^\s*$" "$REGEX_HEADER_LINE" "$REGEX_HEADER_NOTES" "$REGEX_HEADER_UNDERLINE" "$REGEX_DATA_LINE" "$REGEX_M_MIGRATED_LINE" < $LOGS_DIR/timehist_migration.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_HEADER_LINE" "$REGEX_HEADER_NOTES" "$REGEX_HEADER_UNDERLINE" "$REGEX_DATA_LINE" < $LOGS_DIR/timehist_migration.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "--migration"
(( TEST_RESULT += $? ))


# -n (next) option

$CMD_PERF sched -i $CURRENT_TEST_DIR/perf.data timehist -n > $LOGS_DIR/timehist_next.log 2> /dev/null
PERF_EXIT_CODE=$?

REGEX_N_NEXT_LINE="\s*$RE_NUMBER\s+\[\d+\]\s+[\w~\[\]\/ \+:#-]+\s+next: [\w~\[\]\/ \+:#-]+"

../common/check_all_lines_matched.pl "^\s*$" "$REGEX_HEADER_LINE" "$REGEX_HEADER_NOTES" "$REGEX_HEADER_UNDERLINE" "$REGEX_DATA_LINE" "$REGEX_N_NEXT_LINE" < $LOGS_DIR/timehist_next.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_HEADER_LINE" "$REGEX_HEADER_NOTES" "$REGEX_HEADER_UNDERLINE" "$REGEX_DATA_LINE" < $LOGS_DIR/timehist_next.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "--next"
(( TEST_RESULT += $? ))


# -I (idle hist) option

$CMD_PERF sched -i $CURRENT_TEST_DIR/perf.data timehist -I > $LOGS_DIR/timehist_idle-hist.log 2> /dev/null
PERF_EXIT_CODE=$?

REGEX_I_DATA_LINE="\s*$RE_NUMBER\s+\[\d+\]\s+[\w~\[\]\/ \+:#-]+\s+[0\.]+\s+[0\.]+\s+[0\.]+"
REGEX_I_IDLE_LINE="\s*$RE_NUMBER\s+\[\d+\]\s+<idle>\s+$RE_NUMBER\s+$RE_NUMBER\s+$RE_NUMBER"

../common/check_all_lines_matched.pl "^\s*$" "$REGEX_HEADER_LINE" "$REGEX_HEADER_NOTES" "$REGEX_HEADER_UNDERLINE" "$REGEX_I_DATA_LINE" "$REGEX_I_IDLE_LINE" < $LOGS_DIR/timehist_idle-hist.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_HEADER_LINE" "$REGEX_HEADER_NOTES" "$REGEX_HEADER_UNDERLINE" "$REGEX_DATA_LINE" < $LOGS_DIR/timehist_idle-hist.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "--idle-hist"
(( TEST_RESULT += $? ))


# --state option

$CMD_PERF sched -i $CURRENT_TEST_DIR/perf.data timehist --state > $LOGS_DIR/timehist_state.log 2> /dev/null
PERF_EXIT_CODE=$?

REGEX_ST_HEADER_LINE="$REGEX_HEADER_LINE\s+state"

REGEX_ST_DATA_LINE="\s*$RE_NUMBER\s+\[\d+\]\s+[\w~\[\]\/ \+:#-]+\s+$RE_NUMBER\s+$RE_NUMBER\s+$RE_NUMBER\s+[RSDTtZXxKWP]"
REGEX_ST_IDLE_LINE="\s*$RE_NUMBER\s+\[\d+\]\s+<idle>\s+$RE_NUMBER\s+$RE_NUMBER\s+$RE_NUMBER\s+I"

../common/check_all_lines_matched.pl "$REGEX_ST_HEADER_LINE" "$REGEX_HEADER_NOTES" "$REGEX_HEADER_UNDERLINE" "$REGEX_ST_DATA_LINE" "$REGEX_ST_IDLE_LINE" < $LOGS_DIR/timehist_state.log
CHECK_EXIT_CODE=$?

REGEX_ST_SLEEP_LINE="\s*$RE_NUMBER\s+\[\d+\]\s+sleep\[\d+\]\s+$RE_NUMBER\s+$RE_NUMBER\s+$RE_NUMBER\s+[Xx]"
../common/check_all_patterns_found.pl "$REGEX_ST_SLEEP_LINE" < $LOGS_DIR/timehist_state.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "--state"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
