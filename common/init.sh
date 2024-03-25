#
#	init.sh
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#
#		This file should be used for initialization of basic functions
#	for checking, reporting results etc.
#
#


. ../common/settings.sh
. ../common/patterns.sh

THIS_TEST_NAME=`basename $0 .sh`

if [ -f "settings_cache.sh" ] && [ ! "$THIS_TEST_NAME" = "cleanup" ]; then
	source settings_cache.sh
fi

# general functions
_echo()
{
	test "$TESTLOG_VERBOSITY" -ne 0 && echo -e "$@"
}

print_results()
{
	PERF_RETVAL="$1"; shift
	CHECK_RETVAL="$1"; shift
	FAILURE_REASON=""
	TASK_COMMENT="$*"
	if [ $PERF_RETVAL -eq 0 ] && [ $CHECK_RETVAL -eq 0 ]; then
		_echo "$MPASS-- [ PASS ] --$MEND $TEST_NAME :: $THIS_TEST_NAME :: $TASK_COMMENT"
		return 0
	else
		if [ $PERF_RETVAL -ne 0 ]; then
			FAILURE_REASON="command exitcode"
		fi
		if [ $CHECK_RETVAL -ne 0 ]; then
			test -n "$FAILURE_REASON" && FAILURE_REASON="$FAILURE_REASON + "
			FAILURE_REASON="$FAILURE_REASON""output regexp parsing"
		fi
		_echo "$MFAIL-- [ FAIL ] --$MEND $TEST_NAME :: $THIS_TEST_NAME :: $TASK_COMMENT ($FAILURE_REASON)"
		return 1
	fi
}

print_overall_results()
{
	RETVAL="$1"; shift
	if [ $RETVAL -eq 0 ]; then
		_echo "$MALLPASS## [ PASS ] ##$MEND $TEST_NAME :: $THIS_TEST_NAME SUMMARY"
	else
		_echo "$MALLFAIL## [ FAIL ] ##$MEND $TEST_NAME :: $THIS_TEST_NAME SUMMARY :: $RETVAL failures found"
	fi
	return $RETVAL
}

print_testcase_skipped()
{
	TASK_COMMENT="$*"
	_echo "$MSKIP-- [ SKIP ] --$MEND $TEST_NAME :: $THIS_TEST_NAME :: $TASK_COMMENT :: testcase skipped"
	return 0
}

print_overall_skipped()
{
	_echo "$MSKIP## [ SKIP ] ##$MEND $TEST_NAME :: $THIS_TEST_NAME :: testcase skipped"
	return 0
}

print_warning()
{
	WARN_COMMENT="$*"
	_echo "$MWARN-- [ WARN ] --$MEND $TEST_NAME :: $THIS_TEST_NAME :: $WARN_COMMENT"
	return 0
}

# this function should skip a testcase if the testsuite is not run in
# a runmode that fits the testcase --> if the suite runs in BASIC mode
# all STANDARD and EXPERIMENTAL testcases will be skipped; if the suite
# runs in STANDARD mode, all EXPERIMENTAL testcases will be skipped and
# if the suite runs in EXPERIMENTAL mode, nothing is skipped
consider_skipping()
{
	TESTCASE_RUNMODE="$1"
	# the runmode of a testcase needs to be at least the current suite's runmode
	if [ $PERFTOOL_TESTSUITE_RUNMODE -lt $TESTCASE_RUNMODE ]; then
		print_overall_skipped
		exit 0
	fi
}

detect_baremetal()
{
	# return values:
	# 0 = bare metal
	# 1 = virtualization detected
	# 2 = unknown state
	VIRT=`systemd-detect-virt 2>/dev/null`
	test $? -eq 127 && return 2
	test "$VIRT" = "none"
}

detect_intel()
{
	# return values:
	# 0 = is Intel
	# 1 = is not Intel or unknown
	grep "vendor_id" < /proc/cpuinfo | grep -q "GenuineIntel"
}

detect_amd()
{
	# return values:
	# 0 = is AMD
	# 1 = is not AMD or unknown
	grep "vendor_id" < /proc/cpuinfo | grep -q "AMD"
}

