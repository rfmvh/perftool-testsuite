#
#	settings.sh of perf c2c test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		FIXME
#
#

export TEST_NAME="perf_c2c"
export MY_ARCH=`arch`
export MY_HOSTNAME=`hostname`
export MY_KERNEL_VERSION=`uname -r`
export MY_CPUS_ONLINE=`nproc`
export MY_CPUS_AVAILABLE=`cat /proc/cpuinfo | grep -P "processor\s" | wc -l`

export MEM_LOADS_SUPPORTED="yes"
export MEM_STORES_SUPPORTED="yes"
$CMD_PERF list | grep -q mem-loads || export MEM_LOADS_SUPPORTED="no"
$CMD_PERF list | grep -q mem-stores || export MEM_STORES_SUPPORTED="no"

# FIXME: either this or the previous code block is probably redundant
export LDLAT_LOADS_SUPPORTED="yes"
export LDLAT_STORES_SUPPORTED="yes"
$CMD_PERF mem record -e list |& grep -q ldlat-loads || export LDLAT_LOADS_SUPPORTED="no"
$CMD_PERF mem record -e list |& grep -q ldlat-stores || export LDLAT_STORES_SUPPORTED="yes"

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
