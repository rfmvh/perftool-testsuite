#
#	settings_cache.sh of perf archive test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		FIXME
#
#
if [ -z "$BUILDIDDIR" ]; then
	export BUILDIDDIR=${BUILDIDDIR:-"$HOME/.debug-`date +%s`"}
fi
if [ ! -d "$BUILDIDDIR" ]; then
	mkdir "$BUILDIDDIR"
	echo "$BUILDIDDIR" >> $CURRENT_TEST_DIR/BUILDIDDIRS
fi
