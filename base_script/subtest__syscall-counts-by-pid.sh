#### !!! THIS IS TO BE SOURCED BY test_scripts.sh !!!

### test for syscall-counts-by-pid script

# syscall-counts-by-pid script records all syscalls of a process
# or systemwide and counts numbers of each syscall by command/pid

script="syscall-counts-by-pid"


# record
$CMD_PERF script record $script -o $CURRENT_TEST_DIR/perf.data -- dd if=/dev/zero of=/dev/null bs=1 count=100 2> $LOGS_DIR/script__${script}__record.log
PERF_EXIT_CODE=$?

# note: this script does not produce any record output

print_results $PERF_EXIT_CODE 0 "script $script :: record"
(( TEST_RESULT += $? ))


# report
$CMD_PERF script report $script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/script__${script}__report.log 2> $LOGS_DIR/script__${script}__report.err
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "syscall events by comm/pid:" "comm \[pid\]/syscalls\s+count" < $LOGS_DIR/script__${script}__report.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "^\s+\w+\s+\d+$" < $LOGS_DIR/script__${script}__report.log
(( CHECK_EXIT_CODE += $? ))

if should_support_syscall_translations; then
	../common/check_all_patterns_found.pl "open" "close" "read" "exit" < $LOGS_DIR/script__${script}__report.log
	(( CHECK_EXIT_CODE += $? ))
fi

REGEX_LINE_READWRITE="^\s+\w+\s+1\d\d"
RW_LINE_COUNT=`grep -P "$REGEX_LINE_READWRITE" -c < $LOGS_DIR/script__${script}__report.log`
test $RW_LINE_COUNT -eq 2
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report"
(( TEST_RESULT += $? ))


# syscall count check
N_SAMPLES=`$CMD_PERF report -i $CURRENT_TEST_DIR/perf.data --stdio | perl -ne 'print "$1" if /^#\sSamples:\s(\d+)\s+of\s+event.+raw_syscalls:sys_enter/'`

CNT=`perl -ne 'BEGIN{$n=0;$en=0;}{$n+=$1 if ($en&&/\s+\w+\s+(\d+)/);$en=1 if /^\w+\s\[[0-9]+\]$/;$en=0 if /^\s*$/} END{print "$n";}' < $LOGS_DIR/script__${script}__report.log`
test $CNT -eq $N_SAMPLES
print_results 0 $? "script $script :: syscall count check ($CNT == $N_SAMPLES)"
(( TEST_RESULT += $? ))
