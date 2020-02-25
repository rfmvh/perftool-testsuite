#### !!! THIS IS TO BE SOURCED BY test_scripts.sh !!!

### test for netdev-times

# netdev-times display a process of packet and proecessing time,
# it helps up to investigate networking or network device

script="netdev-times"


# record
$CMD_PERF script record $script -o $CURRENT_TEST_DIR/perf.data -- ping -c 10 -i 0.01 127.0.0.1 > /dev/null 2> $LOGS_DIR/script__${script}__record.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/script__${script}__record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE 0 "script $script :: record"
(( TEST_RESULT += $? ))


# report
$CMD_PERF script report $script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/script__${script}__report.log 2> $LOGS_DIR/script__${script}__report.err
PERF_EXIT_CODE=$?

REGEX_HEADER_LINE="\s+dev\s+len\s+Qdisc\s+netdevice\s+free"

../common/check_all_patterns_found.pl "$REGEX_HEADER_LINE" < $LOGS_DIR/script__${script}__report.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report"
(( TEST_RESULT += $? ))


# sample count check
N_SAMPLES=`perl -ne 'print "$1" if /\((\d+) samples\)/' $LOGS_DIR/script__${script}__record.log`

CNT=`$CMD_PERF report -i $CURRENT_TEST_DIR/perf.data --stdio | perl -ne 'BEGIN{$n=0;}{$n+=$1 if (/# Samples:\s+(\d+)\s+of\s+event.*/)} END{print "$n";}'`

test $CNT -eq $N_SAMPLES
print_results 0 $? "script $script :: sample count check ($CNT == $N_SAMPLES)"
(( TEST_RESULT += $? ))
