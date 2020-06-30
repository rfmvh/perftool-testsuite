#
#	settings.sh of perf_sched test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		FIXME
#
#

export TEST_NAME="perf_sched"

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
