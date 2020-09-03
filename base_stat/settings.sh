#
#	settings.sh of perf_stat test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		FIXME
#
#

export TEST_NAME="perf_stat"
export MY_ARCH=`arch`
export MY_HOSTNAME=`hostname`
export MY_KERNEL_VERSION=`uname -r`
export MY_CPUS_ONLINE=`nproc`
export MY_CPUS_AVAILABLE=`cat /proc/cpuinfo | grep -P "processor\s" | wc -l`

if [ -n "$PERFSUITE_RUN_DIR" ]; then
	# when $PERFSUITE_RUN_DIR is set to something, all the logs and temp files will be placed there
	# --> the $PERFSUITE_RUN_DIR/perf_something/examples and $PERFSUITE_RUN_DIR/perf_something/logs
	#     dirs will be used for that
	export PERFSUITE_RUN_DIR=`readlink -f $PERFSUITE_RUN_DIR`
	export CURRENT_TEST_DIR="$PERFSUITE_RUN_DIR/$TEST_NAME"
	test -d "$CURRENT_TEST_DIR" || mkdir -p "$CURRENT_TEST_DIR"
	export LOGS_DIR="$PERFSUITE_RUN_DIR/$TEST_NAME/logs"
	test -d "$LOGS_DIR" || mkdir -p "$LOGS_DIR"
else
	# when $PERFSUITE_RUN_DIR is not set, logs will be placed here
	export CURRENT_TEST_DIR="."
	export LOGS_DIR="."
fi

# NMI Watchdog may occupy one PMU counter which is not great for k+u=ku
# tests, since they need at least 3 counters (k, u, ku). That would not
# be a problem, but not all of the available counters are generic, so it
# may easily happen that we run out of usable counters for some event
# with NMI watchdog enabled

disable_nmi_watchdog_if_exists()
{
	test -e /proc/sys/kernel/nmi_watchdog || return 9
	stat -c '%A' /proc/sys/kernel/nmi_watchdog | grep -q 'w' || return 9
	export NMI_WD_PREVIOUS_VALUE=`cat /proc/sys/kernel/nmi_watchdog`
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
