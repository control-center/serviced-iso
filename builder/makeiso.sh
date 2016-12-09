#!/bin/bash

# Builds an installable Zenoss ISO appliance
#
# Expects:
#   - /build the directory with the build bundle
#     (must include /build/manifest.json)
#   - /common the directory with shared appliance files
#   - /output the directory where the resulting ISO goes

ISO_ID="Zenoss_CentOS_Install"
echo "Building ISO $ISO_FILENAME"

cd /

# make working directory
mkdir -p working

if [ -z "$BASE_ISO_NAME" ]
then
    echo "ERROR: BASE_ISO_NAME not defined"
    exit 1
elif [ ! -f /mnt/build/$BASE_ISO_NAME ]
then
    echo "ERROR: /mnt/build/$BASE_ISO_NAME not found"
    exit 1
fi

if [ -z "$RPM_TARFILE" ]
then
    echo "ERROR: RPM_TARFILE not defined"
    exit 1
elif [ ! -f /mnt/build/$RPM_TARFILE ]
then
    echo "ERROR: /mnt/build/$RPM_TARFILE not found"
    exit 1
fi

set -x
set -e

# copy from iso to working dir; make sure and capture all files via tar
echo "Copying $BASE_ISO_NAME ..."
mkdir isomount && mount -o loop /mnt/build/$BASE_ISO_NAME /isomount
cd isomount && tar -cf - . | ( cd ../working ; tar -xpf - )
cd / && umount isomount && rmdir isomount

# iso's are read-only; chmod so we can update files
chmod +w -R working
# remove TRANS.TBL files
find working -name TRANS.TBL -exec rm -f {} \; -print

echo "Unpacking $RPM_TARFILE ..."
mkdir working/centos-updates
cd working/centos-updates
tar xvfz /mnt/build/$RPM_TARFILE

echo 'Creating repo ...'
createrepo -p --unique-md .
echo 'Done copying packages'
cd /

# stage files needed on appliance
mkdir working/zenoss

# install kickstart and modify boot config
cp zenoss-5-ks.cfg working/zenoss/ks.cfg
sed -i "s/DEFAULT_HOSTNAME/zenoss-centos/g" working/zenoss/ks.cfg
sed -i "s/DEFAULT_PASSWORD/zenoss/g" working/zenoss/ks.cfg
cp -f isolinux.cfg working/isolinux/
sed -i "s/APPLIANCE_ISO_TITLE/Zenoss CentOS/g" working/isolinux/isolinux.cfg
sed -i "s/APPLIANCE_ISO_ID/$ISO_ID/g" working/isolinux/isolinux.cfg

# build ISO
cd working
du -h
chmod 664 isolinux/isolinux.bin
mkisofs -o /mnt/output/$ISO_FILENAME \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot \
        -joliet-long \
        -V "$ISO_ID" \
        -boot-load-size 4 \
        -boot-info-table \
        -R -J -v -T .

chmod a+rw /mnt/output/$ISO_FILENAME
