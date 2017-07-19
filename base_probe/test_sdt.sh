#!/bin/bash

#
#	test_sdt of perf_probe test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This is a basic testcase covering SDT events.
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

check_uprobes_available
if [ $? -ne 0 ]; then
	print_overall_skipped
	exit 0
fi

check_sdt_support
if [ $? -ne 0 ]; then
	print_overall_skipped
	exit 0
fi


# FIXME -- experimental (this test is testing libpthread SDT tracepoints)
PTHREAD_LIBRARY=`$CMD_PERF probe --cache --list | grep -o -P '^/.+libpthread.+\.so'`
EVENTS_TO_TEST=`$CMD_PERF probe --cache --list | grep sdt_libpthread:pthread_ | perl -pe 's/\n/ /' | perl -pe 's/\s+$//'`
NO_OF_EVENTS_TO_TEST=`$CMD_PERF probe --cache --list | grep -c sdt_libpthread:pthread_`

if [ -z "$PTHREAD_LIBRARY" -o -z "$EVENTS_TO_TEST" ]; then
	# nothing to test, maybe this should be rather a skip, FIXME
	print_results 0 1 "NOTHING TO TEST"
	(( TEST_RESULT += $? ))
	print_overall_results "$TEST_RESULT"
	exit $?
fi


# clean up before we start
clear_all_probes
find . -name perf.data\* | xargs -r rm


### adding SDT tracepoints as probes

# perf probe should add all the SDT tracepoints as probes
$CMD_PERF probe -x $PTHREAD_LIBRARY `echo " $EVENTS_TO_TEST" | perl -pe 's/ / -a /g'` 2> $LOGS_DIR/sdt_adding_probes.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl `echo $EVENTS_TO_TEST | perl -pe 's/:[^=]+=/:/g'` < $LOGS_DIR/sdt_adding_probes.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "adding SDT tracepoints as probes"
(( TEST_RESULT += $? ))


### listing added probes

$CMD_PERF probe -l > $LOGS_DIR/sdt_list.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl `echo $EVENTS_TO_TEST | perl -pe 's/:[^=]+=/:/g'` < $LOGS_DIR/sdt_list.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "listing added probes"
(( TEST_RESULT += $? ))


PROBE_PREFIX=`head -n 1 $LOGS_DIR/sdt_list.log | perl -ne 'print "$1" if /\s+(\w+):/'`


### using probes :: perf stat

for N in 13 128 241; do
	# perf stat should catch all the events and give exact results
	$CMD_PERF stat -x';' -e "$PROBE_PREFIX:"'*' $CURRENT_TEST_DIR/examples/simple_threads $N > $LOGS_DIR/sdt_stat_$N.out 2> $LOGS_DIR/sdt_stat_$N.log
	PERF_EXIT_CODE=$?

	# check for exact values in perf stat results
	../common/check_all_lines_matched.pl "$N;+$PROBE_PREFIX:pthread_" < $LOGS_DIR/sdt_stat_$N.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "using probes :: perf stat (N = $N)"
	(( TEST_RESULT += $? ))
done

### using probes :: perf record

REGEX_SCRIPT_LINE="\s*simple_threads\s+$RE_NUMBER\s+\[$RE_NUMBER\]\s+$RE_NUMBER:\s+sdt_libpthread:pthread_\w+:\s+\($RE_NUMBER_HEX\)"
for N in 37 97 237; do
	# perf record should catch all the samples as well
	$CMD_PERF record -m 16M -e "$PROBE_PREFIX:"'*' -o $CURRENT_TEST_DIR/perf.data $CURRENT_TEST_DIR/examples/simple_threads $N > $LOGS_DIR/sdt_record_$N.out 2> $LOGS_DIR/sdt_record_$N.log
	PERF_EXIT_CODE=$?

	# perf record should catch exactly ($N * $NO_OF_EVENTS_TO_TEST) samples
	EXPECTED_SAMPLES=$(( N * NO_OF_EVENTS_TO_TEST ))
	../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "$EXPECTED_SAMPLES samples" < $LOGS_DIR/sdt_record_$N.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "using probes :: perf record (N = $N)"
	(( TEST_RESULT += $? ))

	# perf report should report exact values too
	$CMD_PERF report -s comm,symbol --stdio -i $CURRENT_TEST_DIR/perf.data -n > $LOGS_DIR/sdt_report_$N.log 2> $LOGS_DIR/sdt_report_$N.err
	PERF_EXIT_CODE=$?

	test $TESTLOG_VERBOSITY -ge 2 && cat $LOGS_DIR/sdt_report_$N.err
	# perf report should report exact sample counts
	../common/check_all_lines_matched.pl "\s*100.00%\s+$N\s+simple_threads\s+\[\.\]\s+.*thread.*" "$RE_LINE_EMPTY" "$RE_LINE_COMMENT" < $LOGS_DIR/sdt_report_$N.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "using probes :: perf report (N = $N)"
	(( TEST_RESULT += $? ))

	# perf script should report exact values too
	$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/sdt_script_$N.log 2> $LOGS_DIR/sdt_script_$N.err
	PERF_EXIT_CODE=$?

	# perf script should report exact sample counts
	../common/check_all_lines_matched.pl `echo $EVENTS_TO_TEST | perl -pe 's/:[^=]+=/:/g'` < $LOGS_DIR/sdt_script_$N.log
	CHECK_EXIT_CODE=$?
	../common/check_all_lines_matched.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/sdt_script_$N.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "using probes :: perf script (N = $N)"
	(( TEST_RESULT += $? ))
done

clear_all_probes


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
