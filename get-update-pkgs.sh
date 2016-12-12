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

# Install the Zenoss repo so
curl -sO http://get.zenoss.io/yum/zenoss-repo-1-1.x86_64.rpm
sudo yum localinstall -y zenoss-repo-1-1.x86_64.rpm

sudo cat <<EOF > /etc/yum.repos.d/docker.repo
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

# Use yumdownloader to get all 3rd-party dependencies for CC
yumdownloader --enablerepo=zenoss-$CC_REPO --resolve $CC_RPM

# Remove the CC package, so that we only bundling non-zenoss RPMs.
rm $CC_RPM*

# Add in all of the other utilities that we want on the appliance images
yumdownloader --resolve telnet
yumdownloader --resolve nmap-ncat
yumdownloader --resolve ntp
yumdownloader --resolve zip
yumdownloader --resolve unzip
yumdownloader --resolve nano
yumdownloader --resolve yum-utils

tar -czvf ../centos7-rpms.tar.gz ./*.rpm

