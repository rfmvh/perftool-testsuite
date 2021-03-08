#!/bin/bash

#
#	test_basic of perf_kmem test
#	Author: Benjamin Salon <bsalon@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf kmem command.
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
	$CMD_PERF kmem --help > $LOGS_DIR/basic_helpmsg.log
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "PERF-KMEM" "NAME" "SYNOPSIS" "DESCRIPTION" "OPTIONS" "SEE ALSO" < $LOGS_DIR/basic_helpmsg.log
	CHECK_EXIT_CODE=$?
	../common/check_all_patterns_found.pl "input" "force" "verbose" "caller" "alloc" "sort" "line" "raw-ip" "slab" "page" "live" "time" < $LOGS_DIR/basic_helpmsg.log
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "help message"
fi


# use output redirection paramter if it is supported
if support_output_parameter; then
	OUTPUT_FLAG="-o $CURRENT_TEST_DIR/perf.data"
else
	OUTPUT_FLAG="-- -o $CURRENT_TEST_DIR/perf.data"
fi


### basic execution

# basic kmem record test

$CMD_PERF kmem record $OUTPUT_FLAG -- $CMD_SIMPLE 2> $LOGS_DIR/basic_record.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/basic_record.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "record"
(( TEST_RESULT += $? ))


# basic kmem stat test

$CMD_PERF kmem stat -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_stat.log
PERF_EXIT_CODE=$?

REGEX_STAT_HEADER_LINE="SUMMARY \(SLAB allocator\)"
REGEX_STAT_HEADER_UNDERLINE="={20,}"
REGEX_TOT_REQUEST="Total bytes requested:\s+$RE_NUMBER"
REGEX_TOT_ALLOC="Total bytes allocated:\s+$RE_NUMBER"
REGEX_TOT_FREED="Total bytes freed:\s+$RE_NUMBER"
REGEX_NET_TOT_ALLOC="Net total bytes allocated:\s+$RE_NUMBER"
REGEX_TOT_WASTED="Total bytes wasted on internal fragmentation:\s+$RE_NUMBER"
REGEX_INTERN_FRAG="Internal fragmentation:\s+${RE_NUMBER}%"
REGEX_CROSS_CPU_ALLOC="Cross CPU allocations:\s+$RE_NUMBER/$RE_NUMBER"

../common/check_exact_pattern_order.pl "$REGEX_STAT_HEADER_LINE" "$REGEX_STAT_HEADER_UNDERLINE" "$REGEX_TOT_REQUEST" "$REGEX_TOT_ALLOC" "$REGEX_TOT_FREED" "$REGEX_NET_TOT_ALLOC" "$REGEX_TOT_WASTED" "$REGEX_INTERN_FRAG" "$REGEX_CROSS_CPU_ALLOC" < $LOGS_DIR/basic_stat.log
CHECK_EXIT_CODE=$?

# should create the same file
$CMD_PERF kmem --slab stat -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_stat_slab.log
(( PERF_EXIT_CODE += $? ))

cmp $LOGS_DIR/basic_stat.log $LOGS_DIR/basic_stat_slab.log 2> /dev/null
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "stat"
(( TEST_RESULT += $? ))


# kmen stat --caller and --raw-ip

# --caller

$CMD_PERF kmem --caller stat -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_stat_caller.log 2> $LOGS_DIR/basic_stat_caller.err
PERF_EXIT_CODE=$?

REGEX_CALLER_HEADER_LINE="\s+Callsite\s+\|\s+Total_alloc\/Per\s+\|\s+Total_req\/Per\s+\|\s+Hit\s+\|\s+Ping-pong\s+\|\s+Frag"
REGEX_CALLER_HEADER_UNDERLINE="-{100,}"
REGEX_CALLER_DATA_LINE="\s+[\w\+\.]+\s+\|\s+\d+\/\d+\s+\|\s+\d+\/\d+\s+\|\s+\d+\s+\|\s+\d+\s+\|\s+\d+\.\d+%"

# regex check
../common/check_all_patterns_found.pl "$REGEX_CALLER_HEADER_LINE" "$REGEX_CALLER_HEADER_UNDERLINE" "$REGEX_CALLER_DATA_LINE" < $LOGS_DIR/basic_stat_caller.log
CHECK_EXIT_CODE=$?

