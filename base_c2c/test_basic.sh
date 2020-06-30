#!/bin/bash

#
#	test_basic of perf c2c test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf c2c command.
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

# skip the testcase if there are no suitable events to be used
if [ "$LDLAT_LOADS_SUPPORTED" = "no" -a "$LDLAT_STORES_SUPPORTED" = "no" ]; then
	# FIXME: one of the blocks, either this or the previous one is probably redundant
	# but in order to check it, we need to watch its behaviour for some time, since
	# the mem-* events are still somehow broken on some boxes, thus it's safer to have
	# it like this now
	echo "DEBUG: -- WARNING -- mem-* events are supported but ldlat-* ones are not"
	print_overall_skipped
	exit 0
fi


### help message

if [ "$PARAM_GENERAL_HELP_TEXT_CHECK" = "y" ]; then
	# test that a help message is shown and looks reasonable
	$CMD_PERF c2c --help > $LOGS_DIR/basic_helpmsg.log 2> $LOGS_DIR/basic_helpmsg.err
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "PERF-C2C" "NAME" "SYNOPSIS" "DESCRIPTION" "RECORD OPTIONS" "REPORT OPTIONS" "C2C RECORD" "C2C REPORT" "NODE INFO" "COALESCE" "SEE ALSO" < $LOGS_DIR/basic_helpmsg.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "event" "ldlat" "all-kernel" "all-user" "verbose" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "vmlinux" "input" "node-info" "call-graph" "coalesce" "stdio" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "stats" "full-symbols" "no-source" "show-all" "display" "force" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_no_patterns_found.pl "No manual entry for" < $LOGS_DIR/basic_helpmsg.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "help message"
fi

# For all evlist checks in this script:
#   "ldlat=" attribute is expected only on x86_64
if [ "$MY_ARCH" = "x86_64" ]; then
	REGEX_LDLAT_ATTR="ldlat="
fi


### invalid args

! $CMD_PERF c2c report -input 2> /dev/null
PERF_EXIT_CODE=$?

print_results $PERF_EXIT_CODE 0 "invalid args"
(( TEST_RESULT += $? ))


### loads record, loads event check, loads report

if [ "$LDLAT_LOADS_SUPPORTED" = "yes" ]; then
	### loads record

	# test that perf c2c record can record ldlat-loads
	$CMD_PERF c2c record -e ldlat-loads -- -o $CURRENT_TEST_DIR/perf.data examples/dummy > /dev/null 2> $LOGS_DIR/basic_loads_record.err
	PERF_EXIT_CODE=$?

	# check the perf c2c record output
	../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/basic_loads_record.err
	CHECK_EXIT_CODE=$?
	../common/check_errors_whitelisted.pl "stderr-whitelist.txt" < $LOGS_DIR/basic_loads_record.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "ldlat-loads record"
	(( TEST_RESULT += $? ))


	### loads event check

	# we need to check, whether the correct event has been used
	$CMD_PERF evlist -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_loads_evlist.log 2> $LOGS_DIR/basic_loads_evlist.err
	PERF_EXIT_CODE=$?

	# check the events used
	../common/check_all_patterns_found.pl "cpu\/mem-loads" "$REGEX_LDLAT_ATTR" < $LOGS_DIR/basic_loads_evlist.log
	CHECK_EXIT_CODE=$?
	../common/check_no_patterns_found.pl "cycles" < $LOGS_DIR/basic_loads_evlist.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_no_patterns_found.pl "zero-sized file" "nothing to do" < $LOGS_DIR/basic_loads_evlist.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "ldlat-loads event check"
	(( TEST_RESULT += $? ))


	### loads report

	# test that something got recorded here
	$CMD_PERF c2c report -i $CURRENT_TEST_DIR/perf.data --stdio > $LOGS_DIR/basic_loads_report.log 2> $LOGS_DIR/basic_loads_report.err
	PERF_EXIT_CODE=$?

	# check the perf c2c report output
	TOTAL_SAMPLES=`perl -ne 'print $1 if /Captured and wrote[^\(]+\((\d+)\ssamples\)/' < $LOGS_DIR/basic_loads_record.err`
	../common/check_all_patterns_found.pl "Total records\s+:\s+$TOTAL_SAMPLES" < $LOGS_DIR/basic_loads_report.log
	CHECK_EXIT_CODE=$?
	LOAD_OPS=`perl -ne 'print $1 if /^\s*Load Operations\s+:\s+(\d+)/' < $LOGS_DIR/basic_loads_report.log`
	UNPARSED_OPS=`perl -ne 'print $1 if /^\s*Unable to parse data source\s+:\s+(\d+)/' < $LOGS_DIR/basic_loads_report.log`
	test $(( LOAD_OPS + UNPARSED_OPS )) -eq $TOTAL_SAMPLES
	(( CHECK_EXIT_CODE += $? ))
	# little logging
	test $TESTLOG_VERBOSITY -ge 2 -a $CHECK_EXIT_CODE -ne 0 && echo "$LOAD_OPS + $UNPARSED_OPS should be equal to $TOTAL_SAMPLES"
	../common/check_all_patterns_found.pl "Store Operations\s+:\s+0" < $LOGS_DIR/basic_loads_report.log
	(( CHECK_EXIT_CODE += $? ))
	
	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "ldlat-loads report"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "ldlat-loads record"
	print_testcase_skipped "ldlat-loads event check"
	print_testcase_skipped "ldlat-loads report"
