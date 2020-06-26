#!/bin/bash

#
#	test_intr_regs of perf_record test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		On some architectures, the internal CPU registers
#	can be sampled by perf-record. This test should test
#	this feature.
#
#

# include working environment
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0 .sh`
TEST_RESULT=0


INTR_REGISTERS_SUPPORT="no"


# enable for x86_64
if [[ "$MY_ARCH" =~ x86_64 ]]; then
	INTR_REGISTERS_SUPPORT="yes"

	REGEX_INTR_REG_LIST="AX BX CX DX SI DI BP SP IP FLAGS CS SS(?:\sR\d+)*"
	# e.g.
	# AX BX CX DX SI DI BP SP IP FLAGS CS SS R8 R9 R10 R11 R12 R13 R14 R15

	INTR_REG0="AX"
fi

# enable for i386 (and i586 and )
if [[ "$MY_ARCH" =~ i[356]86 ]]; then
	INTR_REGISTERS_SUPPORT="yes"

	REGEX_INTR_REG_LIST="AX BX CX DX SI DI BP SP IP FLAGS CS SS DS ES FS GS"
	# e.g.
	# AX BX CX DX SI DI BP SP IP FLAGS CS SS DS ES FS GS

	INTR_REG0="AX"
fi

# enable for ppc64
if [[ "$MY_ARCH" =~ ppc64.* ]]; then
	INTR_REGISTERS_SUPPORT="yes"

	REGEX_INTR_REG_LIST="(?:r\d+\s+){16,}(?:(?:nip|msr|\w+)\s)"
	# e.g.
	# r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 r12 r13 r14 r15 r16 r17 r18 r19 r20 r21 r22 r23 r24 r25 r26 r27 r28 r29 r30 r31 nip msr orig_r3 ctr link xer ccr softe trap dar dsisr

	INTR_REG0="r0"
fi


# skip if not supported
if [ "$INTR_REGISTERS_SUPPORT" = "no" ]; then
	print_overall_skipped
	exit 0
fi


### intr registers list

# perf record -I\? should show intr registers
! $CMD_PERF record -I\? > /dev/null 2> $LOGS_DIR/intr_list.err
PERF_EXIT_CODE=$?

# check the registers
../common/check_all_patterns_found.pl "$REGEX_INTR_REG_LIST" < $LOGS_DIR/intr_list.err
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "list"
(( TEST_RESULT += $? ))


### basic sampling

# perf record --intr-regs=$REG should save the register's value to samples
$CMD_PERF record --intr-regs=$INTR_REG0 -o $CURRENT_TEST_DIR/perf.data $CURRENT_TEST_DIR/examples/load > /dev/null 2> $LOGS_DIR/intr_basic_record.err
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/intr_basic_record.err
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "basic sampling ($INTR_REG0) :: record"
(( TEST_RESULT += $? ))

# perf report -D should print the register values per samples
$CMD_PERF report -i $CURRENT_TEST_DIR/perf.data -D > $LOGS_DIR/intr_basic_report.log
PERF_EXIT_CODE=$?

# check that the values are in the report
REGEX_INTR_RESULT="\.+\s$INTR_REG0\s+0x$RE_NUMBER_HEX"
../common/check_all_patterns_found.pl "$REGEX_INTR_RESULT" "intr regs: mask 0x1" < $LOGS_DIR/intr_basic_report.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "basic sampling ($INTR_REG0) :: report"
(( TEST_RESULT += $? ))

# check that the report contains enough values
NO_OF_VALUES=`cat $LOGS_DIR/intr_basic_report.log | grep -P "$REGEX_INTR_RESULT" | wc -l`
NO_OF_SAMPLES=`cat $LOGS_DIR/intr_basic_record.err | perl -ne 'print "$1" if /(\d+)\ssamples\)/'`
test -z "$NO_OF_SAMPLES" && NO_OF_SAMPLES=0
test $NO_OF_VALUES -eq $NO_OF_SAMPLES
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "basic sampling ($INTR_REG0) :: report values count"
(( TEST_RESULT += $? ))


### using all registers

# without specifying the register, perf should capture values of all of them
$CMD_PERF record -I -o $CURRENT_TEST_DIR/perf.data $CURRENT_TEST_DIR/examples/load > /dev/null 2> $LOGS_DIR/intr_all_regs_record.err
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "$RE_LINE_RECORD1" "$RE_LINE_RECORD2" "perf.data" < $LOGS_DIR/intr_all_regs_record.err
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "using all registers :: record"
(( TEST_RESULT += $? ))

# perf report -D should print the register values per samples
$CMD_PERF report -i $CURRENT_TEST_DIR/perf.data -D > $LOGS_DIR/intr_all_regs_report.log
PERF_EXIT_CODE=$?

# check that the report contains enough values of all the registers
NO_OF_SAMPLES=`cat $LOGS_DIR/intr_all_regs_record.err | perl -ne 'print "$1" if /(\d+)\ssamples\)/'`
test -z "$NO_OF_SAMPLES" && NO_OF_SAMPLES=0
ALL_REGISTERS=`cat $LOGS_DIR/intr_list.err | grep available | sed 's/available registers: //'`
if [ -z "$ALL_REGISTERS" ]; then
	# if there are no available registers, we cannot check anything and it means a failure
	CHECK_EXIT_CODE=1
else
	# check if all the registers that are supported are really captured within the samples
	CHECK_EXIT_CODE=0
	for rg in $ALL_REGISTERS; do
		REGEX_INTR_RESULT="\.+\s$rg\s+0x$RE_NUMBER_HEX"
		NO_OF_VALUES=`cat $LOGS_DIR/intr_all_regs_report.log | grep -P "$REGEX_INTR_RESULT" | wc -l`

		# 128bit register tweak: XMM registers appear twice in the log, since their 128 valules are
		# stored as 64bit pairs
		echo $rg | grep -q -P '^XMM\d+$' && (( NO_OF_VALUES /= 2 ))

		test $NO_OF_VALUES -eq $NO_OF_SAMPLES
		(( CHECK_EXIT_CODE += $? ))
	done
fi

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "using all registers :: report values count"
(( TEST_RESULT += $? ))


# print overall results
print_overall_results "$TEST_RESULT"
exit $?
