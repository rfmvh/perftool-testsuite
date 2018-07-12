#!/bin/bash

#
#	test_basic of perf diff test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf diff command.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


### help message

if [ "$PARAM_GENERAL_HELP_TEXT_CHECK" = "y" ]; then
	# test that a help message is shown and looks reasonable
	$CMD_PERF diff --help > $LOGS_DIR/basic_helpmsg.log 2> $LOGS_DIR/basic_helpmsg.err
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "PERF-DIFF" "NAME" "SYNOPSIS" "DESCRIPTION" "COMPARISON" "OPTIONS" "SEE ALSO" < $LOGS_DIR/basic_helpmsg.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "differential\sprofile" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "dump-raw-trace" "modules" "dsos" "comms" "symbols" "force" "verbose" "field-separator" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "symfs" "baseline-only" "compute" "period" "formula" "order" "percentage" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_all_patterns_found.pl "delta" "ratio" "wdiff" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_no_patterns_found.pl "No manual entry for" < $LOGS_DIR/basic_helpmsg.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "help message"
fi


### basic execution

# diff...
( cd $CURRENT_TEST_DIR ; $CMD_PERF diff -m -t'|' perf.data.1 perf.data.2 > $LOGS_DIR/basic_diff.log 2> $LOGS_DIR/basic_diff.err )
PERF_EXIT_CODE=$?

# check the diff output
REGEX_SEP="\s*\|\s*"
REGEX_LINE_BASELINE="$RE_NUMBER$REGEX_SEP$REGEX_SEP(?:$RE_FILE_NAME)|(?:\[[\w\.]+\])$REGEX_SEP\[[\.kH]\]\s[\w\.\-]+"
REGEX_LINE_DELTA="$REGEX_SEP[\+\-]$RE_NUMBER%$REGEX_SEP(?:$RE_FILE_NAME)|(?:\[[\w\.]+\](?:[\.\w]+)?)$REGEX_SEP\[[\.kH]\]\s[\w\.\-]+"
REGEX_LINE_BOTH="$RE_NUMBER$REGEX_SEP[\+\-]$RE_NUMBER%$REGEX_SEP(?:$RE_FILE_NAME)|(?:\[[\w\.]+\](?:[\.\w]+)?)$REGEX_SEP\[[\.kH]\]\s[\w\.\-]+"
# check for the basic structure
../common/check_all_lines_matched.pl "$REGEX_LINE_BASELINE" "$REGEX_LINE_DELTA" "$REGEX_LINE_BOTH" "$RE_LINE_COMMENT" < $LOGS_DIR/basic_diff.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "basic execution - diff"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
