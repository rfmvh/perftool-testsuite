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

# FIXME look for the cache dir to /etc/perfconfig
export BUILDIDDIR="$HOME/.debug"

clear_buildid_cache()
{
	rm -rf $BUILDIDDIR/*
}
