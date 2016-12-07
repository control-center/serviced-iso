#!/usr/bin/bash

# Step 1 Build Dependencies tarball
# inputs: centos-7.2.1511 iso, or centos-7.2.1511 VM
# outputs: tarball of RPMS,

# Step 2 Build iso-build image
# inputs: makeiso.sh, centos7-rpms.tar.gz
# outputs: iso-build Docker image

# Step 3 Create zenoss-centos ISO file
# inputs: centos_version, iso_build_number
# outputs: zenoss-centos-<CENTOS_VERSION>-<ISO_BUILD_NUMBER>-x86_64.iso

# Step 4 upload to artifacts
# inputs: newly build zenoss-centos ISO
# output: ISO uploaded to artifacts