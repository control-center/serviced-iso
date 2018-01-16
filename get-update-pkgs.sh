#!/bin/bash

set -x
set -e
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
yumdownloader --resolve sysstat
yumdownloader --resolve yum-utils
yumdownloader --resolve wget
yumdownloader --resolve python-chardet
yumdownloader --resolve cloud-init
yumdownloader --resolve open-vm-tools
yumdownloader --resolve tcpdump
yumdownloader --resolve dnsmasq
yumdownloader --resolve bind-utils

tar -czvf ../centos7-os-rpms.tar.gz ./*.rpm

# Install the Zenoss repo so
curl -sO http://get.zenoss.io/yum/zenoss-repo-1-1.x86_64.rpm
sudo yum localinstall -y zenoss-repo-1-1.x86_64.rpm

sudo chmod 777 /etc/yum.repos.d
sudo cat <<EOF > /etc/yum.repos.d/docker-ce.repo
[docker-ce-stable]
name=Docker CE Stable - x86_64
baseurl=https://download.docker.com/linux/centos/7/x86_64/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF

# Use yumdownloader to get all 3rd-party dependencies for CC
yumdownloader --enablerepo=zenoss-$CC_REPO --resolve $CC_RPM --setopt=obsoletes=0

# Remove the CC package, so that we only bundling non-zenoss RPMs.
rm -f serviced* zenoss*

tar -czvf ../centos7-rpms.tar.gz ./*.rpm
