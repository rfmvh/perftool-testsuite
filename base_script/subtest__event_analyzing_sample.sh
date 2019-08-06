#### !!! THIS IS TO BE SOURCED BY test_scripts.sh !!!

### test for event_analyzing_sample script

# event_analyzing_sample script should print histograms from perf.data sample file
# and show them per command, dso and symbol

script="event_analyzing_sample"

# clean-up
DBFILE="/dev/shm/perf.db"
test -f $DBFILE && rm -f $DBFILE


# record
$CMD_PERF script record $script -a -o $CURRENT_TEST_DIR/perf.data -- $CMD_BASIC_SLEEP 2> $LOGS_DIR/script__${script}__record.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/script__${script}__record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: record"
(( TEST_RESULT += $? ))


# report
$CMD_PERF script report $script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/script__${script}__report.log 2> $LOGS_DIR/script__${script}__report.err
PERF_EXIT_CODE=$?

REGEX_HEADER_COMM="comm\s+number\s+histogram"
REGEX_HEADER_SYMBOL="\s*symbol\s+number\s+histogram"
REGEX_HEADER_DSO="\s*dso\s+number\s+histogram"
REGEX_HEADER_UNDERLINE="={50,}"
REGEX_HISTO_LINE="\s*[\w\-:\[\]]+\s+$RE_NUMBER\s+#+"

../common/check_all_patterns_found.pl "$REGEX_HEADER_COMM" "$REGEX_HEADER_SYMBOL" "$REGEX_HEADER_DSO" "$REGEX_HEADER_UNDERLINE" < $LOGS_DIR/script__${script}__report.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_HISTO_LINE" < $LOGS_DIR/script__${script}__report.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script $script :: report"
(( TEST_RESULT += $? ))


# sample count check
N_SAMPLES=`perl -ne 'print "$1" if /\((\d+) samples\)/' $LOGS_DIR/script__${script}__record.log`

for WHAT in "dso" "comm" "symbol"; do
	CNT=`perl -ne 'BEGIN{$n=0;$en=0;}{$n+=$1 if ($en&&/\s*\S+\s+(\d+)\s+#+/);$en=1 if /^\s+'$WHAT'\s+number\s+histogram/;$en=0 if /^\s*$/} END{print "$n";}' < $LOGS_DIR/script__${script}__report.log`
	test $CNT -eq $N_SAMPLES
	print_results 0 $? "script $script :: sample count check for $WHAT ($CNT == $N_SAMPLES)"
	(( TEST_RESULT += $? ))
done

