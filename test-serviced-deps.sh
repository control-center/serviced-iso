#!/usr/bin/env bash
set -e
set -x

cd $CC_RPM_DIR
sudo yum -y localinstall --disablerepo=\* --enablerepo=zenoss-mirror ${CC_RPM_FILENAME}
