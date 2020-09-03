#!/bin/bash

#
#	test_io of perf_timechart test
#	Author: Benjamin Salon <bsalon@redhat.com>
#
#	Description:
#
#		This test tests io options of perf timechart command.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

consider_skipping $RUNMODE_EXPERIMENTAL

# timechart record with --io-only

$CMD_PERF timechart record -I -- -o $CURRENT_TEST_DIR/perf.data -- $CMD_BASIC_SLEEP 2> $LOGS_DIR/io_record.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/io_record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "timechart record with --io-only"
(( TEST_RESULT += $? ))


# timechart with no options to compare with timechart with --io_* options
$CMD_PERF timechart -i $CURRENT_TEST_DIR/perf.data -o $LOGS_DIR/io_normal.svg 2> $LOGS_DIR/io_normal.log


##### perf timechart with all --io_* options

### timechart with --io-skip-eagain option

# timechart with --io-skip-eagain

$CMD_PERF timechart --io-skip-eagain -i $CURRENT_TEST_DIR/perf.data -o $LOGS_DIR/io_io_skip_eagain.svg 2> $LOGS_DIR/io_io_skip_eagain.log
PERF_EXIT_CODE=$?

REGEX_TIMEHIST_LINE="Written $RE_NUMBER seconds of trace to $LOGS_DIR/io_io_skip_eagain\.svg\."

../common/check_all_patterns_found.pl "$REGEX_TIMEHIST_LINE" < $LOGS_DIR/io_io_skip_eagain.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "timechart with --io-skip-eagain"
(( TEST_RESULT += $? ))


# timechart with --io-skip-eagain :: svg output check

REGEX_ATTRIBUTE="[-\w]+=\"[\w-,;\.:\/\(\) ]+\""
REGEX_ATTRIBUTES="(?:\s*$REGEX_ATTRIBUTE)*"
REGEX_XML="<\?xml$REGEX_ATTRIBUTES\?>"
REGEX_DOCTYPE="<!DOCTYPE svg SYSTEM \"[\w:\/\.]+\">"

REGEX_CDATA_ATTRIBUTE="[\w\-]+:\s*[\w\,\(\)\.\s]+;" #
REGEX_CDATA_ATTRIBUTES="(?:\s*$REGEX_CDATA_ATTRIBUTE\s*)*"
REGEX_CDATA_START="<!\[CDATA\["
REGEX_CDATA_LINE="\s*[\w\.]+\s*\{$REGEX_CDATA_ATTRIBUTES\}"
REGEX_CDATA_END="\]\]"

REGEX_TAG="<\w+$REGEX_ATTRIBUTES\/?>"

REGEX_SVG_ELEMENT="<svg$REGEX_ATTRIBUTES>"

REGEX_TEXT="[-\w\(\)@\.: ]*"
REGEX_TAG_WITH_TEXT="$REGEX_TAG$REGEX_TEXT(?:<\/\w+>)?"

REGEX_CLOSING_TAG="</\w+>"

../common/check_all_lines_matched.pl "$REGEX_XML" "$REGEX_DOCTYPE" "$REGEX_CDATA_START" "$REGEX_CDATA_LINE" "$REGEX_CDATA_END" "$REGEX_TAG" "$REGEX_TAG_WITH_TEXT" "$REGEX_CLOSING_TAG" < $LOGS_DIR/io_io_skip_eagain.svg
CHECK_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$REGEX_XML" "$REGEX_DOCTYPE" "$REGEX_SVG_ELEMENT" < $LOGS_DIR/io_io_skip_eagain.svg
(( CHECK_EXIT_CODE += $? ))

print_results 0 $CHECK_EXIT_CODE "timechart --io-skip-eagain :: svg output check"
(( TEST_RESULT += $? ))


### timechart with --io-min-time option

# timechart --io-min-time=$MIN_TIME_NSECS

MIN_TIME_NSECS=100

$CMD_PERF timechart --io-min-time=$MIN_TIME_NSECS -i $CURRENT_TEST_DIR/perf.data -o $LOGS_DIR/io_io_min_time.svg 2> $LOGS_DIR/io_io_min_time.log
PERF_EXIT_CODE=$?