fi


### stores record, stores event check, stores report

if [ "$LDLAT_STORES_SUPPORTED" = "yes" ]; then
	### stores record

	# test that perf c2c record can record ldlat-stores
	$CMD_PERF c2c record -e ldlat-stores -- -o $CURRENT_TEST_DIR/perf.data examples/dummy > /dev/null 2> $LOGS_DIR/basic_stores_record.err
	PERF_EXIT_CODE=$?

	# check the perf c2c record output
	../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/basic_stores_record.err
	CHECK_EXIT_CODE=$?
	../common/check_errors_whitelisted.pl "stderr-whitelist.txt" < $LOGS_DIR/basic_stores_record.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "ldlat-stores record"
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

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "ldlat-stores event check"
	(( TEST_RESULT += $? ))


	### stores report

	# test that something got recorded here
	$CMD_PERF c2c report -i $CURRENT_TEST_DIR/perf.data --stdio > $LOGS_DIR/basic_stores_report.log 2> $LOGS_DIR/basic_stores_report.err
	PERF_EXIT_CODE=$?

	# check the perf c2c report output
	TOTAL_SAMPLES=`perl -ne 'print $1 if /Captured and wrote[^\(]+\((\d+)\ssamples\)/' < $LOGS_DIR/basic_stores_record.err`
	../common/check_all_patterns_found.pl "Total records\s+:\s+$TOTAL_SAMPLES" < $LOGS_DIR/basic_stores_report.log
	CHECK_EXIT_CODE=$?
	STORE_OPS=`perl -ne 'print $1 if /^\s*Store Operations\s+:\s+(\d+)/' < $LOGS_DIR/basic_stores_report.log`
	UNPARSED_OPS=`perl -ne 'print $1 if /^\s*Unable to parse data source\s+:\s+(\d+)/' < $LOGS_DIR/basic_stores_report.log`
	test $(( STORE_OPS + UNPARSED_OPS )) -eq $TOTAL_SAMPLES
	(( CHECK_EXIT_CODE += $? ))

	# little logging
	test $TESTLOG_VERBOSITY -ge 2 -a $CHECK_EXIT_CODE -ne 0 && echo "$STORE_OPS + $UNPARSED_OPS should be equal to $TOTAL_SAMPLES"

	../common/check_all_patterns_found.pl "Load Operations\s+:\s+0" < $LOGS_DIR/basic_stores_report.log
	(( CHECK_EXIT_CODE += $? ))
	
	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "ldlat-stores report"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "ldlat-stores record"
	print_testcase_skipped "ldlat-stores event check"
	print_testcase_skipped "ldlat-stores report"
fi



### ldlat-loads&ldlat-stores record, ldlat-loads&ldlat-stores event check, ldlat-loads&ldlat-stores report, ldlat-loads&ldlat-stores verification

