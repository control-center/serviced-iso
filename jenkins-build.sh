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

CONSOLIDATED_OUTPUT=./consolidated-output
rm -rf ${CONSOLIDATED_OUTPUT}
mkdir -p ${CONSOLIDATED_OUTPUT}

set -e

export CENTOS_ISO=CentOS-7-x86_64-Minimal-2009
export ISO_CHECKSUM=a4711c4fa6a1fb32bd555fae8d885b12
./build-serviced-iso.sh

export CENTOS_ISO=CentOS-7-x86_64-Minimal-2003
export ISO_CHECKSUM=f99e2b01389c62a56bb0d3afdbc202f2
./build-serviced-iso.sh

export CENTOS_ISO=CentOS-7-x86_64-Minimal-1810
export ISO_CHECKSUM=bd43d41e01c2a46b3cb23eb9139dce4b
./build-serviced-iso.sh

export CENTOS_ISO=CentOS-7-x86_64-Minimal-1804
export ISO_CHECKSUM=fabdc67ff3a1674a489953effa285dfd
./build-serviced-iso.sh

export CENTOS_ISO=CentOS-7-x86_64-Minimal-1708
export ISO_CHECKSUM=5848f2fd31c7acf3811ad88eaca6f4aa
./build-serviced-iso.sh

export CENTOS_ISO=CentOS-7-x86_64-Minimal-1611
export ISO_CHECKSUM=d2ec6cfa7cf6d89e484aa2d9f830517c
./build-serviced-iso.sh

export CENTOS_ISO=CentOS-7-x86_64-Minimal-1511
export ISO_CHECKSUM=88c0437f0a14c6e2c94426df9d43cd67
./build-serviced-iso.sh

export CENTOS_ISO=CentOS-7-x86_64-Minimal-1503-01
export ISO_CHECKSUM=d07ab3e615c66a8b2e9a50f4852e6a77
./build-serviced-iso.sh

#
# Consolidate all of the artifacts in a single directory
#
mv -f ./output-centos*/update-os* ${CONSOLIDATED_OUTPUT}
mv -f ./output-centos*/serviced* ${CONSOLIDATED_OUTPUT}
mv -f ./output-centos*/*.tar.gz ${CONSOLIDATED_OUTPUT}
mv -f ./output-centos*/packer*.log ${CONSOLIDATED_OUTPUT}
