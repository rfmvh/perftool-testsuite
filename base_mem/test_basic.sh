#!/bin/bash

#
#	test_basic of perf_mem test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf mem command.
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


### help message

if [ "$PARAM_GENERAL_HELP_TEXT_CHECK" = "y" ]; then
	# test that a help message is shown and looks reasonable
	$CMD_PERF mem --help > $LOGS_DIR/basic_helpmsg.log 2> $LOGS_DIR/basic_helpmsg.err
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "PERF-MEM" "NAME" "SYNOPSIS" "DESCRIPTION" "OPTIONS" "SEE ALSO" < $LOGS_DIR/basic_helpmsg.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "command" "type" "dump-raw-samples" "field-separator" "cpu" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "perf mem record" "perf mem report" "dump" "raw samples" "delay" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_no_patterns_found.pl "No manual entry for" < $LOGS_DIR/basic_helpmsg.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "help message"
fi


### loads record, loads event check, loads report

if [ "$MEM_LOADS_SUPPORTED" = "yes" ]; then
	### loads record

	# test that perf mem record can record mem-loads
	$CMD_PERF mem -t load record -o $CURRENT_TEST_DIR/perf.data examples/dummy > /dev/null 2> $LOGS_DIR/basic_loads_record.err
	PERF_EXIT_CODE=$?

	# check the perf mem record output
	../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/basic_loads_record.err
	CHECK_EXIT_CODE=$?
	../common/check_errors_whitelisted.pl "stderr-whitelist.txt" < $LOGS_DIR/basic_loads_record.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "loads record"
	(( TEST_RESULT += $? ))


	### loads event check

	# we need to check, whether the correct event has been used
	$CMD_PERF evlist -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_loads_evlist.log 2> $LOGS_DIR/basic_loads_evlist.err
	PERF_EXIT_CODE=$?

	# check the events used
	../common/check_all_patterns_found.pl "cpu\/mem-loads" < $LOGS_DIR/basic_loads_evlist.log
	CHECK_EXIT_CODE=$?
	../common/check_no_patterns_found.pl "cycles" < $LOGS_DIR/basic_loads_evlist.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_no_patterns_found.pl "zero-sized file" "nothing to do" < $LOGS_DIR/basic_loads_evlist.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "loads event check"
	(( TEST_RESULT += $? ))


	### loads report

	# test that something got recorded here
	$CMD_PERF mem report --stdio -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_loads_report.log 2> $LOGS_DIR/basic_loads_report.err
	PERF_EXIT_CODE=$?

	# check the perf mem report output
	REGEX_MEM_REPORT_LINE="\s*$RE_NUMBER%\s+$RE_NUMBER\s+$RE_NUMBER\s+.*\s+\[[kuH\.]\]\s\w+"
	../common/check_all_lines_matched.pl "$REGEX_MEM_REPORT_LINE" "$RE_LINE_COMMENT" "$RE_LINE_EMPTY" < $LOGS_DIR/basic_loads_report.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "dummy" "function_a" "function_b" "stack" < $LOGS_DIR/basic_loads_report.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_no_patterns_found.pl "zero-sized file" "nothing to do" < $LOGS_DIR/basic_loads_report.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "loads report"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "loads record"
	print_testcase_skipped "loads event check"
	print_testcase_skipped "loads report"
fi


### stores record, stores event check, stores report