# following are functions for different testcases split
# into sections based on the dirs where they are utilized,
# merging of settings.sh files from the dirs

# BASE_ARCHIVE and BASE_BUILDID
clear_buildid_cache()
{
	if [ -n "$BUILDIDDIR" ]; then
		rm -rf $BUILDIDDIR/.b*
		rm -rf ${BUILDIDDIR:?}/*
	fi
}

#---------------------------------------------------------
# BASE_BUILDID
support_buildids_vs_files_check()
{
	command -v file &> /dev/null
}

#----------------------------------------------------------
# BASE_REPORT and BASE_TOP
should_support_expect_script()
{
	# return values:
	# 0 = expected to support expect script
	# 1 = expected not to support expect script

	type expect &> /dev/null
}

#----------------------------------------------------------
# BASE_DATA
should_support_ctf_conversion()
{
	# return value
	# 0 = expected to support CTF conversion
	# 1 = not expected to support CTF conversion
	ldd "`which $CMD_PERF`" | grep -q 'libbabeltrace'
}

#----------------------------------------------------------
# BASE_KMEM
support_output_parameter()
{
	$CMD_PERF kmem record -o /dev/null -- true &> /dev/null
}

#----------------------------------------------------------
# BASE_PROBE
check_kprobes_available()
{
	test -e /sys/kernel/debug/tracing/kprobe_events
}

check_uprobes_available()
{
	test -e /sys/kernel/debug/tracing/uprobe_events
}

clear_all_probes()
{
	echo 0 > /sys/kernel/debug/tracing/events/enable
	check_kprobes_available && echo > /sys/kernel/debug/tracing/kprobe_events
	check_uprobes_available && echo > /sys/kernel/debug/tracing/uprobe_events
}

# FIXME
check_perf_probe_option()
{ #option
	$PERF probe -h 2>&1 | egrep '[\t ]+'$1'[\t ]+' > /dev/null
}

#FIXME
check_kernel_debuginfo()
{
	eu-addr2line -k 0x"`grep -m 1 vfs_read /proc/kallsyms | cut -f 1 -d" "`" | grep vfs_read
}

check_sdt_support()
{
	$CMD_PERF list sdt | grep sdt > /dev/null 2> /dev/null
}

#------------------------------------------------------------------
# BASE_RECORD
should_test_callgraph_fp()
{
	# testing "fp" callgraph depends only on its config variable
	test "$PARAM_RECORD_CALLGRAPH_FP" = "y"
}

should_test_callgraph_dwarf()
{
	test -z "$PARAM_RECORD_CALLGRAPH_DWARF" && PARAM_RECORD_CALLGRAPH_DWARF="decide"
	case "$PARAM_RECORD_CALLGRAPH_DWARF" in
		"y")
			# run it
			return 0
			;;
		"n")
			# do NOT run it
			return 1
			;;
		*)
			# run it only on x86_64 and aarch64
			test "$MY_ARCH" = "x86_64" -o "$MY_ARCH" = "aarch64"
			return $?
			;;
	esac
}

should_support_intel_pt()
{
	# return values
	# 0 = expected to support Intel Processor Trace
	# 1 = not expected to support Intel Processor Trace

	$CMD_PERF list | grep -q 'intel_pt'
}

#----------------------------------------------------------------------------
# BASE_SCHED
NECESSARY_FD_LIMIT=8192

bump_fd_limit_if_needed()
{
	ORIGINAL_FD_LIMIT=`ulimit -n 2> /dev/null`
	if [ $ORIGINAL_FD_LIMIT -lt $NECESSARY_FD_LIMIT ]; then
		# current fd limit is too low, let's try to bump it
		ulimit -n $NECESSARY_FD_LIMIT
		# according to man pages, changing `ulimit -n` might be not supported
		# let's detect it and log if logging is verbose
		CURRENT_FD_LIMIT=`ulimit -n`
		test $CURRENT_FD_LIMIT -eq $ORIGINAL_FD_LIMIT && print_warning "open FD limit could not be set to $NECESSARY_FD_LIMIT and remains $CURRENT_FD_LIMIT"
	fi
}

restore_fd_limit_if_needed()
{
	test $CURRENT_FD_LIMIT -ne $ORIGINAL_FD_LIMIT && ulimit -n $ORIGINAL_FD_LIMIT
}

#-------------------------------------------------------------------------------
# BASE_SCRIPT
should_support_syscall_translations()
{
	# return values
	# 0 = expected to support syscall translations
	# 1 = not expected to support syscall translations
	test -z "$PYTHON" && /usr/bin/env python -V &>/dev/null && export PYTHON="/usr/bin/env python"
	test -z "$PYTHON" && /usr/bin/env python3 -V &>/dev/null && export PYTHON="/usr/bin/env python3"
	test -z "$PYTHON" && /usr/bin/env python2 -V &>/dev/null && export PYTHON="/usr/bin/env python2"
	test -z "$PYTHON" && /usr/libexec/platform-python -V &>/dev/null && export PYTHON="/usr/libexec/platform-python"
	test -z "$PYTHON" && export PYTHON="python"
	$PYTHON -c "import audit" 2>/dev/null
}

detect_Qt_Python_bindings()
{
	# return values
	# 0 = PySide package is installed
	# 1 = PySide package is not installed
	test -z "$PYTHON" && /usr/bin/env python -V &>/dev/null && export PYTHON="/usr/bin/env python"
	test -z "$PYTHON" && /usr/bin/env python3 -V &>/dev/null && export PYTHON="/usr/bin/env python3"
	test -z "$PYTHON" && /usr/bin/env python2 -V &>/dev/null && export PYTHON="/usr/bin/env python2"
	test -z "$PYTHON" && /usr/libexec/platform-python -V &>/dev/null && export PYTHON="/usr/libexec/platform-python"
	test -z "$PYTHON" && export PYTHON="python"
	$PYTHON -c "import PySide.QtSql" 2> /dev/null || $PYTHON -c "import PySide2.QtSql" 2> /dev/null
}

should_support_deltatime_option()
{
	# return value
	# 0 = expected to support --deltatime option
	# 1 = not expected to support --deltatime option
	perf script --help | grep -q "\-\-deltatime"
}

should_support_reltime_option()
{
	# return value
	# 0 = expected to support --reltime option
	# 1 = not expected to support --reltime option
	perf script --help | grep -q "\-\-reltime"
}

should_support_compaction_times_script()
{
	# return value
	# 0 = expected to support compaction-times script
	# 1 = not expected to support compaction-times script
	FIVE=`perf list | grep -P "compaction:mm_compaction_(?:begin|end|migratepages|isolate_migratepages|isolate_freepages)" | wc -l`
	test $FIVE -ge 5
}

should_support_tod_field()
{
	# return value
	# 0 = expected to support perf script -F+tod
	# 1 = expected not to support perf script -F+tod
	PERF_SCRIPT_FIELDS="`$CMD_PERF script -F 2>&1 >/dev/null | perl -ne 'print "$1\n" if /Fields:\s*(.*)/' | sed 's/,/ /g'`"
	echo $PERF_SCRIPT_FIELDS | grep -q "tod"
}

#----------------------------------------------------------------------------
# BASE_STAT
# NMI Watchdog may occupy one PMU counter which is not great for k+u=ku
# tests, since they need at least 3 counters (k, u, ku). That would not
# be a problem, but not all of the available counters are generic, so it
# may easily happen that we run out of usable counters for some event
# with NMI watchdog enabled

disable_nmi_watchdog_if_exists()
{
	test -e /proc/sys/kernel/nmi_watchdog || return 9
	stat -c '%A' /proc/sys/kernel/nmi_watchdog | grep -q 'w' || return 9
	NMI_WD_PREVIOUS_VALUE=`cat /proc/sys/kernel/nmi_watchdog`; export NMI_WD_PREVIOUS_VALUE
	echo 0 > /proc/sys/kernel/nmi_watchdog
	return $NMI_WD_PREVIOUS_VALUE
}

restore_nmi_watchdog_if_needed()
{
	test -n "$NMI_WD_PREVIOUS_VALUE" || return 9
	echo $NMI_WD_PREVIOUS_VALUE > /proc/sys/kernel/nmi_watchdog
	return $NMI_WD_PREVIOUS_VALUE
}


# The following functions detect whether the machine should support/test
# various microarchitecture specific features.

should_support_intel_uncore()
{
	# return values:
	# 0 = expected to support uncore
	# 1 = not expected to support uncore

	# virtual machines do not support uncore
	detect_baremetal || return 1

	# non-Intel CPUs do not support uncore
	detect_intel || return 1

	# only some models should support uncore
	# (taken from the arch/x86/kernel/cpu/perf_event_intel_uncore.c source file)
	UNCORE_COMPATIBLE="26 30 37 44    42 58 60 69 70 61 71   46 47   45   62   63   79 86   87   94"
	CURRENT_FAMILY=`head -n 25 /proc/cpuinfo | grep 'cpu family' | perl -pe 's/[^:]+:\s*//g'`
	CURRENT_MODEL=`head -n 25 /proc/cpuinfo | grep -v 'name' | grep 'model' | perl -pe 's/[^:]+:\s*//g'`
	test $CURRENT_FAMILY -eq 6 || return 1
	AUX=${UNCORE_COMPATIBLE/$CURRENT_MODEL/}
	! test "$UNCORE_COMPATIBLE" = "$AUX"
}


