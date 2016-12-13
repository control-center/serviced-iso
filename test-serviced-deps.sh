#!/usr/bin/env bash
set -e
set -x

cd $CC_RPM_DIR
sudo yum -y localinstall --disablerepo=\* --enablerepo=zenoss-mirror ${CC_RPM_FILENAME}

if [ "$?" -ne 0]
then
  echo "Error: Serviced dependency verifcation failed"
  exit 1
fi

echo "${CC_RPM_FILENAME} install succeeded."
echo "JOB DONE"
