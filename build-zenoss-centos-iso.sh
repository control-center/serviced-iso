#!/usr/bin/env bash
# print stack trace
set -o errtrace
trap 'echo "Error occurred on $FUNCNAME."' ERR

if [ -z "${CENTOS_ISO}" ]
then
    echo "ERROR: CENTOS_ISO undefined"
    exit 1
fi

if [ -z "${ISO_CHECKSUM}" ]
then
    echo "ERROR: ISO_CHECKSUM undefined"
    exit 1
fi

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

case "${CENTOS_ISO}" in
   *1511*)
	CENTOS_ABBREV=centos7.2.1511
	;;

   *1503*)
	CENTOS_ABBREV=centos7.1.1503
	;;

   *)
	echo "ERROR: CENTOS_ISO='${CENTOS_ISO}' does not contain one of the recognized versions: 1511 or 1503"
	exit 1
	;;
esac

ISO_FILENAME=${CENTOS_ISO}.iso
ISO_FILEPATH=$HOME/isos/${ISO_FILENAME}
RPM_TARFILE=${CENTOS_ISO}-rpm-updates.tar.gz
BUILD_DIR=./output

export PACKER_CACHE_DIR="${HOME}/packer_cache"
export PACKER_LOG=1
export PACKER_LOG_PATH="$(readlink -e ${BUILD_DIR})/packer.log"

if [ -z "$BUILD_NUMBER" ]
then
    BUILD_NUMBER="dev"
fi

# Step 0 Download the ISO if it's not cached already
if [ ! -f ${ISO_FILEPATH} ]
then
    echo "Downloading ${ISO_FILENAME}"
    wget -q http://artifacts.zenoss.eng/isos/${ISO_FILENAME} -O ${ISO_FILEPATH}
fi

if [ -z ${ISO_FILEPATH} ]
then
    echo "ERROR: Can not find ${ISO_FILEPATH}"
    exit 1
fi

set -x
set -e
pwd
rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}

# Step 1 Build a VM from the Centos ISO
#
# Use -only=virtualbox-iso to test with VirtualBox instead of VMWare
packer -machine-readable build -force \
	-only=vmware-iso \
	-var iso_url=file:${ISO_FILEPATH} \
	-var iso_checksum=${ISO_CHECKSUM} \
	-var centos_iso=${CENTOS_ISO} \
	-var outputdir=${BUILD_DIR} \
	centos-base.json

# Step 2 Start the VM from step 1 to build a tarball of OS and
#        third-party RPMs from "yum updates"
#
# To test with VirtualBox instead of VMWare, use:
# -only=virtualbox-ovf -var vm_source=${BUILD_DIR}/${CENTOS_ISO}.ovf
packer -machine-readable build -force \
	-only=vmware-vmx \
	-var vm_source=${BUILD_DIR}/${CENTOS_ISO}.vmx \
	-var cc_repo=${CC_REPO} \
	-var cc_rpm=${CC_RPM} \
	-var rpm_tarfile=${RPM_TARFILE} \
	-var outputdir=${BUILD_DIR} \
	vm-get-update-pkgs.json

# Step 3 Create the offline mirror based on the tar file
#
OUTPUT_NAME="${CC_RPM}-${CC_REPO}-${CENTOS_ABBREV}-bld-${BUILD_NUMBER}"
OUTPUT_RPM="${OUTPUT_NAME}.rpm"
python ./create_mirror.py \
	--build-dir=${BUILD_DIR} \
	--build-number=${BUILD_NUMBER} \
	--base-iso=${CENTOS_ISO} \
	--cc-repo=${CC_REPO} \
	--cc-rpm=${CC_RPM} \
	--rpm-tarfile=${RPM_TARFILE} \
	--output-name=${OUTPUT_RPM}

# Step 3 Create zenoss-centos ISO file that includes the files from the
#        tarball in a separate directory
# inputs: a CentOS ISO file, and a tarball of updated RPMs
# outputs: output/zenoss-<CENTOS_ISO>-bld-<BUILD_NUMBER>.iso
cp ${ISO_FILEPATH} ${BUILD_DIR}
OUTPUT_ISO="${OUTPUT_NAME}.iso"
python create_iso.py \
	--build-dir=${BUILD_DIR} \
	--build-number=${BUILD_NUMBER} \
	--base-iso=${CENTOS_ISO} \
	--cc-repo=${CC_REPO} \
	--cc-rpm=${CC_RPM} \
	--rpm-tarfile=${RPM_TARFILE} \
	--output-name=${OUTPUT_ISO}


# Step 5 Test newly created ISO file
# inputs: newly build zenoss-centos ISO
# output: a Centos VM based on the ISO that was just built