if [ "$MEM_STORES_SUPPORTED" = "yes" ]; then
	### stores record

	# test that perf mem record can record mem-stores
	$CMD_PERF mem -t store record -o $CURRENT_TEST_DIR/perf.data examples/dummy > /dev/null 2> $LOGS_DIR/basic_stores_record.err
	PERF_EXIT_CODE=$?

	# check the perf mem record output
	../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/basic_stores_record.err
	CHECK_EXIT_CODE=$?
	../common/check_errors_whitelisted.pl "stderr-whitelist.txt" < $LOGS_DIR/basic_stores_record.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "stores record"
	(( TEST_RESULT += $? ))


	### stores event check

	# we need to check, whether the correct event has been used
	$CMD_PERF evlist -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_stores_evlist.log 2> $LOGS_DIR/basic_stores_evlist.err
	PERF_EXIT_CODE=$?

	# check the events used
	../common/check_all_patterns_found.pl "cpu\/mem-stores" < $LOGS_DIR/basic_stores_evlist.log
	CHECK_EXIT_CODE=$?
	../common/check_no_patterns_found.pl "cycles" < $LOGS_DIR/basic_stores_evlist.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_no_patterns_found.pl "zero-sized file" "nothing to do" < $LOGS_DIR/basic_stores_evlist.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "stores event check"
	(( TEST_RESULT += $? ))


	### stores report

	# test that something got recorded here
	$CMD_PERF mem report --stdio -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_stores_report.log 2> $LOGS_DIR/basic_stores_report.err
	PERF_EXIT_CODE=$?

	# check the perf mem report output
	REGEX_MEM_REPORT_LINE="\s*$RE_NUMBER%\s+$RE_NUMBER\s+$RE_NUMBER\s+.*\s+\[[kuH\.]\]\s\w+"
	../common/check_all_lines_matched.pl "$REGEX_MEM_REPORT_LINE" "$RE_LINE_COMMENT" "$RE_LINE_EMPTY" < $LOGS_DIR/basic_stores_report.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "dummy" "function_a" "function_b" "stack" < $LOGS_DIR/basic_stores_report.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_no_patterns_found.pl "zero-sized file" "nothing to do" < $LOGS_DIR/basic_stores_report.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "stores report"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "stores record"
	print_testcase_skipped "stores event check"
	print_testcase_skipped "stores report"
fi


### loads&stores record, loads&stores event check, loads&tores report

if [ "$MEM_LOADS_SUPPORTED" = "yes" -a "$MEM_STORES_SUPPORTED" = "yes" ]; then
	### both loads and stores record

	# test that perf mem record can record both mem-loads and mem-stores
	$CMD_PERF mem -t load,store record -o $CURRENT_TEST_DIR/perf.data examples/dummy > /dev/null 2> $LOGS_DIR/basic_both_record.err
	PERF_EXIT_CODE=$?

	# check the perf mem record output
	../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/basic_both_record.err
	CHECK_EXIT_CODE=$?
	../common/check_errors_whitelisted.pl "stderr-whitelist.txt" < $LOGS_DIR/basic_both_record.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "loads&stores record"
	(( TEST_RESULT += $? ))


	### loads&stores event check

	# we need to check, whether the correct events have been used
	$CMD_PERF evlist -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_both_evlist.log 2> $LOGS_DIR/basic_both_evlist.err
	PERF_EXIT_CODE=$?

	# check the events used
	../common/check_all_patterns_found.pl "cpu\/mem-stores" "cpu\/mem-loads" < $LOGS_DIR/basic_both_evlist.log
	CHECK_EXIT_CODE=$?
	../common/check_no_patterns_found.pl "cycles" < $LOGS_DIR/basic_both_evlist.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_no_patterns_found.pl "zero-sized file" "nothing to do" < $LOGS_DIR/basic_both_evlist.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "loads&stores event check"
	(( TEST_RESULT += $? ))


	### loads&stores report

	# test that something got recorded here
	$CMD_PERF mem report --stdio -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_both_report.log 2> $LOGS_DIR/basic_both_report.err
	PERF_EXIT_CODE=$?

	# check the perf mem report output
	REGEX_MEM_REPORT_LINE="\s*$RE_NUMBER%\s+$RE_NUMBER\s+$RE_NUMBER\s+.*\s+\[[kuH\.]\]\s\w+"
	../common/check_all_lines_matched.pl "$REGEX_MEM_REPORT_LINE" "$RE_LINE_COMMENT" "$RE_LINE_EMPTY" < $LOGS_DIR/basic_stores_report.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "dummy" "function_a" "function_b" "stack" < $LOGS_DIR/basic_both_report.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_no_patterns_found.pl "zero-sized file" "nothing to do" < $LOGS_DIR/basic_both_report.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "loads&stores report"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "loads&stores record"
	print_testcase_skipped "loads&stores event check"
	print_testcase_skipped "loads&stores report"
fi


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