should_support_intel_rapl()
{
	# return values:
	# 0 = expected to support RAPL
	# 1 = not expected to support RAPL

	# virtual machines do not support RAPL
	detect_baremetal || return 1

	# non-Intel CPUs do not support RAPL
	detect_intel || return 1

	# only some models should support RAPL
	# (taken from the arch/x86/kernel/cpu/perf_event_intel_rapl.c source file)
	RAPL_COMPATIBLE="42 58  63 79  60 69 61 71  45 62  87"
	CURRENT_FAMILY=`head -n 25 /proc/cpuinfo | grep 'cpu family' | perl -pe 's/[^:]+:\s*//g'`
	CURRENT_MODEL=`head -n 25 /proc/cpuinfo | grep -v 'name' | grep 'model' | perl -pe 's/[^:]+:\s*//g'`
	test $CURRENT_FAMILY -eq 6 || return 1
	AUX=${RAPL_COMPATIBLE/$CURRENT_MODEL/}
	! test "$RAPL_COMPATIBLE" = "$AUX"
}


should_support_pmu()
{
	# return values
	# 0 = expected to support PMU
	# 1 = not expected to support PMU

	# everything except s390x is expected to support PMU
	! test "$MY_ARCH" = "s390x"
}


should_support_hw_breakpoints()
{
	# return values
	# 0 = expected to support HW breakpoints
	# 1 = not expected to support HW breakpoints

	# ppc64le does not support hw breakpoints on Linux
	test "$MY_ARCH" = "ppc64le" && return 1

	# s390x does not support hw breakpoints on Linux
	test "$MY_ARCH" = "s390x" && return 1

	# aarch64 hw breakpoint interface is broken/obsoleted
	test "$MY_ARCH" = "aarch64" && return 1

	# when mem:<addr>[/len][:access] event is listed, we expect it
	# to be supported (currently, this is always true in perf)
	$CMD_PERF list | grep -q '\[Hardware breakpoint\]'
}

should_support_hw_watchpoints()
{
	# return values
	# 0 = expected to support HW watchpoints
	# 1 = not expected to support HW watchpoints

	# POWER9 does not support hw watchpoints due to a HW bug
	# POWER8 should support them
	test "$MY_ARCH" = "ppc64le" && grep -q 'POWER9' /proc/cpuinfo && return 1

	# s390x does not support hw watchpoints on Linux
	test "$MY_ARCH" = "s390x" && return 1

	# aarch64 hw watchpoint interface is broken/obsoleted
	test "$MY_ARCH" = "aarch64" && return 1

	# when mem:<addr>[/len][:access] event is listed, we expect it
	# to be supported (currently, this is always true in perf)
	$CMD_PERF list | grep -q '\[Hardware breakpoint\]'
}