REGEX_TIMEHIST_LINE="Written $RE_NUMBER seconds of trace to $LOGS_DIR/io_io_min_time\.svg\."

../common/check_all_patterns_found.pl "$REGEX_TIMEHIST_LINE" < $LOGS_DIR/io_io_min_time.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "timechart --io-min-time=$MIN_TIME_NSECS"
(( TEST_RESULT += $? ))


# timechart --io-min-time=$MIN_TIME_NSECS :: svg output check

../common/check_all_lines_matched.pl "$REGEX_XML" "$REGEX_DOCTYPE" "$REGEX_CDATA_START" "$REGEX_CDATA_LINE" "$REGEX_CDATA_END" "$REGEX_TAG" "$REGEX_TAG_WITH_TEXT" "$REGEX_CLOSING_TAG" < $LOGS_DIR/io_io_min_time.svg
CHECK_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$REGEX_XML" "$REGEX_DOCTYPE" "$REGEX_SVG_ELEMENT" < $LOGS_DIR/io_io_min_time.svg
(( CHECK_EXIT_CODE += $? ))

print_results 0 $CHECK_EXIT_CODE "timechart --io-min-time=$MIN_TIME_NSECS :: svg output check"
(( TEST_RESULT += $? ))


REGEX_FOR_DIFF="<title>fd=\d+\s*error=\d+\s*merges=(\d+)<\/title>"

diff $LOGS_DIR/io_normal.svg $LOGS_DIR/io_io_min_time.svg > $LOGS_DIR/io_io_min_time.diff
if [ $? -ne 0 ]; then
	CHECK_EXIT_CODE=`perl -ne 'BEGIN{$n=0;$i=0;} {$n += 1 if ($i < 0); $i += $1 + 1 if /^<\s*'$REGEX_FOR_DIFF'$/; $i -= $1 if /^>\s*'$REGEX_FOR_DIFF'$/} END{print "$n";}' < $LOGS_DIR/io_io_min_time.diff`

	print_results 0 $CHECK_EXIT_CODE "timechart --io-min-time=$MIN_TIME_NSECS :: diff"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "timechart --io-min-time=$MIN_TIME_NSECS :: diff"
fi


### timechart with --io-merge-dist option

# timechart --io-merge-dist=$MERGE_DIST_NSECS

MERGE_DIST_NSECS=10000000

$CMD_PERF timechart --io-merge-dist=$MERGE_DIST_NSECS -i $CURRENT_TEST_DIR/perf.data -o $LOGS_DIR/io_io_merge_dist.svg 2> $LOGS_DIR/io_io_merge_dist.log
PERF_EXIT_CODE=$?

REGEX_TIMEHIST_LINE="Written $RE_NUMBER seconds of trace to $LOGS_DIR/io_io_merge_dist\.svg\."

../common/check_all_patterns_found.pl "$REGEX_TIMEHIST_LINE" < $LOGS_DIR/io_io_merge_dist.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "timechart --io-merge-dist=$MERGE_DIST_NSECS"
(( TEST_RESULT += $? ))


# timechart --io-merge-dist=$MERGE_DIST_NSECS :: svg output check

../common/check_all_lines_matched.pl "$REGEX_XML" "$REGEX_DOCTYPE" "$REGEX_CDATA_START" "$REGEX_CDATA_LINE" "$REGEX_CDATA_END" "$REGEX_TAG" "$REGEX_TAG_WITH_TEXT" "$REGEX_CLOSING_TAG" < $LOGS_DIR/io_io_merge_dist.svg
CHECK_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$REGEX_XML" "$REGEX_DOCTYPE" "$REGEX_SVG_ELEMENT" < $LOGS_DIR/io_io_merge_dist.svg
(( CHECK_EXIT_CODE += $? ))

print_results 0 $CHECK_EXIT_CODE "timechart --io-merge-dist=$MERGE_DIST_NSECS :: svg output check"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
