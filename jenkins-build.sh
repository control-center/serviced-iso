#!/bin/bash
#
# This script is intended to be called from a Jenkins job to rebuild the
# serviced base ISOs
#
if [ -z "${CC_REPO}" ]
then
    echo "ERROR: CC_REPO undefined"
    exit 1
fi

if [ -z "${CC_RPM}" ]
then
    echo "ERROR: CC_RPM undefined"
    exit 1
fi

export CENTOS_ISO=CentOS-7-x86_64-Minimal-1511
export ISO_CHECKSUM=88c0437f0a14c6e2c94426df9d43cd67
./build-zenoss-centos-iso.sh

export CENTOS_ISO=CentOS-7-x86_64-Minimal-1503-01
export ISO_CHECKSUM=d07ab3e615c66a8b2e9a50f4852e6a77
./build-zenoss-centos-iso.sh
