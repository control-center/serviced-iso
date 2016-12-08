#!/usr/bin/bash

# Step 1 Build Dependencies tarball
# inputs: centos-7.2.1511 iso, or centos-7.2.1511 VM
# outputs: tarball of RPMS,
curl -sO http://artifacts.zenoss.eng/isos/prereqs/zenoss-centos-7.2.1511.tar.gz
if [ -e zenoss-centos-7.2.1511.tar.gz ]
then
  pushd prereqs
  tar -xzvf zenoss-centos-7.2.1511.tar.gz
  popd
else
  packer -machine-reable build -only=virtualbox-iso vm-dependencies.json
  # upload newly created vm file to artifacts
fi

# The next two packer scripts can probably be merged into one build script
# that can run in parallel, either as two parallel builders or as concurrent
# processes within a provisioner job
packer -machine-readable build -only=virtualbox-ovf vm-get-centos7-base-pkgs.json
# check if centos7-base-pkgs.tar.gz exists
packer -machine-readable build -only=virtualbox-ovf vm-get-update-pkgs.json
# check if centos7-rpm-updates.tar.gz exists
# merge RPMs tarballs into single tarball with flat directory tree

# Step 2 Build iso-build image
# inputs: makeiso.sh, centos7-rpms.tar.gz
# outputs: iso-build Docker image

# Step 3 Create zenoss-centos ISO file
# inputs: centos_version, iso_build_number
# outputs: zenoss-centos-<CENTOS_VERSION>-<ISO_BUILD_NUMBER>-x86_64.iso

# Step 4 upload to artifacts
# inputs: newly build zenoss-centos ISO
# output: ISO uploaded to artifacts
