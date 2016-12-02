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
cd /working/Packages

# while read pkg; do
#   yumdownloader --resolve $pkg
# done </build/dependencies.txt

createrepo -pgo .. .
cd /

# stage files needed on appliance
mkdir working/zenoss
cp -r build working/zenoss
cp -r common working/zenoss

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
chmod 664 isolinux/isolinux.bin
mkisofs -o /output/$ISO_FILENAME \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot \
        -V "$ISO_ID" \
        -boot-load-size 4 \
        -boot-info-table \
        -R -J -v -T .

chmod a+rw /output/$ISO_FILENAME
