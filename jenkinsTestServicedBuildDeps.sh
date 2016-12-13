#!/bin/bash
set -e
set -x

if [ -z ${SERVICED_RPM} ]
then
  echo "ERROR: ${SERVICED_RPM} is undefined"
  exit 1
fi

SERVICED_ARTIFACT_BASENAME=serviced-1.2.0-1-stable-centos7.2.1511-bld-12
SERVICED_CENTOS_ISO_URL=http://artifacts.zenoss.eng/isos/serviced/${SERVICED_ARTIFACT_BASENAME}.iso
CHECKSUM_FILEPATH=${SERVICED_ARTIFACT_BASENAME}.md5sum.txt

wget -q http://artifacts.zenoss.eng/isos/serviced/${SERVICED_ARTIFACT_BASENAME}.md5sum.txt -O ${CHECKSUM_FILEPATH}
if [ ! -f ${CHECKSUM_FILEPATH} ]
then
  echo "ERROR: Cannot find ${CHECKSUM_FILEPATH}"
  exit 1
fi

SERVICED_CENTOS_ISO_CHECKSUM=`cat ${CHECKSUM_FILEPATH} | grep iso | awk '{print $1}'`

packer -machine-readable build -force -only=virtualbox-iso \
  -var iso_url=${SERVICED_CENTOS_ISO_URL} \
  -var iso_checksum=${SERVICED_CENTOS_ISO_CHECKSUM} \
  -var outputdir=./test-iso-output \
  -var cc_rpm=${SERVICED_RPM} \
  test-centos-base.json
