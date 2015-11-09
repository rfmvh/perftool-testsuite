#
#	settings.sh of perf_annotate test
#	Author: Michael Petlan <mpetlan@redhat.com>
#
#	Description:
#		FIXME
#
#

export TEST_NAME="perf_annotate"
export MY_ARCH=`arch`
export MY_HOSTNAME=`hostname`
export MY_KERNEL_VERSION=`uname -r`
export MY_CPUS_ONLINE=`nproc`
export MY_CPUS_AVAILABLE=`cat /proc/cpuinfo | grep processor | wc -l`
