#
#	test_basic of perf_report test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests basic functionality of perf report command.
#
#

# include working environment
. ../common/settings.sh
. ../common/patterns.sh
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


### help message

# test that a help message is shown and looks reasonable
$CMD_PERF report --help > basic_helpmsg.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "PERF-REPORT" "NAME" "SYNOPSIS" "DESCRIPTION" "OPTIONS" "OVERHEAD\s+CALCULATION" "SEE ALSO" < basic_helpmsg.log
CHECK_EXIT_CODE=$?
../common/check_all_patterns_found.pl "input" "verbose" "show-nr-samples" "showcpuutilization" "threads" "comms" "pid" "tid" "dsos" "symbols" "symbol-filter" < basic_helpmsg.log
(( CHECK_EXIT_CODE += $? ))
../common/check_all_patterns_found.pl "hide-unresolved" "sort" "fields" "parent" "exclude-other" "column-widths" "field-separator" "dump-raw-trace" "children" < basic_helpmsg.log
(( CHECK_EXIT_CODE += $? ))
../common/check_all_patterns_found.pl "call-graph" "max-stack" "inverted" "ignore-callees" "pretty" "stdio" "tui" "gtk" "vmlinux" "kallsyms" "modules" < basic_helpmsg.log
(( CHECK_EXIT_CODE += $? ))
../common/check_all_patterns_found.pl "force" "symfs" "cpu" "disassembler-style" "source" "asm-raw" "show-total-period" "show-info" "branch-stack" "group" < basic_helpmsg.log
(( CHECK_EXIT_CODE += $? ))
../common/check_all_patterns_found.pl "branch-history" "objdump" "demangle" "percent-limit" "percentage" "header" "itrace" "full-source-path" "show-ref-call-graph" < basic_helpmsg.log
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "help message"
(( TEST_RESULT += $? ))


### basic execution

# test that perf report is even working
$CMD_PERF report --stdio > basic_basic.log 2> basic_basic.err
PERF_EXIT_CODE=$?

REGEX_LOST_SAMPLES_INFO="#\s*Total Lost Samples:\s+$RE_NUMBER"
REGEX_SAMPLES_INFO="#\s*Samples:\s+$RE_NUMBER\s+of\s+event\s+'$RE_EVENT_ANY'"
REGEX_LINES_HEADER="#\s*Children\s+Self\s+Command\s+Shared Object\s+Symbol"
REGEX_LINES="\s*$RE_NUMBER%\s+$RE_NUMBER%\s+\S+\s+\[kernel\.vmlinux\]\s+\[[k\.]\]\s+\w+"
../common/check_all_patterns_found.pl "$REGEX_LOST_SAMPLES_INFO" "$REGEX_SAMPLES_INFO" "$REGEX_LINES_HEADER" "$REGEX_LINES" < basic_basic.log
CHECK_EXIT_CODE=$?
test ! -s basic_basic.err
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "basic execution"
(( TEST_RESULT += $? ))


### number of samples

# '--show-nr-samples' should show number of samples for each symbol
$CMD_PERF report --stdio --show-nr-samples > basic_nrsamples.log 2> basic_nrsamples.err
PERF_EXIT_CODE=$?

REGEX_LINES_HEADER="#\s*Children\s+Self\s+Samples\s+Command\s+Shared Object\s+Symbol"
REGEX_LINES="\s*$RE_NUMBER%\s+$RE_NUMBER%\s+$RE_NUMBER\s+\S+\s+\[kernel\.vmlinux\]\s+\[[k\.]\]\s+\w+"
../common/check_all_patterns_found.pl "$REGEX_LINES_HEADER" "$REGEX_LINES" < basic_nrsamples.log
CHECK_EXIT_CODE=$?
test ! -s basic_nrsamples.err
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "number of samples"
(( TEST_RESULT += $? ))


### header

# '--header' and '--header-only' should show perf report header
$CMD_PERF report --stdio --header-only > basic_header.log
PERF_EXIT_CODE=$?

REGEX_LINE_HOSTNAME="#\s+hostname\s*:\s*$MY_HOSTNAME"
REGEX_LINE_KERNEL="#\s+os release\s*:\s*$MY_KERNEL_VERSION"
REGEX_LINE_PERF="#\s+perf version\s*:\s*"
REGEX_LINE_ARCH="#\s+arch\s*:\s*$MY_ARCH"
REGEX_LINE_CPUS_ONLINE="#\s+nrcpus online\s*:\s*$MY_CPUS_ONLINE"
REGEX_LINE_CPUS_AVAIL="#\s+nrcpus avail\s*:\s*$MY_CPUS_AVAILABLE"
../common/check_all_patterns_found.pl "$REGEX_LINE_HOSTNAME" "$REGEX_LINE_KERNEL" "$REGEX_LINE_PERF" "$REGEX_LINE_ARCH" "$REGEX_LINE_CPUS_ONLINE" "$REGEX_LINE_CPUS_AVAIL" < basic_header.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "header"
(( TEST_RESULT += $? ))


### show CPU utilization

# '--showcpuutilization' should show percentage for both system and userspace mode
$CMD_PERF report --stdio --showcpuutilization > basic_cpuut.log 2> basic_cpuut.err
PERF_EXIT_CODE=$?

REGEX_LINES_HEADER="#\s*Children\s+Self\s+sys\s+usr\s+Command\s+Shared Object\s+Symbol"
REGEX_LINES="\s*$RE_NUMBER%\s+$RE_NUMBER%\s+$RE_NUMBER%\s+$RE_NUMBER%\s+\S+\s+\[kernel\.vmlinux\]\s+\[[k\.]\]\s+\w+"
../common/check_all_patterns_found.pl "$REGEX_LINES_HEADER" "$REGEX_LINES" < basic_cpuut.log
CHECK_EXIT_CODE=$?
test ! -s basic_cpuut.err
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "show CPU utilization"
(( TEST_RESULT += $? ))


### pid

# '--pid=' should limit the output for a process with the given pid only
$CMD_PERF report --stdio --pid=1 > basic_pid.log 2> basic_pid.err
PERF_EXIT_CODE=$?

grep -P '\s+[\d\.]+%' basic_pid.log | ../common/check_all_lines_matched.pl "systemd|init"
CHECK_EXIT_CODE=$?
test ! -s basic_pid.err
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "pid"
(( TEST_RESULT += $? ))


### non-existing symbol

# '--symbols' should show only the given symbols
$CMD_PERF report --stdio --symbols=dummynonexistingsymbol > basic_symbols.log 2> basic_symbols.err
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$RE_LINE_EMPTY" "$RE_LINE_COMMENT" < basic_symbols.log
CHECK_EXIT_CODE=$?
test ! -s basic_symbols.err
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "non-existing symbol"
(( TEST_RESULT += $? ))


### symbol filter

# '--symbol-filter' should filter symbols based on substrings
$CMD_PERF report --stdio --symbol-filter=map > basic_symbolfilter.log 2> basic_symbolfilter.err
PERF_EXIT_CODE=$?

grep -P '\s+[\d\.]+%' basic_symbolfilter.log | ../common/check_all_lines_matched.pl "\[[k\.]\]\s+.*map"
CHECK_EXIT_CODE=$?
test ! -s basic_symbolfilter.err
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "symbol filter"
(( TEST_RESULT += $? ))


# TODO: $CMD_PERF report -n --showcpuutilization -TUxDg 2> 01.log

# print overall resutls
print_overall_results "$TEST_RESULT"
exit $?