if [ "$LDLAT_LOADS_SUPPORTED" = "yes" -a "$LDLAT_STORES_SUPPORTED" = "yes" ]; then
	### both loads and stores record

	# test that perf c2c record can record both ldlat-loads and ldlat-stores
	$CMD_PERF c2c record -- -o $CURRENT_TEST_DIR/perf.data examples/dummy > /dev/null 2> $LOGS_DIR/basic_both_record.err
	PERF_EXIT_CODE=$?

	# check the perf c2c record output
	../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/basic_both_record.err
	CHECK_EXIT_CODE=$?
	../common/check_errors_whitelisted.pl "stderr-whitelist.txt" < $LOGS_DIR/basic_both_record.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "ldlat-loads&ldlat-stores record"
	(( TEST_RESULT += $? ))


	### ldlat-loads&ldlat-stores event check

	# we need to check, whether the correct events have been used
	$CMD_PERF evlist -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_both_evlist.log 2> $LOGS_DIR/basic_both_evlist.err
	PERF_EXIT_CODE=$?

	# check the events used
	../common/check_all_patterns_found.pl "cpu\/mem-stores" "cpu\/mem-loads" "$REGEX_LDLAT_ATTR" < $LOGS_DIR/basic_both_evlist.log
	CHECK_EXIT_CODE=$?
	../common/check_no_patterns_found.pl "cycles" < $LOGS_DIR/basic_both_evlist.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_no_patterns_found.pl "zero-sized file" "nothing to do" < $LOGS_DIR/basic_both_evlist.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "ldlat-loads&ldlat-stores event check"
	(( TEST_RESULT += $? ))


	### ldlat-loads&ldlat-stores report

	# test that something got recorded here
	$CMD_PERF c2c report -i $CURRENT_TEST_DIR/perf.data --stdio > $LOGS_DIR/basic_both_report.log 2> $LOGS_DIR/basic_both_report.err
	PERF_EXIT_CODE=$?

	# check the perf c2c report output
	TOTAL_SAMPLES=`perl -ne 'print $1 if /Captured and wrote[^\(]+\((\d+)\ssamples\)/' < $LOGS_DIR/basic_both_record.err`
	../common/check_all_patterns_found.pl "Total records\s+:\s+$TOTAL_SAMPLES" < $LOGS_DIR/basic_both_report.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "Store Operations\s+:\s+$RE_NUMBER" < $LOGS_DIR/basic_both_report.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "Load Operations\s+:\s+$RE_NUMBER" < $LOGS_DIR/basic_both_report.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "ldlat-loads&ldlat-stores report"
	(( TEST_RESULT += $? ))


	### ldlat-loads&ldlat-stores verification

	# load + stores should equal the number of all samples
	LOAD_OPS=`perl -ne 'print $1 if /^\s*Load Operations\s+:\s+(\d+)/' < $LOGS_DIR/basic_both_report.log`
	STORE_OPS=`perl -ne 'print $1 if /^\s*Store Operations\s+:\s+(\d+)/' < $LOGS_DIR/basic_both_report.log`
	UNPARSED_OPS=`perl -ne 'print $1 if /^\s*Unable to parse data source\s+:\s+(\d+)/' < $LOGS_DIR/basic_both_report.log`
	test $(( LOAD_OPS + STORE_OPS + UNPARSED_OPS )) -eq $TOTAL_SAMPLES
	CHECK_EXIT_CODE=$?

	# little logging
	test $TESTLOG_VERBOSITY -ge 2 -a $CHECK_EXIT_CODE -ne 0 && echo "$LOAD_OPS + $STORE_OPS + $UNPARSED_OPS should be equal to $TOTAL_SAMPLES"

	print_results 0 $CHECK_EXIT_CODE "ldlat-loads&ldlat-stores verification"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "ldlat-loads&ldlat-stores record"
	print_testcase_skipped "ldlat-loads&ldlat-stores event check"
	print_testcase_skipped "ldlat-loads&ldlat-stores report"
	print_testcase_skipped "ldlat-loads&ldlat-stores verification"
fi


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
