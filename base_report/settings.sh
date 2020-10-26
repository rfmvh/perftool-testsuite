#
#	settings.sh of perf_report test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		FIXME
#
#

export TEST_NAME="perf_report"
export MY_ARCH=`arch`
export MY_HOSTNAME=`hostname`
export MY_KERNEL_VERSION=`uname -r`
export MY_CPUS_ONLINE=`nproc`
export MY_CPUS_AVAILABLE=`lscpu | grep '^CPU(s)' | awk '{print $2}'`

if [ -n "$PERFSUITE_RUN_DIR" ]; then
	# when $PERFSUITE_RUN_DIR is set to something, all the logs and temp files will be placed there
	# --> the $PERFSUITE_RUN_DIR/perf_something/examples and $PERFSUITE_RUN_DIR/perf_something/logs
	#     dirs will be used for that
	export PERFSUITE_RUN_DIR=`readlink -f $PERFSUITE_RUN_DIR`
	export CURRENT_TEST_DIR="$PERFSUITE_RUN_DIR/$TEST_NAME"
	test -d "$CURRENT_TEST_DIR" || mkdir -p "$CURRENT_TEST_DIR"
	export LOGS_DIR="$PERFSUITE_RUN_DIR/$TEST_NAME/logs"
	test -d "$LOGS_DIR" || mkdir -p "$LOGS_DIR"
	export HEADER_TAR_DIR="$PERFSUITE_RUN_DIR/$TEST_NAME/header_tar"
	test -d "$HEADER_TAR_DIR" || mkdir -p "$HEADER_TAR_DIR"
else
	# when $PERFSUITE_RUN_DIR is not set, logs will be placed here
	export CURRENT_TEST_DIR="."
	export LOGS_DIR="."
	export HEADER_TAR_DIR="./header_tar"
	test -d "$HEADER_TAR_DIR" || mkdir -p "$HEADER_TAR_DIR"
fi


should_support_expect_script()
{
	# return values:
	# 0 = expected to support expect script
	# 1 = expected not to support expect script

	type expect &> /dev/null
}
