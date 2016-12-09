#!/bin/bash

set -x
pwd

mkdir -p /home/centos/tmp
cd /home/centos/tmp

# Get yumdownloader
sudo yum -y install yum-utils

#
# Get a list of OS RPMs that need to be updated, then use yumdownloader to get
# each of those RPMs, and their dependencies
#
yum makecache fast
RPMS=`yum --quiet list updates | grep -v 'Updated Packages' | awk '{print $1}'`
for rpm in $RPMS
do
	yumdownloader --resolve $rpm 
done

# Add in all of the other utilities that we want on the appliance images
yumdownloader --resolve telnet
yumdownloader --resolve nmap-ncat
yumdownloader --resolve ntp
yumdownloader --resolve zip
yumdownloader --resolve unzip
yumdownloader --resolve nano
yumdownloader --resolve yum-utils

tar -czvf ../centos7-rpms.tar.gz ./*.rpm