# slab allocator events
../common/check_exact_pattern_order.pl "$REGEX_STAT_HEADER_LINE" "$REGEX_STAT_HEADER_UNDERLINE" "$REGEX_TOT_REQUEST" "$REGEX_TOT_ALLOC" "$REGEX_TOT_FREED" "$REGEX_NET_TOT_ALLOC" "$REGEX_TOT_WASTED" "$REGEX_INTERN_FRAG" "$REGEX_CROSS_CPU_ALLOC" < $LOGS_DIR/basic_stat_caller.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "stat --caller"
(( TEST_RESULT += $? ))

# count check
CHECK_EXIT_CODE=`cat $LOGS_DIR/basic_stat_caller.log | cut -s -d'|' -f2-4 | perl -ne 'BEGIN{$n=0;}{$n+=1 if (/\s+(\d+)\/(\d+)\s+\|\s+(\d+)\/(\d+)\s+\|\s+(\d+)/) and ((int($1 / $5) != $2) or (int($3 / $5) != $4));} END{print "$n";}'`

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "stat --caller ($CHECK_EXIT_CODE wrong counts)"
(( TEST_RESULT += $? ))


# --raw-ip

$CMD_PERF kmem --caller --raw-ip stat -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_stat_raw-ip.log 2> $LOGS_DIR/basic_stat_raw-ip.err
PERF_EXIT_CODE=$?

REGEX_RAW_IP_DATA_LINE="\s+${RE_ADDRESS}\s+\|\s+\d+\/\d+\s+\|\s+\d+\/\d+\s+\|\s+\d+\s+\|\s+\d+\s+\|\s+\d+\.\d+%"

../common/check_all_patterns_found.pl "$REGEX_CALLER_HEADER_LINE" "$REGEX_CALLER_HEADER_UNDERLINE" "$REGEX_RAW_IP_DATA_LINE" < $LOGS_DIR/basic_stat_raw-ip.log
CHECK_EXIT_CODE=$?

# slab allocator events
../common/check_exact_pattern_order.pl "$REGEX_STAT_HEADER_LINE" "$REGEX_STAT_HEADER_UNDERLINE" "$REGEX_TOT_REQUEST" "$REGEX_TOT_ALLOC" "$REGEX_TOT_FREED" "$REGEX_NET_TOT_ALLOC" "$REGEX_TOT_WASTED" "$REGEX_INTERN_FRAG" "$REGEX_CROSS_CPU_ALLOC" < $LOGS_DIR/basic_stat_raw-ip.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "stat --caller --raw-ip"
(( TEST_RESULT += $? ))

# count check
CHECK_EXIT_CODE=`cat $LOGS_DIR/basic_stat_raw-ip.log | cut -s -d'|' -f2-4 | perl -ne 'BEGIN{$n=0;}{$n+=1 if (/\s+(\d+)\/(\d+)\s+\|\s+(\d+)\/(\d+)\s+\|\s+(\d+)/) and ((int($1 / $5) != $2) or (int($3 / $5) != $4));} END{print "$n";}'`

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "stat --caller --raw-ip ($CHECK_EXIT_CODE wrong counts)"
(( TEST_RESULT += $? ))


# kmem stat --alloc

$CMD_PERF kmem --alloc stat -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_stat_alloc.log 2> $LOGS_DIR/basic_stat_alloc.err
PERF_EXIT_CODE=$?

REGEX_ALLOC_HEADER_LINE="\s+Alloc Ptr\s+\|\s+Total_alloc\/Per\s+\|\s+Total_req\/Per\s+\|\s+Hit\s+\|\s+Ping-pong\s+\|\s+Frag"

../common/check_all_patterns_found.pl "$REGEX_ALLOC_HEADER_LINE" "$REGEX_CALLER_HEADER_UNDERLINE" "$REGEX_RAW_IP_DATA_LINE" < $LOGS_DIR/basic_stat_alloc.log
CHECK_EXIT_CODE=$?

# slab allocator events
../common/check_exact_pattern_order.pl "$REGEX_STAT_HEADER_LINE" "$REGEX_STAT_HEADER_UNDERLINE" "$REGEX_TOT_REQUEST" "$REGEX_TOT_ALLOC" "$REGEX_TOT_FREED" "$REGEX_NET_TOT_ALLOC" "$REGEX_TOT_WASTED" "$REGEX_INTERN_FRAG" "$REGEX_CROSS_CPU_ALLOC" < $LOGS_DIR/basic_stat_alloc.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "stat --alloc"
(( TEST_RESULT += $? ))

