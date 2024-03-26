#!/bin/bash

#
#	test_exact_counts of perf_probe test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This testcase checks, whether the perf-stat catches all
#	the probes with exactly known counts of function calls.
#
#

# include working environment
. ../common/init.sh

TEST_RESULT=0

check_uprobes_available
if [ $? -ne 0 ]; then
	print_overall_skipped
	exit 0
fi

# clean up before we start
clear_all_probes
find . -name perf.data\* -print0 | xargs -0 -r rm


### adding userspace probes

PERF_EXIT_CODE=0
test -e $LOGS_DIR/exact_counts_add.log && rm -f $LOGS_DIR/exact_counts_add.log
for i in 1 2 3 103 997 65535; do
	$CMD_PERF probe -x $CURRENT_TEST_DIR/examples/exact_counts --add f_${i}x >> $LOGS_DIR/exact_counts_add.log 2>&1
	(( PERF_EXIT_CODE += $? ))
done

../common/check_all_patterns_found.pl "probe_exact\w*:f_1x" "probe_exact\w*:f_2x" "probe_exact\w*:f_3x" "probe_exact\w*:f_103x" \
		"probe_exact\w*:f_997x" "probe_exact\w*:f_65535x" < $LOGS_DIR/exact_counts_add.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "adding userspace probes"
(( TEST_RESULT += $? ))


### listing added probes

$CMD_PERF probe -l > $LOGS_DIR/exact_counts_list.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "probe_exact\w*:f_1x" "probe_exact\w*:f_2x" "probe_exact\w*:f_3x" "probe_exact\w*:f_103x" \
		"probe_exact\w*:f_997x" "probe_exact\w*:f_65535x" < $LOGS_DIR/exact_counts_list.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "listing added probes"
(( TEST_RESULT += $? ))


### using probes :: perf stat

# perf stat should catch all the events and give exact results
PROBE_PREFIX=`head -n 1 $LOGS_DIR/exact_counts_list.log | perl -ne 'print "$1" if /\s+(\w+):/'`
$CMD_PERF stat -x';' -e "$PROBE_PREFIX:"'*' $CURRENT_TEST_DIR/examples/exact_counts 2> $LOGS_DIR/exact_counts_stat.log
PERF_EXIT_CODE=$?

# check for exact values in perf stat results
../common/check_all_lines_matched.pl "(\d+);+$PROBE_PREFIX:f_\1x" < $LOGS_DIR/exact_counts_stat.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "using probes :: perf stat"
(( TEST_RESULT += $? ))


### using probes :: perf record

# perf record should catch all the samples as well
$CMD_PERF record -m 16M -e "$PROBE_PREFIX:"'*' -o $CURRENT_TEST_DIR/perf.data $CURRENT_TEST_DIR/examples/exact_counts 2> $LOGS_DIR/exact_counts_record.log
PERF_EXIT_CODE=$?

# perf record should catch exactly 66641 samples
../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "66641 samples" < $LOGS_DIR/exact_counts_record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "using probes :: perf record"
(( TEST_RESULT += $? ))

# perf report should report exact values too
$CMD_PERF report -s comm,dso,symbol --stdio -i $CURRENT_TEST_DIR/perf.data -n > $LOGS_DIR/exact_counts_report.log 2> $LOGS_DIR/exact_counts_report.err
PERF_EXIT_CODE=$?

test $TESTLOG_VERBOSITY -ge 2 && cat $LOGS_DIR/exact_counts_report.err
# perf report should report exact sample counts
../common/check_all_lines_matched.pl "\s*100.00%\s+(\d+)\s+exact_counts\s+exact_counts\s+\[\.\]\s+f_\1x" "$RE_LINE_EMPTY" "$RE_LINE_COMMENT" < $LOGS_DIR/exact_counts_report.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "using probes :: perf report"
(( TEST_RESULT += $? ))


clear_all_probes


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
