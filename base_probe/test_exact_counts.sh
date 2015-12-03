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
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

check_uprobes_available
if [ $? -ne 0 ]; then
	print_overall_skipped
	exit 0
fi

# clean up before we start
clear_all_probes
find . -name perf.data\* | xargs -r rm


### adding userspace probes

PERF_EXIT_CODE=0
test -e exact_counts_add.log && rm -f exact_counts_add.log
for i in 1 2 3 103 997 65535; do
	$CMD_PERF probe -x examples/exact_counts --add f_${i}x >> exact_counts_add.log 2>&1
	(( PERF_EXIT_CODE += $? ))
done

../common/check_all_patterns_found.pl "probe_exact:f_1x" "probe_exact:f_2x" "probe_exact:f_3x" "probe_exact:f_103x" \
		"probe_exact:f_997x" "probe_exact:f_65535x" < exact_counts_add.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "adding userspace probes"
(( TEST_RESULT += $? ))


### listing added probes

$CMD_PERF probe -l > exact_counts_list.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "probe_exact:f_1x" "probe_exact:f_2x" "probe_exact:f_3x" "probe_exact:f_103x" \
		"probe_exact:f_997x" "probe_exact:f_65535x" < exact_counts_list.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "listing added probes"
(( TEST_RESULT += $? ))


### using probes :: perf stat

# perf stat should catch all the events and give exact results
$CMD_PERF stat -x';' -e 'probe_exact:*' examples/exact_counts 2> exact_counts_stat.log
PERF_EXIT_CODE=$?

# check for exact values in perf stat results
../common/check_all_lines_matched.pl "(\d+);+probe_exact:f_\1x" < exact_counts_stat.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "using probes :: perf stat"
(( TEST_RESULT += $? ))


### using probes :: perf record

# perf record should catch all the samples as well
$CMD_PERF record -e 'probe_exact:*' examples/exact_counts 2> exact_counts_record.log
PERF_EXIT_CODE=$?

# perf record should catch exactly 66641 samples
../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "66641 samples" < exact_counts_record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "using probes :: perf record"
(( TEST_RESULT += $? ))

# perf report should report exact values too
$CMD_PERF report --stdio -n > exact_counts_report.log
PERF_EXIT_CODE=$?

# perf report should report exact sample counts
../common/check_all_lines_matched.pl "\s*100.00%\s+(\d+)\s+exact_counts\s+exact_counts\s+\[\.\]\s+f_\1x" "$RE_LINE_EMPTY" "$RE_LINE_COMMENT" < exact_counts_report.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "using probes :: perf report"
(( TEST_RESULT += $? ))


clear_all_probes


# print overall resutls
print_overall_results "$TEST_RESULT"
exit $?
