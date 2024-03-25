#!/bin/bash

#
#	test_control_pipe of perf_record test
#	Author: Ziqian SUN <zsun@redhat.com>
#
#	Description:
#
#		This test tries to control perf event using the control pipe.
#
#

# include working environment
. ../common/init.sh

TEST_RESULT=0

consider_skipping $RUNMODE_EXPERIMENTAL

#### Create and read the controle pipe
mkfifo control ack perf.pipe
$CMD_PERF record --control=fifo:control,ack -D -1 --no-buffering -e 'sched:*' -o - > perf.pipe 2> $LOGS_DIR/control_pipe_record.log &
PERF_PIPE_PID=$!

#### Consume the pipe

cat perf.pipe | $CMD_PERF --no-pager script -i - > $LOGS_DIR/control_pipe_script.log 2> $LOGS_DIR/control_pipe_script.err &
PERF_SCRIPT_PID=$!

echo 'enable sched:sched_process_fork' > control
$CMD_DOUBLE_LONGER_SLEEP
echo 'enable sched:sched_wakeup_new' > control
$CMD_DOUBLE_LONGER_SLEEP
echo > control

kill -SIGINT $PERF_PIPE_PID &> $LOGS_DIR/control_pipe_kill.log
PERF_EXIT_CODE=$?
! wait $PERF_PIPE_PID
(( PERF_EXIT_CODE += $? ))

kill -SIGINT $PERF_SCRIPT_PID &> $LOGS_DIR/control_pipe_script_kill.log
! wait $PERF_PIPE_PID

../common/check_all_patterns_found.pl "sched:sched_process_fork" "sched:sched_wakeup_new" < $LOGS_DIR/control_pipe_record.log
CHECK_EXIT_CODE=$?

../common/check_all_patterns_found.pl "sched:sched_process_fork" "sched:sched_wakeup_new" < $LOGS_DIR/control_pipe_script.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "control pipe"
(( TEST_RESULT += $? ))

rm -rf control ack perf.pipe

# print overall results
print_overall_results "$TEST_RESULT"
exit $?
