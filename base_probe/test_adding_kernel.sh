#
#	test_adding_kernel of perf_probe test
#	Author: Masami Hiramatsu <masami.hiramatsu.pt@hitachi.com>
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This test tests adding of probes, their correct listing
#		and removing.
#

# include working environment
. ../common/settings.sh
. ../common/patterns.sh
. ../common/init.sh
. ./settings.sh

THIS_TEST_NAME=`basename $0`
TEST_RESULT=0

TEST_PROBE="vfs_read"


### basic probe adding

for opt in "" "-a" "--add"; do
	clear_all_probes
	$CMD_PERF probe $opt $TEST_PROBE 2> adding_kernel_add$opt.err
	PERF_EXIT_CODE=$?

	../common/check_all_patterns_found.pl "Added new event:" "probe:$TEST_PROBE" "on $TEST_PROBE" < adding_kernel_add$opt.err
	CHECK_EXIT_CODE=$?

	print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "adding probe $TEST_PROBE :: $opt"
	(( TEST_RESULT += $? ))
done


### listing added probe :: perf list

# any added probes should appear in perf-list output
$CMD_PERF list probe:\* > adding_kernel_list.log
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$RE_LINE_EMPTY" "List of pre-defined events" "probe:$TEST_PROBE\s+\[Tracepoint event\]" < adding_kernel_list.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "listing added probe :: perf list"
(( TEST_RESULT += $? ))


### listing added probe :: perf probe -l

# '-l' should list all the added probes as well
$CMD_PERF probe -l > adding_kernel_list-l.log
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "\s*probe:$TEST_PROBE\s+\(on $TEST_PROBE@.+\)" < adding_kernel_list-l.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "listing added probe :: perf probe -l"
(( TEST_RESULT += $? ))


### using added probe

$CMD_PERF stat -e probe:$TEST_PROBE -o adding_kernel_using_probe.log -- cat /proc/uptime > /dev/null
PERF_EXIT_CODE=$?

REGEX_STAT_HEADER="\s*Performance counter stats for \'cat /proc/uptime\':"
# the value should be greater than 1
REGEX_STAT_VALUES="\s*[1-9][0-9]*\s+probe:$TEST_PROBE"
REGEX_STAT_TIME="\s*$RE_NUMBER\s+seconds time elapsed"
../common/check_all_lines_matched.pl "$REGEX_STAT_HEADER" "$REGEX_STAT_VALUES" "$REGEX_STAT_TIME" "$RE_LINE_COMMENT" "$RE_LINE_EMPTY" < adding_kernel_using_probe.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "using added probe"
(( TEST_RESULT += $? ))


### removing added probe

# '-d' should remove the probe
$CMD_PERF probe -d $TEST_PROBE 2> adding_kernel_removing.err
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "Removed event: probe:$TEST_PROBE" < adding_kernel_removing.err
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "deleting added probe"
(( TEST_RESULT += $? ))


### listing removed probe

# removed probes should NOT appear in perf-list output
$CMD_PERF list probe:\* > adding_kernel_list_removed.log
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "$RE_LINE_EMPTY" "List of pre-defined events" < adding_kernel_list_removed.log
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "listing removed probe (should NOT be listed)"
(( TEST_RESULT += $? ))


### dry run

# the '-n' switch should run it in dry mode
$CMD_PERF probe -n --add $TEST_PROBE 2> adding_kernel_dryrun.err
PERF_EXIT_CODE=$?

# check for the output (should be the same as usual)
../common/check_all_patterns_found.pl "Added new event:" "probe:$TEST_PROBE" "on $TEST_PROBE" < adding_kernel_dryrun.err
CHECK_EXIT_CODE=$?

# check that no probe was added in real
! ( $CMD_PERF probe -l | grep "probe:$TEST_PROBE" )
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "dry run :: adding probe"
(( TEST_RESULT += $? ))


### force-adding probes

# when using '--force' a probe should be added even if it is already there
$CMD_PERF probe --add $TEST_PROBE 2> adding_kernel_forceadd_01.err
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "Added new event:" "probe:$TEST_PROBE" "on $TEST_PROBE" < adding_kernel_forceadd_01.err
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "force-adding probes :: first probe adding"
(( TEST_RESULT += $? ))

# adding existing probe without '--force' should fail
! $CMD_PERF probe --add $TEST_PROBE 2> adding_kernel_forceadd_02.err
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "Error: event \"$TEST_PROBE\" already exists." "Error: Failed to add events." < adding_kernel_forceadd_02.err
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "force-adding probes :: second probe adding (without force)"
(( TEST_RESULT += $? ))

# adding existing probe with '--force' should pass
$CMD_PERF probe --force --add $TEST_PROBE 2> adding_kernel_forceadd_03.err
PERF_EXIT_CODE=$?

../common/check_all_patterns_found.pl "Added new event:" "probe:${TEST_PROBE}_1" "on $TEST_PROBE" < adding_kernel_forceadd_03.err
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "force-adding probes :: second probe adding (with force)"
(( TEST_RESULT += $? ))


### using doubled probe

# since they are the same, they should produce the same results
$CMD_PERF stat -e probe:$TEST_PROBE -e probe:${TEST_PROBE}_1 -x';' -o adding_kernel_using_two.log -- bash -c 'cat /proc/cpuinfo > /dev/null'
PERF_EXIT_CODE=$?

REGEX_LINE="$RE_NUMBER;+probe:${TEST_PROBE}_?1?;$RE_NUMBER;$RE_NUMBER"
../common/check_all_lines_matched.pl "$REGEX_LINE" "$RE_LINE_EMPTY" "$RE_LINE_COMMENT" < adding_kernel_using_two.log
CHECK_EXIT_CODE=$?

VALUE_1=`grep "$TEST_PROBE;" adding_kernel_using_two.log | awk -F';' '{print $1}'`
VALUE_2=`grep "${TEST_PROBE}_1;" adding_kernel_using_two.log | awk -F';' '{print $1}'`

test $VALUE_1 -eq $VALUE_2
(( CHECK_EXIT_CODE += $? ))

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "using doubled probe"


### removing multiple probes

# using wildcards should remove all matching probes
$CMD_PERF probe --del \* 2> adding_kernel_removing_wildcard.err
PERF_EXIT_CODE=$?

../common/check_all_lines_matched.pl "Removed event: probe:$TEST_PROBE" "Removed event: probe:${TEST_PROBE}_1" < adding_kernel_removing_wildcard.err
CHECK_EXIT_CODE=$?

print_results $PERF_EXIT_CODE $CHECK_EXIT_CODE "removing multiple probes"
(( TEST_RESULT += $? ))


# print overall resutls
print_overall_results "$TEST_RESULT"
exit $?
