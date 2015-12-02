#
#	settings.sh of perf_report test
#	Author: Michael Petlan <mpetlan@redhat.com>
#	Author: Masami Hiramatsu <masami.hiramatsu.pt@hitachi.com>
#
#	Description:
#		FIXME
#
#

export TEST_NAME="perf_probe"

export MY_ARCH=`arch`

check_kprobes_available()
{
	grep -q kprobe_register /proc/kallsyms
}

check_uprobes_available()
{
	grep -q uprobe_register /proc/kallsyms
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
	eu-addr2line -k 0x`grep -m 1 vfs_read /proc/kallsyms | cut -f 1 -d" "` | grep vfs_read
}
