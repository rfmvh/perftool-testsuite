#!/bin/bash

#
#	test_header of perf_script test
#	Author: Benjamin Salon <bsalon@redhat.com>
#
#	Description:
#
#		This test tests --header and --header-only options.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


# record

$CMD_PERF record -a -o $CURRENT_TEST_DIR/perf.data -- $CMD_BASIC_SLEEP > $LOGS_DIR/header_record.log 2> $LOGS_DIR/header_record.err
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/header_record.err
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "basic record"
(( TEST_RESULT += $? ))


# script

$CMD_PERF script -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/header_script.log 2> $LOGS_DIR/header_script.err
PERF_EXIT_CODE=$?

REGEX_COMMAND="[\w#~\-\+\/: ]+"
REGEX_EVENT="[\w]+"
REGEX_SYMBOL="(?:[\w\.@:<>*~,\[\] ]+\+$RE_ADDRESS|\[unknown\])"
REGEX_DSO="\((?:$RE_PATH_ABSOLUTE(?: \(deleted\))?|\[kernel\.kallsyms\]|\[unknown\]|\[vdso\]|\[kernel\.vmlinux\][\w\.]*)\)"

REGEX_BASIC_SCRIPT_LINE="^\s*$REGEX_COMMAND\s+$RE_NUMBER\s+\[$RE_NUMBER\]\s+($RE_NUMBER):\s+$RE_NUMBER\s*$RE_EVENT:\s+$RE_NUMBER_HEX\s+$REGEX_SYMBOL\s+$REGEX_DSO$"

../common/check_all_lines_matched.pl "$REGEX_BASIC_SCRIPT_LINE" < $LOGS_DIR/header_script.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "$REGEX_BASIC_SCRIPT_LINE" < $LOGS_DIR/header_script.log
(( CHECK_EXIT_CODE += $? ))
../common/check_timestamps.pl "$REGEX_BASIC_SCRIPT_LINE" < $LOGS_DIR/header_script.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "script"
(( TEST_RESULT += $? ))


# --header-only

$CMD_PERF script --header-only -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/header_header_only.log 2> $LOGS_DIR/header_header_only.err
PERF_EXIT_CODE=$?

REGEX_LINE_TIMESTAMP="#\s+captured on\s*:\s*$RE_DATE_TIME"
REGEX_LINE_HOSTNAME="#\s+hostname\s*:\s*$MY_HOSTNAME"
REGEX_LINE_KERNEL="#\s+os release\s*:\s*${MY_KERNEL_VERSION//+/\\+}"
REGEX_LINE_PERF="#\s+perf version\s*:\s*"
REGEX_LINE_ARCH="#\s+arch\s*:\s*$MY_ARCH"
REGEX_LINE_CPUS_ONLINE="#\s+nrcpus online\s*:\s*$MY_CPUS_ONLINE"
REGEX_LINE_CPUS_AVAIL="#\s+nrcpus avail\s*:\s*$MY_CPUS_AVAILABLE"

# disable precise check for "nrcpus avail" in BASIC runmode
test $PERFTOOL_TESTSUITE_RUNMODE -lt $RUNMODE_STANDARD && REGEX_LINE_CPUS_AVAIL="#\s+nrcpus avail\s*:\s*$RE_NUMBER"

../common/check_all_patterns_found.pl "$REGEX_LINE_TIMESTAMP" "$REGEX_LINE_HOSTNAME" "$REGEX_LINE_KERNEL" "$REGEX_LINE_PERF" "$REGEX_LINE_ARCH" "$REGEX_LINE_CPUS_ONLINE" "$REGEX_LINE_CPUS_AVAIL" < $LOGS_DIR/header_header_only.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "--header-only"
(( TEST_RESULT += $? ))


# --header-only -I

$CMD_PERF script --header-only -I -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/header_header_only_I.log 2> $LOGS_DIR/header_header_only_I.err
PERF_EXIT_CODE=$?

REGEX_CPU_TOPOLOGY="# CPU_TOPOLOGY info available, use -I to display"
REGEX_NUMA_TOPOLOGY="# NUMA_TOPOLOGY info available, use -I to display"
REGEX_CACHE="# CACHE info available, use -I to display"
REGEX_MEM_TOPOLOGY="# MEM_TOPOLOGY info available, use -I to display"

../common/check_all_patterns_found.pl "$REGEX_LINE_TIMESTAMP" "$REGEX_LINE_HOSTNAME" "$REGEX_LINE_KERNEL" "$REGEX_LINE_PERF" "$REGEX_LINE_ARCH" "$REGEX_LINE_CPUS_ONLINE" "$REGEX_LINE_CPUS_AVAIL" < $LOGS_DIR/header_header_only_I.log
CHECK_EXIT_CODE=$?
../common/check_no_patterns_found.pl "$REGEX_CPU_TOPOLOGY" "$REGEX_NUMA_TOPOLOGY" "$REGEX_CACHE" "$REGEX_MEM_TOPOLOGY" < $LOGS_DIR/header_header_only_I.log 
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "--header-only -I"


# --header

$CMD_PERF script --header -i $CURRENT_TEST_DIR/perf.data > $LOGS_DIR/header_header.log 2> $LOGS_DIR/header_header.err
CMD_EXIT_CODE=$?

cat $LOGS_DIR/header_header_only.log $LOGS_DIR/header_script.log > $LOGS_DIR/header_header_only_script.log 2> $LOGS_DIR/header_header_only_script.err
(( CMD_EXIT_CODE += $? ))

# --header should contain --header-only part
cmp $LOGS_DIR/header_header.log $LOGS_DIR/header_header_only_script.log &> $LOGS_DIR/header_header.cmp
CHECK_EXIT_CODE=$?

print_results $CMD_EXIT_CODE $CHECK_EXIT_CODE "--header"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
