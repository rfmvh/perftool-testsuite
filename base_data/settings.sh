#
#	settings.sh of perf_data test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		FIXME
#
#

export TEST_NAME="perf_data"

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

should_support_ctf_conversion()
{
	# return value
	# 0 = expected to support CTF conversion
	# 1 = not expected to support CTF conversion
	ldd `which $CMD_PERF` | grep -q 'libbabeltrace'
}
