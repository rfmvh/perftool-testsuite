#!/bin/bash

$CMD_DOUBLE_LONGER_SLEEP &
exec $CMD_PERF stat -a -e cpu-clock -I100 -- $CMD_LONGER_SLEEP 2> $LOGS_DIR/endless_wait.log
