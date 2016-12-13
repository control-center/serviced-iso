#!/usr/bin/env bash


sudo yum -y --disablerepo\* --enablerepo=zenoss-mirror install \
  bash-completion \
  device-mapper-lib \
  device-mapper-event \
  device-mapper-event-libs \
  docker-engine-1.12.1 \
  rsync \
  lvm2

rpm -ivh --test ${CC_RPM_FILEPATH}
