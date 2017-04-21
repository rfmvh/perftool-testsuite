#
#	settings.sh of perf_record test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		FIXME
#
#

export TEST_NAME="perf_record"
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
