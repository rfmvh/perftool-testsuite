#!/bin/bash

#
#	test_basic of perf_timechart test
#	Author: Benjamin Salon <bsalon@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf timechart command.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

consider_skipping $RUNMODE_EXPERIMENTAL

### help message

if [ "$PARAM_GENERAL_HELP_TEXT_CHECK" = "y" ]; then
	# test that a help message is shown and looks reasonable
	$CMD_PERF timechart --help > $LOGS_DIR/basic_helpmsg.log
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "PERF-TIMECHART" "NAME" "SYNOPSIS" "DESCRIPTION" "TIMECHART OPTIONS" "RECORD OPTIONS" "EXAMPLES" "SEE ALSO" < $LOGS_DIR/basic_helpmsg.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "input" "output" "width" "power-only" "tasks-only" "process" "force" "symfs" "proc-num" "topology" "highlight" "io-min-time" "io-merge-dist" "io-only" "callchain" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "help message"
fi


### basic execution

# timechart record

$CMD_PERF timechart record -- -o $CURRENT_TEST_DIR/perf.data -- $CMD_BASIC_SLEEP 2> $LOGS_DIR/basic_record.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/basic_record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "timechart record"
(( TEST_RESULT += $? ))


# timechart

$CMD_PERF timechart -i $CURRENT_TEST_DIR/perf.data -o $LOGS_DIR/basic_timechart.svg 2> $LOGS_DIR/basic_timechart.log
PERF_EXIT_CODE=$?

REGEX_TIMEHIST_LINE="Written $RE_NUMBER seconds of trace to $LOGS_DIR/basic_timechart\.svg\."

../common/check_all_patterns_found.pl "$REGEX_TIMEHIST_LINE" < $LOGS_DIR/basic_timechart.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "timechart"
(( TEST_RESULT += $? ))


# timechart :: svg output check

REGEX_ATTRIBUTE="[-\w]+=\"[\w-,;\.:\/\(\)]+\""
REGEX_ATTRIBUTES="(?:\s*$REGEX_ATTRIBUTE)*"
REGEX_XML="<\?xml$REGEX_ATTRIBUTES\?>"
REGEX_DOCTYPE="<!DOCTYPE svg SYSTEM \"[\w:\/\.]+\">"

REGEX_CDATA_ATTRIBUTE="[\w\-]+:\s*[\w\,\(\)\.\s]+;"
REGEX_CDATA_ATTRIBUTES="(?:\s*$REGEX_CDATA_ATTRIBUTE\s*)*"
REGEX_CDATA_START="<!\[CDATA\["
REGEX_CDATA_LINE="\s*[\w\.]+\s*\{$REGEX_CDATA_ATTRIBUTES\}"
REGEX_CDATA_END="\]\]>"

REGEX_TAG="<\w+$REGEX_ATTRIBUTES\/?>"

REGEX_SVG_ELEMENT="<svg$REGEX_ATTRIBUTES>"

REGEX_TEXT="[-\w\(\)@\.: ]*"
REGEX_TAG_WITH_TEXT="$REGEX_TAG$REGEX_TEXT(?:</\w+>)?"

REGEX_CLOSING_TAG="</\w+>"

../common/check_all_lines_matched.pl "$REGEX_XML" "$REGEX_DOCTYPE" "$REGEX_CDATA_START" "$REGEX_CDATA_LINE" "$REGEX_CDATA_END" "$REGEX_TAG" "$REGEX_TAG_WITH_TEXT" "$REGEX_CLOSING_TAG" < $LOGS_DIR/basic_timechart.svg
CHECK_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$REGEX_XML" "$REGEX_DOCTYPE" "$REGEX_SVG_ELEMENT" < $LOGS_DIR/basic_timechart.svg
(( CHECK_EXIT_CODE += $? ))

print_results 0 $CHECK_EXIT_CODE "timechart :: svg output check"
(( TEST_RESULT += $? ))


### perf timechart with --callchain option

# timechart record with --callchain

$CMD_PERF timechart record -g -- -o $CURRENT_TEST_DIR/perf.data -- $CMD_SIMPLE 2> $LOGS_DIR/basic_record_g.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/basic_record_g.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "timechart record with --callchain"
(( TEST_RESULT += $? ))


# timechart with --callchain

