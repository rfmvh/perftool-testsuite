#!/bin/bash

#
#	test_listing of perf_probe test
#	Author: Michael Petlan <mpetlan@redhat.com>
#	Author: Masami Hiramatsu <masami.hiramatsu.pt@hitachi.com>
#
#	Description:
#
#		This test tests various listings of the perf-probe command
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0

check_kprobes_available
if [ $? -ne 0 ]; then
	print_overall_skipped
	exit 0
fi

check_uprobes_available
if [ $? -ne 0 ]; then
	print_overall_skipped
	exit 0
fi


### kernel functions list

# the '-F' option should list all the available kernel functions for probing
$CMD_PERF probe -F > $LOGS_DIR/listing_kernel_functions.log
PERF_EXIT_CODE=$?

RATE=`../common/check_kallsyms_vs_probes.pl /proc/kallsyms <(cat $LOGS_DIR/listing_kernel_functions.log | grep -P '^\w+$')`
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "kernel functions list ($RATE to kallsyms)"
(( TEST_RESULT += $? ))


### userspace functions list

# with '-x binary' the '-F' option should inspect the binary instead of kernel
$CMD_PERF probe -x $CURRENT_TEST_DIR/examples/exact_counts -F > $LOGS_DIR/listing_userspace_functions.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "f_103x" "f_1x" "f_2x" "f_3x" "f_65535x" "f_997x" "main" < $LOGS_DIR/listing_userspace_functions.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "userspace functions list"
(( TEST_RESULT += $? ))


### kernel variables list

# the '-V' option should list all the available variables for a function/line
$CMD_PERF probe -V vfs_read > $LOGS_DIR/listing_kernel_variables.log 2> $LOGS_DIR/listing_kernel_variables.err
PERF_EXIT_CODE=$?

test $TESTLOG_VERBOSITY -ge 2 && cat $LOGS_DIR/listing_kernel_variables.err
../common/check_all_patterns_found.pl "Available variables at vfs_read" "char\s*\*\s*buf" "pos" "size_t\s+count" "struct\s+file\s*\*\s*file" < $LOGS_DIR/listing_kernel_variables.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "kernel variables list"
(( TEST_RESULT += $? ))


### userspace variables list

# with '-x binary' the '-V' option should inspect the binary for variables available in a function
LONG_FUNC="some_function_with_a_really_long_name_that_must_be_longer_than_64_bytes"
$CMD_PERF probe -x $CURRENT_TEST_DIR/examples/test -V $LONG_FUNC > $LOGS_DIR/listing_userspace_variables.log
PERF_EXIT_CODE=$?

LONG_VAR="some_variable_with_a_really_long_name_that_must_be_longer_than_64_bytes"
LONG_ARG="some_argument_with_a_really_long_name_that_must_be_longer_than_64_bytes"
../common/check_all_patterns_found.pl "Available variables at $LONG_FUNC" "int\s+i" "int\s+$LONG_VAR" "int\s+$LONG_ARG" < $LOGS_DIR/listing_userspace_variables.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "userspace variables list"
(( TEST_RESULT += $? ))


### kernel lines list

# the '-L' option should list all the available lines suitable for probing per function
$CMD_PERF probe -L vfs_read > $LOGS_DIR/listing_kernel_lines.log 2> $LOGS_DIR/listing_kernel_lines.err
PERF_EXIT_CODE=$?

test $TESTLOG_VERBOSITY -ge 2 && cat $LOGS_DIR/listing_kernel_lines.err
../common/check_all_patterns_found.pl "0\s+ssize_t\svfs_read" "\d+\s+\w+" "\d+\s+if\s?\(" "\d+\s+if\s?\(!?ret" < $LOGS_DIR/listing_kernel_lines.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "kernel lines list"
(( TEST_RESULT += $? ))


### kernel source lines list

# the '-L' option should list all the available lines suitable for probing per file
$CMD_PERF probe -L fs/read_write.c > $LOGS_DIR/listing_kernel_source_lines.log 2> $LOGS_DIR/listing_kernel_source_lines.err
PERF_EXIT_CODE=$?

test $TESTLOG_VERBOSITY -ge 2 && cat $LOGS_DIR/listing_kernel_source_lines.err
../common/check_all_patterns_found.pl "linux/fs/read_write.c" "\d+\s+\w+" "\d+\s+if\s?\(" "\d+\s+if\s?\(!?ret" "\d+\s+.*vfs_read" "\d+\s+.*vfs_write" "Linus Torvalds" < $LOGS_DIR/listing_kernel_source_lines.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "kernel source lines list"
(( TEST_RESULT += $? ))


### userspace lines list

# with '-x binary' the '-L' option should search for lines suitable for probing in the binary
LONG_FUNC="some_function_with_a_really_long_name_that_must_be_longer_than_64_bytes"
$CMD_PERF probe -x $CURRENT_TEST_DIR/examples/test -L $LONG_FUNC > $LOGS_DIR/listing_userspace_lines.log
PERF_EXIT_CODE=$?

LONG_VAR="some_variable_with_a_really_long_name_that_must_be_longer_than_64_bytes"
../common/check_all_patterns_found.pl "\d+\s+$LONG_VAR \+= i;" < $LOGS_DIR/listing_userspace_lines.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "userspace lines list"
(( TEST_RESULT += $? ))


### userspace source lines list

# the '-L' option should be able to list whole source file as well
LONG_FUNC="some_function_with_a_really_long_name_that_must_be_longer_than_64_bytes"
$CMD_PERF probe -x $CURRENT_TEST_DIR/examples/test -L examples/test.c > $LOGS_DIR/listing_userspace_source_lines.log
PERF_EXIT_CODE=$?

LONG_VAR="some_variable_with_a_really_long_name_that_must_be_longer_than_64_bytes"
../common/check_all_patterns_found.pl "\d+\s+$LONG_VAR \+= i;" < $LOGS_DIR/listing_userspace_source_lines.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "userspace source lines list"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
