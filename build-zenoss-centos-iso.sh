#!/usr/bin/env bash

# Step 1 Build Dependencies tarball
# inputs: centos-7.2.1511 iso, or centos-7.2.1511 VM
# outputs: tarball of RPMS,
packer -machine-readable build -force -only=virtualbox-iso vm-dependencies.json
# upload newly created vm file to artifacts

# Step 1.2
packer -machine-readable build -force -only=virtualbox-ovf vm-get-update-pkgs.json

# Step 2 Build iso-build image
# inputs: makeiso.sh, centos7-rpms.tar.gz
# outputs: iso-build Docker image
mv centos7-rpms.tar.gz builder/.
pushd builder/
docker build -t iso-build:latest .
popd

# Step 3 Create zenoss-centos ISO file
# inputs: centos_version, iso_build_number
# outputs: output/zenoss-centos-<CENTOS_VERSION>-<ISO_BUILD_NUMBER>-x86_64.iso
mkdir -p output
python create_iso.py --build-dir=./output --centos-version=$CENTOS_VERSION

# Step 4 Test newly created ISO file
# inputs: newly build zenoss-centos ISO
# output: a Centos VM based on the ISO that was just built