$CMD_PERF timechart -i $CURRENT_TEST_DIR/perf.data -o $LOGS_DIR/basic_timechart_g.svg 2> $LOGS_DIR/basic_timechart_g.log
PERF_EXIT_CODE=$?

REGEX_TIMEHIST_LINE="Written $RE_NUMBER seconds of trace to $LOGS_DIR/basic_timechart_g\.svg\."

../common/check_all_patterns_found.pl "$REGEX_TIMEHIST_LINE" < $LOGS_DIR/basic_timechart_g.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "timechart with --callchain"
(( TEST_RESULT += $? ))


# timechart with --callchain :: svg output check

REGEX_ADDRESS_LINE="\.+\s*$RE_NUMBER_HEX"

../common/check_all_lines_matched.pl "$REGEX_XML" "$REGEX_DOCTYPE" "$REGEX_CDATA_START" "$REGEX_CDATA_LINE" "$REGEX_CDATA_END" "$REGEX_TAG" "$REGEX_TAG_WITH_TEXT" "$REGEX_CLOSING_TAG" "$REGEX_ADDRESS_LINE" < $LOGS_DIR/basic_timechart_g.svg
CHECK_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$REGEX_XML" "$REGEX_DOCTYPE" "$REGEX_SVG_ELEMENT" < $LOGS_DIR/basic_timechart_g.svg
(( CHECK_EXIT_CODE += $? ))

print_results 0 $CHECK_EXIT_CODE "timechart with --callchain :: svg output check"
(( TEST_RESULT += $? ))


### perf timechart with --power-only option

# timechart record with --power-only

$CMD_PERF timechart record -P -- -o $CURRENT_TEST_DIR/perf.data -- $CMD_BASIC_SLEEP 2> $LOGS_DIR/basic_record_power_only.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/basic_record_power_only.log
CHECK_EXIT_CODE=$?

 print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "timechart record with --power-only"
(( TEST_RESULT += $? ))


# timechart with --power-only

$CMD_PERF timechart -P -i $CURRENT_TEST_DIR/perf.data -o $LOGS_DIR/basic_timechart_power_only.svg 2> $LOGS_DIR/basic_timechart_power_only.log
PERF_EXIT_CODE=$?

REGEX_TIMEHIST_LINE="Written $RE_NUMBER seconds of trace to $LOGS_DIR/basic_timechart_power_only\.svg\."

../common/check_all_patterns_found.pl "$REGEX_TIMEHIST_LINE" < $LOGS_DIR/basic_timechart_power_only.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "timechart with --power-only"
(( TEST_RESULT += $? ))


# timechart without --power-only

$CMD_PERF timechart -i $CURRENT_TEST_DIR/perf.data -o $LOGS_DIR/basic_timechart_power_only_no_P.svg 2> $LOGS_DIR/basic_timechart_power_only_no_P.log
PERF_EXIT_CODE=$?

REGEX_TIMEHIST_LINE="Written $RE_NUMBER seconds of trace to $LOGS_DIR/basic_timechart_power_only_no_P\.svg\."

../common/check_all_patterns_found.pl "$REGEX_TIMEHIST_LINE" < $LOGS_DIR/basic_timechart_power_only_no_P.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "timechart without --power-only"
(( TEST_RESULT += $? ))


# timechart with --power-only :: svg output check

REGEX_ADDRESS_LINE="\.+\s*$RE_NUMBER_HEX"

../common/check_all_lines_matched.pl "$REGEX_XML" "$REGEX_DOCTYPE" "$REGEX_CDATA_START" "$REGEX_CDATA_LINE" "$REGEX_CDATA_END" "$REGEX_TAG" "$REGEX_TAG_WITH_TEXT" "$REGEX_CLOSING_TAG" < $LOGS_DIR/basic_timechart_power_only.svg
CHECK_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$REGEX_XML" "$REGEX_DOCTYPE" "$REGEX_SVG_ELEMENT" < $LOGS_DIR/basic_timechart_power_only.svg
(( CHECK_EXIT_CODE += $? ))

print_results 0 $CHECK_EXIT_CODE "timechart with --power-only :: svg output check"
(( TEST_RESULT += $? ))


# timechart with --power-only :: diff

cmp $LOGS_DIR/basic_timechart_power_only.svg $LOGS_DIR/basic_timechart_power_only_no_P.svg &> /dev/null

print_results 0 $? "timechart with --power-only :: diff"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
