#!/bin/bash

# Builds an installable Zenoss ISO appliance
#
# Expects:
#   - /build the directory with the build bundle
#     (must include /build/manifest.json)
#   - /common the directory with shared appliance files
#   - /output the directory where the resulting ISO goes

# ZENOSS_TYPE=$(python -c "import json; print json.load(open('/build/manifest.json'))['type']")
# ZENOSS_VERSION=$(python -c "import json; print json.load(open('/build/manifest.json'))['zenoss-version']")
# ZENOSS_BUILD=$(python -c "import json; print json.load(open('/build/manifest.json'))['zenoss-build']")

ISO_ID="Zenoss_CentOS_Install"
echo "Building ISO for CentOS $CENTOS_VERSION, build number $BUILD_NUMBER"
ISO_FILENAME="zenoss-centos-$CENTOS_VERSION-$BUILD_NUMBER.x86_64.iso"

cd /

# make working directory
mkdir -p working

# copy from iso to working dir; make sure and capture all files via tar
mkdir isomount && mount -o loop /centos.iso /isomount
cd isomount && tar -cf - . | ( cd ../working ; tar -xpf - )
cd / && umount isomount && rmdir isomount

# iso's are read-only; chmod so we can update files
chmod +w -R working
# remove TRANS.TBL files
find working -name TRANS.TBL -exec rm -f {} \; -print

# update RPM repo with newer files
yum makecache fast
echo 'About to copy packages'
mkdir working/zenoss-repo
cd working/zenoss-repo
# cd working/Packages
# ls .
gunzip /centos7-rpms.tar.gz
tar -xf /centos7-rpms.tar
# createrepo -p --update --update-md-path=.. --outputdir=.. \
#   --unique-md \
#   --groupfile=/working/repodata/c30db98d87c9664d3e52acad6596f6968b4a2c6974c80d119137a804c15cdf86-c7-minimal-x86_64-comps.xml .
# ls .
createrepo -p --unique-md .
# pwd
# ls .
echo 'Done copying packages'
cd /

# stage files needed on appliance
mkdir working/zenoss
# cp -r build working/zenoss
# cp -r common working/zenoss

# cat <<EOF > working/zenoss/zenoss-local.repo
# [zenoss-local]
# name=Zenoss 5.2.x Centos 7 Dependencies
# baseurl=file:///working/Packages
# enabled=1
# gpgcheck=0
# EOF

# install kickstart and modify boot config
cp zenoss-5-ks.cfg working/zenoss/ks.cfg
sed -i "s/DEFAULT_HOSTNAME/zenoss-centos/g" working/zenoss/ks.cfg
sed -i "s/DEFAULT_PASSWORD/zenoss/g" working/zenoss/ks.cfg
cp -f isolinux.cfg working/isolinux/
sed -i "s/APPLIANCE_ISO_TITLE/Zenoss CentOS/g" working/isolinux/isolinux.cfg
# if [ "$ZENOSS_TYPE" == "core" ] ; then
#   sed -i "s/APPLIANCE_ISO_TITLE/Zenoss Core/g" working/isolinux/isolinux.cfg
# fi
# if [ "$ZENOSS_TYPE" == "resmgr" ] ; then
#   sed -i "s/APPLIANCE_ISO_TITLE/Zenoss Resource Manager/g" working/isolinux/isolinux.cfg
# fi
# if [ "$ZENOSS_TYPE" == "ucspm" ] ; then
#   sed -i "s/APPLIANCE_ISO_TITLE/UCS Performance Manager/g" working/isolinux/isolinux.cfg
# fi
sed -i "s/APPLIANCE_ISO_ID/$ISO_ID/g" working/isolinux/isolinux.cfg

# build ISO
cd working
du -h
chmod 664 isolinux/isolinux.bin
mkisofs -o /output/$ISO_FILENAME \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot \
        -joliet-long \
        -V "$ISO_ID" \
        -boot-load-size 4 \
        -boot-info-table \
        -R -J -v -T .

chmod a+rw /output/$ISO_FILENAME
