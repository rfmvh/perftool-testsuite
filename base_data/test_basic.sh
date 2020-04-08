#!/bin/bash

#
#	test_basic of perf_data test
#	Author: Benjamin Salon <bsalon@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf data command.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

# skip if the CTF conversion is not compiled in
if ! should_support_ctf_conversion; then
	print_overall_skipped
	exit $?
fi


### help message

if [ "$PARAM_GENERAL_HELP_TEXT_CHECK" = "y" ]; then
	# test that a help message is shown and looks reasonable
	$CMD_PERF data --help > $LOGS_DIR/basic_helpmsg.log
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "PERF-DATA" "NAME" "SYNOPSIS" "DESCRIPTION" "COMMANDS" "convert" "OPTIONS FOR CONVERT" "SEE ALSO" < $LOGS_DIR/basic_helpmsg.log
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "help message"
fi


### basic execution

# convert --to-ctf

$CMD_PERF data convert -i $CURRENT_TEST_DIR/perf.data --to-ctf $LOGS_DIR/converted_ctf 2> $LOGS_DIR/basic_convert_ctf.log
PERF_EXIT_CODE=$?

REGEX_LINE_CONVERT1="^\[\s+perf\s+data\s+convert:\s+Converted '$RE_PATH' into CTF data '$RE_PATH'\s+\].*$"
REGEX_LINE_CONVERT2="^\[\s+perf\s+data\s+convert:\s+Converted and wrote $RE_NUMBER\s*MB\s*\(~?$RE_NUMBER samples\)\s+\].*$"

../common/check_all_patterns_found.pl "$REGEX_LINE_CONVERT1" "$REGEX_LINE_CONVERT2" < $LOGS_DIR/basic_convert_ctf.log
CHECK_EXIT_CODE=$?

# metadata file is mandatory
test -e $LOGS_DIR/converted_ctf/metadata
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "convert --to-ctf"
(( TEST_RESULT += $? ))


# convert --to-ctl sample count check

RECORD_SAMPLES=`perl -ne 'print "$1" if /\((\d+) samples\)/' $LOGS_DIR/setup_record.log`
DATA_SAMPLES=`perl -ne 'print "$1" if /\((\d+) samples\)/' $LOGS_DIR/basic_convert_ctf.log`

test $RECORD_SAMPLES -eq $DATA_SAMPLES &> /dev/null
print_results 0 $? "convert --to-ctl sample count check ($DATA_SAMPLES == $RECORD_SAMPLES)"
(( TEST_RESULT += $? ))


# convert --to-ctf --all

$CMD_PERF data convert -i $CURRENT_TEST_DIR/perf.data --all --to-ctf $LOGS_DIR/converted_all_ctf 2> $LOGS_DIR/basic_convert_all_ctf.log
PERF_EXIT_CODE=$?

REGEX_LINE_CONVERT_ALL="^\[\s+perf\s+data\s+convert:\s+Converted and wrote $RE_NUMBER\s*MB\s*\(~?$RE_NUMBER samples, $RE_NUMBER non-samples\)\s+\].*$"

../common/check_all_patterns_found.pl "$REGEX_LINE_CONVERT1" "$REGEX_LINE_CONVERT_ALL" < $LOGS_DIR/basic_convert_all_ctf.log
CHECK_EXIT_CODE=$?

# metadata file is mandatory
test -e $LOGS_DIR/converted_ctf/metadata
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "convert --all --to-ctf"
(( TEST_RESULT += $? ))


# convert --to-ctl --all sample count check

DATA_ALL_SAMPLES=`perl -ne 'print "$1" if /\((\d+) samples, \d+ non-samples\)/' $LOGS_DIR/basic_convert_all_ctf.log`

test $RECORD_SAMPLES -eq $DATA_ALL_SAMPLES &> /dev/null
print_results 0 $? "convert --to-ctl sample count check ($DATA_ALL_SAMPLES == $RECORD_SAMPLES)"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
