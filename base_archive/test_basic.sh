#!/bin/bash

#
#	test_basic of perf_archive test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf report command.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

# skip the testcase if $PERFSUITE_RUN_DIR is set, since we
# cannot guarantee not writting into the current tree (we
# miss '-o' option in 'perf mem record'
if [ -n "$PERFSUITE_RUN_DIR" ]; then
	print_overall_skipped
	exit 0
fi

TEST_RESULT=0

# run the setup
source ./setup_src.sh

# the test name needs to be reset here
THIS_TEST_NAME=`basename $0 .sh`


### help message

if [ "$PARAM_GENERAL_HELP_TEXT_CHECK" = "y" ]; then
	# test that a help message is shown and looks reasonable
	$CMD_PERF archive --help > $LOGS_DIR/basic_helpmsg.log 2> $LOGS_DIR/basic_helpmsg.err
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "PERF-ARCHIVE" "NAME" "SYNOPSIS" "DESCRIPTION" "SEE ALSO" < $LOGS_DIR/basic_helpmsg.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "perf archive \[file\]" "This command runs perf-buildid-list" "perf.data" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))
	../common/check_no_patterns_found.pl "No manual entry for" < $LOGS_DIR/basic_helpmsg.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "help message"
fi


### report

# gather first perf-report log
$CMD_PERF --buildid-dir $BUILDIDDIR report -i $CURRENT_TEST_DIR/perf.data --stdio > $LOGS_DIR/basic_report.log 2> $LOGS_DIR/basic_report.err
PERF_EXIT_CODE=$?

REGEX_LOST_SAMPLES_INFO="#\s*Total Lost Samples:\s+$RE_NUMBER"
REGEX_SAMPLES_INFO="#\s*Samples:\s+(?:$RE_NUMBER)\w?\s+of\s+event\s+'$RE_EVENT_ANY'"
REGEX_LINES_HEADER="#\s*Overhead\s+Command\s+Shared Object\s+Symbol"
REGEX_LINES="\s*$RE_NUMBER%\s+\S+\s+\[kernel\.(?:vmlinux)|(?:kallsyms)\]\s+\[[k\.]\]\s+\w+"
../common/check_all_patterns_found.pl "$REGEX_LOST_SAMPLES_INFO" "$REGEX_SAMPLES_INFO" "$REGEX_LINES_HEADER" "$REGEX_LINES" < $LOGS_DIR/basic_report.log
CHECK_EXIT_CODE=$?
../common/check_errors_whitelisted.pl "stderr-whitelist.txt" < $LOGS_DIR/basic_report.err
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "report"
(( TEST_RESULT += $? ))


### script

# get DSOs hit in the perf.data
$CMD_PERF --buildid-dir $BUILDIDDIR script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_script.log 2> $LOGS_DIR/basic_script.err
PERF_EXIT_CODE=$?

REGEX_SCRIPT_LINE="\s+\S+\s+(?:\-1|$RE_NUMBER)\s+\[$RE_NUMBER\]\s+$RE_NUMBER:\s+$RE_NUMBER\s+$RE_EVENT\s+$RE_NUMBER_HEX\s+(?:@plt|\.?\w+)|(?:\[unknown\])\s+\((?:$RE_PATH|\[[\w\.]+\][\.\w]*)\)"
../common/check_all_lines_matched.pl "$REGEX_SCRIPT_LINE" < $LOGS_DIR/basic_script.log
CHECK_EXIT_CODE=$?
../common/check_errors_whitelisted.pl "stderr-whitelist.txt" < $LOGS_DIR/basic_script.err
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script"
(( TEST_RESULT += $? ))


### archive creation

# create an archive
$CMD_PERF --buildid-dir $BUILDIDDIR archive $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_archive.log 2> $LOGS_DIR/basic_archive.err
# FIXME the above command needs redirect output file to $CURRENT_TEST_DIR
PERF_EXIT_CODE=$?

REGEX_LINES_1="Now please run"
REGEX_LINES_2="perf.data.tar.bz2"
REGEX_LINES_3="wherever you need to run"
../common/check_all_patterns_found.pl "$REGEX_LINES_1" "$REGEX_LINES_2" "$REGEX_LINES_3" "$RE_LINE_EMPTY" < $LOGS_DIR/basic_archive.log
CHECK_EXIT_CODE=$?
../common/check_errors_whitelisted.pl "stderr-whitelist.txt" < $LOGS_DIR/basic_archive.err
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "archive creation"
(( TEST_RESULT += $? ))


### archive file sanity

# get the DSOs that were hit by samples
REGEX_MODULE="$RE_PATH_ABSOLUTE/modules/`uname -r | perl -pe 's/\+/\\\+/'`/$RE_PATH/.*\.ko(?:\.gz|\.xz)?$"
$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data 2> $LOGS_DIR/basic_archive_sanity.err | perl -ne 'print "$1\n" if /\(([^\)]+)\)$/' | sort -u | grep -v -P "$REGEX_MODULE" | grep -P '^/' > $CURRENT_TEST_DIR/basic_dsos_hit.list
# get the DSOs that were saved to the archive
bzcat $CURRENT_TEST_DIR/perf.data.tar.bz2 2>/dev/null | tar t 2>/dev/null | grep -v -P '^\.' 2>/dev/null | grep -v -P '^\[' | perl -pe 's/^/\//;s/\/[0-9a-f]{40}.*$//' | sort > $CURRENT_TEST_DIR/basic_dsos_archived.list
(( EXIT_CODE = ${PIPESTATUS[0]} + ${PIPESTATUS[1]} + ${PIPESTATUS[2]} + ${PIPESTATUS[3]} + ${PIPESTATUS[4]} ))

../common/check_dso_archive_content.pl "$CURRENT_TEST_DIR/basic_dsos_archived.list" "$CURRENT_TEST_DIR/basic_dsos_hit.list"
CHECK_EXIT_CODE=$?

../common/check_errors_whitelisted.pl "stderr-whitelist.txt" < $LOGS_DIR/basic_archive_sanity.err
(( CHECK_EXIT_CODE += $? ))

print_results $EXIT_CODE $CHECK_EXIT_CODE "archive sanity (contents)"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
