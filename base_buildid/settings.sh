#
#	settings.sh of perf buildid test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		FIXME
#
#

export TEST_NAME="perf_buildid-cache"
export MY_ARCH=`arch`
export MY_HOSTNAME=`hostname`
export MY_KERNEL_VERSION=`uname -r`
export MY_CPUS_ONLINE=`nproc`
export MY_CPUS_AVAILABLE=`cat /proc/cpuinfo | grep processor | wc -l`

export BUILDIDDIR=${BUILDIDDIR:-"$HOME/.debug-`date +%s`"}
test -d "$BUILDIDDIR" || mkdir "$BUILDIDDIR"

clear_buildid_cache()
{
	rm -rf $BUILDIDDIR/*
}

remove_buildid_cache()
{
	clear_buildid_cache
	rmdir $BUILDIDDIR
}
