#!/bin/bash

#
#	test_addresses of perf_mem test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests --phys-data and --data options of perf record.
#	While --data can be used with normal events, --phys-data works with
#	memory events only.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

# skip the testcase if there are no suitable events to be used
if [ "$MEM_LOADS_SUPPORTED" = "no" -a "$MEM_STORES_SUPPORTED" = "no" ]; then
	print_overall_skipped
	exit 0
fi


### record --data --phys-data

# test that perf mem record can record virtual and physical addresses along with samples
$CMD_PERF mem record --data --phys-data -o $CURRENT_TEST_DIR/perf.data examples/dummy > /dev/null 2> $LOGS_DIR/addresses_record.err
PERF_EXIT_CODE=$?

# check the perf mem record output
../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/addresses_record.err
CHECK_EXIT_CODE=$?
../common/check_errors_whitelisted.pl "stderr-whitelist.txt" < $LOGS_DIR/addresses_record.err
(( CHECK_EXIT_CODE += $? ))
SAMPLE_COUNT=`perl -ne 'BEGIN{$s=0;}{($s)=$1 if /(\d+)\s+samples/}END{print "$s";}' < $LOGS_DIR/addresses_record.err`
test $SAMPLE_COUNT -gt 0
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "record --data --phys-data"
(( TEST_RESULT += $? ))


### report check

# we need to check, whether each sample has data (virtual address) entry
$CMD_PERF report -i $CURRENT_TEST_DIR/perf.data -D > $LOGS_DIR/addresses_report.log 2> $LOGS_DIR/addresses_report.err
PERF_EXIT_CODE=$?

# check the events used
../common/check_all_patterns_found.pl "PERF_RECORD_SAMPLE" "data_src" "phys_addr" "dummy" < $LOGS_DIR/addresses_report.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "report check"
(( TEST_RESULT += $? ))


### sample check

# are there enough samples
grep "PERF_RECORD_SAMPLE" $LOGS_DIR/addresses_report.log > $LOGS_DIR/addresses_report_samples.log
GREP_EXIT_CODE=$?

# check sample lines sanity
REGEX_PERF_RECORD_SAMPLE="$RE_NUMBER\s+$RE_ADDRESS_NOT_NULL\s+\[$RE_ADDRESS_NOT_NULL\]:\s+PERF_RECORD_SAMPLE\(IP,\s+$RE_ADDRESS_NOT_NULL\):\s+$RE_NUMBER\/$RE_NUMBER:\s+$RE_ADDRESS_NOT_NULL\s+period:\s+$RE_NUMBER\s+addr:\s+$RE_ADDRESS_NOT_NULL"
REGEX_PERF_RECORD_SAMPLE_INCOMPLETE="$RE_NUMBER\s+$RE_ADDRESS_NOT_NULL\s+\[$RE_ADDRESS_NOT_NULL\]:\s+PERF_RECORD_SAMPLE\(IP,\s+$RE_ADDRESS_NOT_NULL\):\s+$RE_NUMBER\/$RE_NUMBER:\s+(?:$RE_ADDRESS_NOT_NULL|0)\s+period:\s+$RE_NUMBER\s+addr:\s+0$"

../common/check_all_lines_matched.pl "$REGEX_PERF_RECORD_SAMPLE" "$REGEX_PERF_RECORD_SAMPLE_INCOMPLETE" < $LOGS_DIR/addresses_report_samples.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_PERF_RECORD_SAMPLE" < $LOGS_DIR/addresses_report_samples.log
(( CHECK_EXIT_CODE += $? ))

INCOMPLETE_SAMPLES=`grep -P "$REGEX_PERF_RECORD_SAMPLE_INCOMPLETE" $LOGS_DIR/addresses_report_samples.log | wc -l`
MAX_INCOMPLETE_SAMPLES=$(( $SAMPLE_COUNT / 100 ))

echo $INCOMPLETE_SAMPLES $MAX_INCOMPLETE_SAMPLES

# count check of incomplete samples
test $INCOMPLETE_SAMPLES -le $MAX_INCOMPLETE_SAMPLES
(( CHECK_EXIT_CODE += $? ))

# check sample lines count
test $SAMPLE_COUNT -eq `wc -l < $LOGS_DIR/addresses_report_samples.log`
(( CHECK_EXIT_CODE += $? ))

print_results $GREP_EXIT_CODE $CHECK_EXIT_CODE "sample check"
(( TEST_RESULT += $? ))


### data_src check

grep "data_src" $LOGS_DIR/addresses_report.log > $LOGS_DIR/addresses_report_data.log
GREP_EXIT_CODE=$?

# check data_src lines sanity
REGEX_DATA_SRC="\s*\.+\s*data_src:\s$RE_ADDRESS_NOT_NULL"
../common/check_all_lines_matched.pl "$REGEX_DATA_SRC" < $LOGS_DIR/addresses_report_data.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_DATA_SRC" < $LOGS_DIR/addresses_report_data.log
(( CHECK_EXIT_CODE += $? ))

# check data_src lines count
test $SAMPLE_COUNT -eq `wc -l < $LOGS_DIR/addresses_report_data.log`
(( CHECK_EXIT_CODE += $? ))

print_results $GREP_EXIT_CODE $CHECK_EXIT_CODE "data_src check"
(( TEST_RESULT += $? ))


### phys_addr

grep "phys_addr" $LOGS_DIR/addresses_report.log > $LOGS_DIR/addresses_report_physdata.log
GREP_EXIT_CODE=$?

# check phys_addr lines sanity
REGEX_PHYSDATA_SRC="\s*\.+\s*phys_addr:\s$RE_ADDRESS"
../common/check_all_lines_matched.pl "$REGEX_PHYSDATA_SRC" < $LOGS_DIR/addresses_report_physdata.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_PHYSDATA_SRC" < $LOGS_DIR/addresses_report_physdata.log
(( CHECK_EXIT_CODE += $? ))

# check data_src lines count
test $SAMPLE_COUNT -eq `wc -l < $LOGS_DIR/addresses_report_physdata.log`
(( CHECK_EXIT_CODE += $? ))

print_results $GREP_EXIT_CODE $CHECK_EXIT_CODE "phys_addr check"
(( TEST_RESULT += $? ))


### print overall results
print_overall_results "$TEST_RESULT"
exit $?
