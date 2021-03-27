#
#	settings.sh of perf buildid test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		FIXME
#
#

export TEST_NAME="perf_buildid"
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

if [ ! "$THIS_TEST_NAME" = "cleanup" ]; then
	source settings_cache.sh
fi

support_buildids_vs_files_check()
{
	command -v file &> /dev/null
}

clear_buildid_cache()
{
	rm -rf $BUILDIDDIR/.b*
	rm -rf $BUILDIDDIR/*
}
