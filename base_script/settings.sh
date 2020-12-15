#
#	settings.sh of perf_script test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		FIXME
#
#

export TEST_NAME="perf_script"

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