# count check
CHECK_EXIT_CODE=`cat $LOGS_DIR/basic_stat_alloc.log | cut -s -d'|' -f2-4 | perl -ne 'BEGIN{$n=0;}{$n+=1 if (/\s+(\d+)\/(\d+)\s+\|\s+(\d+)\/(\d+)\s+\|\s+(\d+)/) and ((int($1 / $5) != $2) or (int($3 / $5) != $4));} END{print "$n\n";}'`

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "stat --alloc ($CHECK_EXIT_CODE wrong counts)"
(( TEST_RESULT += $? ))


# kmem stat --page

# record - rewriting perf.data
$CMD_PERF kmem --page record $OUTPUT_FLAG -- $CMD_SIMPLE 2> $LOGS_DIR/basic_record_page.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/basic_record_page.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "record --page"
(( TEST_RESULT += $? ))

# stat
$CMD_PERF kmem --page stat -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/basic_stat_page.log 2> $LOGS_DIR/basic_stat_page.err
PERF_EXIT_CODE=$?

REGEX_PAGE_HEADER_LINE="SUMMARY \(page allocator\)"
REGEX_PAGE_HEADER_UNDERLINE="={20,}"
REGEX_ALLOC_REQ="Total allocation requests\s*:\s*$RE_NUMBER\s*\[\s*$RE_NUMBER\s+KB\s*\]"
REGEX_FREE_REQ="Total free requests\s*:\s*$RE_NUMBER\s*\[\s*$RE_NUMBER\s+KB\s*\]"
REGEX_ALLOC_FREED_REQ="Total alloc\+freed requests\s*:\s*$RE_NUMBER\s*\[\s*$RE_NUMBER\s+KB\s*\]"
REGEX_ALLOC_ONLY_REQ="Total alloc-only requests\s*:\s*$RE_NUMBER\s*\[\s*$RE_NUMBER\s+KB\s*\]"
REGEX_FREE_ONLY_REQ="Total free-only requests\s*:\s*$RE_NUMBER\s*\[\s*$RE_NUMBER\s+KB\s*\]"
REGEX_ALLOC_FAIL="Total allocation failures\s*:\s*$RE_NUMBER\s*\[\s*$RE_NUMBER\s+KB\s*\]"

../common/check_exact_pattern_order.pl "$REGEX_PAGE_HEADER_LINE" "$REGEX_PAGE_HEADER_UNDERLINE" "$REGEX_ALLOC_REQ" "$REGEX_FREE_REQ" "$REGEX_ALLOC_FREED_REQ" "$REGEX_ALLOC_ONLY_REQ" "$REGEX_FREE_ONLY_REQ" "$REGEX_ALLOC_FAIL" < $LOGS_DIR/basic_stat_page.log
CHECK_EXIT_CODE=$?

MAX_PAGE_ORDER=11
REGEX_PAGE_HEADER_LINE_2="Order\s+Unmovable\s+Reclaimable\s+Movable\s+Reserved\s+CMA\/Isolated"
REGEX_PAGE_HEADER_UNDERLINE_2="[- ]{70,}"
REGEX_PAGE_DATA_LINE="\s+$RE_NUMBER(?:\s+(?:\d+|\.)){5}"

tail -n $(( $MAX_PAGE_ORDER + 2 )) $LOGS_DIR/basic_stat_page.log | ../common/check_all_lines_matched.pl "$REGEX_PAGE_HEADER_LINE_2" "$REGEX_PAGE_HEADER_UNDERLINE_2" "$REGEX_PAGE_DATA_LINE"
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "stat --page"
(( TEST_RESULT += $? ))

# count check
head -n 11 $LOGS_DIR/basic_stat_page.log | awk '{print $5}' | tr '\n' ' ' > $LOGS_DIR/basic_stat_page_count.log

CHECK_EXIT_CODE=`cat $LOGS_DIR/basic_stat_page_count.log | perl -ne 'BEGIN{$n=1;} {$n=0 if (/\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+\d+/ and $1 == $3 + $4 and $2 == $3 + $5);} END{print "$n";}'`

print_results 0 $CHECK_EXIT_CODE "stat --page ($CHECK_EXIT_CODE wrong counts)"
(( TEST_RESULT += $? ))

# sample count check
N_SAMPLES=`perl -ne 'print "$1" if /\((\d+) samples\)/' $LOGS_DIR/basic_record_page.log`

CNT=`cat $LOGS_DIR/basic_stat_page_count.log | perl -ne '{print $1 + $2 if (/\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+\d+/);}'`

test $CNT -eq $N_SAMPLES
print_results 0 $? "stat --page sample count check ($CNT == $N_SAMPLES)"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
