#!/bin/bash

# Converts yum repo into an rpm using fpm
#
# Expects:
#   - mount at /shared with service def rpm (and where repo rpm goes)
#   - mount at /scripts that contains this script
#   - $MIRROR_FILE is the filename of the mirror file to create
#   - $MIRROR_VERSION is the version number of the mirror file to create

# Create the repo metadata
yum -y install yum-utils createrepo rpm-build
createrepo /shared/rpmroot/opt/${MIRROR_DIRNAME}

# Create the detached gpg signature.
PASSPHRASE=$(curl -s http://artifacts.zenoss.loc/repos/.secret/passphrase)
gpg --batch --passphrase "${PASSPHRASE}" --detach-sign --armor /shared/rpmroot/opt/${MIRROR_DIRNAME}/repodata/repomd.xml

# Package the contents of /shared/rpmroot into a yum mirror RPM ($MIRROR_FILE)
cd /shared
fpm -s dir -t rpm -C /shared/rpmroot --name $MIRROR_FILE --version $MIRROR_VERSION .
chmod a+rw /shared/$MIRROR_FILE*
