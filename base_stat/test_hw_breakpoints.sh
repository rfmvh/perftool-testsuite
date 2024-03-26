#!/bin/bash

#
#	test_hw_breakpoints of perf_stat test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test should test mem:0x<ADDR>:[rwx]
#	events. These events use hw breakpoints that
#	are set to the address and can trace access
#	to memory at the address.
#
#	Various architectures have different support
#	of hw breakpoints.
#
#	The test should test both kernelspace and
#	userspace; read, write and execute accesses;
#	and also the '/len' modifier.
#

# include working environment
. ../common/init.sh

TEST_RESULT=0
SKIPPED=0
SUBTEST_CNT=2


### kernelspace address execution

if should_support_hw_breakpoints; then
	# perf stat -e mem:<addr>:x
	TEST_FUNC="vfs_read"
	ADDR=0x`cat /proc/kallsyms | grep -P "\\s$TEST_FUNC\$" | cut -f1 -d' '`
	$CMD_PERF stat -e mem:$ADDR:x -x';' -- cat /proc/cpuinfo > /dev/null 2> $LOGS_DIR/hw_breakpoints_k_addr_exec.err
	PERF_EXIT_CODE=$?

	# non-zero number of breakpoint hits is expected (around 6)
	REGEX_PERF_STAT_OUTPUT="^[1-9]\d*;;mem:$ADDR:x;$RE_NUMBER;100.00;"
	../common/check_all_patterns_found.pl "$REGEX_PERF_STAT_OUTPUT" < $LOGS_DIR/hw_breakpoints_k_addr_exec.err
	CHECK_EXIT_CODE=$?
	../common/check_all_lines_matched.pl "$REGEX_PERF_STAT_OUTPUT" < $LOGS_DIR/hw_breakpoints_k_addr_exec.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "kspace address execution mem:$ADDR:x"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "kspace address execution mem:<address>:x"
	(( SKIPPED += 1 ))
fi


### kernelspace address readwrite

if should_support_hw_watchpoints; then

	# perf stat -e mem:<addr>:rw
	TEST_VAR="vm_dirty_ratio"
	ADDR="0x`grep "$TEST_VAR" /proc/kallsyms | cut -f1 -d' '`"
	$CMD_PERF stat -e mem:$ADDR:rw -x';' -- sysctl vm.dirty_ratio > /dev/null 2> $LOGS_DIR/hw_breakpoints_k_addr_rw.err
	PERF_EXIT_CODE=$?

	# non-zero number of breakpoint hits is expected (around 3)
	REGEX_PERF_STAT_OUTPUT="^[1-9]\d*;;mem:$ADDR:rw;$RE_NUMBER;100.00;"
	../common/check_all_patterns_found.pl "$REGEX_PERF_STAT_OUTPUT" < $LOGS_DIR/hw_breakpoints_k_addr_rw.err
	CHECK_EXIT_CODE=$?
	../common/check_all_lines_matched.pl "$REGEX_PERF_STAT_OUTPUT" < $LOGS_DIR/hw_breakpoints_k_addr_rw.err
	(( CHECK_EXIT_CODE += $? ))

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "kspace address readwrite mem:$ADDR:rw"
	(( TEST_RESULT += $? ))
else
	print_testcase_skipped "kspace address readwrite mem:<address>:x"
	(( SKIPPED += 1 ))
fi

if [ $SKIPPED -eq $SUBTEST_CNT ]; then
	print_overall_skipped
	exit 0
else
	# print overall results
	print_overall_results "$TEST_RESULT"
	exit $?
fi
