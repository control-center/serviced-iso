# serviced-iso
Scripts to build base ISO images for Serviced Appliances

# Overview

This repo contains scripts used to build an ISO image that is a copy of
one of the standard CentOS ISO images plus a yum mirror RPM.  The yum
mirror RPM contains all of the third-party packages needed to for a given
CC RPM.

The end result of the build is the ISO containing the yum mirror, which can be
used for building downstream appliance builds, and the yum mirror RPM, which can be
provided to customers for offline installs.

All downstream appliances, regardless of form factor (ova, iso, ami, etc) should be
based on an ISO produced by the scripts in this repo so that all the appliances have the
exact same set of third-party components.

# Background

In the CC 1.0.x and 1.1.x era, the yum mirror RPM was built as part of the
RM appliance build process, which was problematic because it meant that we
could not build/release CC independently of RM.

The other potential problem was that the contents of the yum mirror RPM might
change from one build to the next because each nightly build of RM would reconstruct
the yum mirror RPM, meaning that we might accidentally pickup some new version
of a third-party package right on the eve of releasing a new product version.

Lastly, the processes for building an RM OVA, an RM ISO and the yum mirror did
not guarantee the exact same set of third-party RPMs in all three artifacts due
to slight variations between these different appliance builds.

For more info about the older build process for the yum mirror RPM, see the
script `offline/create_offline_bundle.py` in the `support/5.1.x` branch
of the [zenoss/zenoss-deploy](https://github.com/zenoss/zenoss-deploy) repo.

# When/How is the ISO and mirror RPM updated?

The ISO and yum mirror RPMs are created by a Jenkins job. The job is NOT run nightly, but only
run on demand.

The job should be run anytime the set of OS and third-party dependencies need to be updated.
When do they need to be updated?
* when the dependencies defined in the CC RPM change
* whenever we modify the set of misc third-party utilities we use in the appliance change (e.g. ntp, telnet, etc)
* whenever we are want to get a refresh of the OS utilities in general; e.g. at the start a new release, or we need a new kernel version, etc.

For builds off of develop, the job which builds the iso is
[ControlCenter/develop/serviced-centos-iso-build](http://platform-jenkins.zenoss.eng/job/ControlCenter/job/develop/job/serviced-centos-iso-build/).
After a new ISO is built, you need to manually update two other scripts to use the new ISO:

1. The script [jenkinsTestServicedBuildDeps.sh](jenkinsTestServicedBuildDeps.sh) in this repo.
1. The script [offline/create_serviced_bom.py](https://github.com/zenoss/zenoss-deploy/blob/develop/offline/create_serviced_bom.py)
in the [zenoss/zenoss-deploy](https://github.com/zenoss/zenoss-deploy) repo.

The [jenkinsTestServicedBuildDeps.sh](jenkinsTestServicedBuildDeps.sh) script is used to verify that all of the dependencies
defined by the latest CC RPM are included in the CC ISO. The test script is run by the job
[ControlCenter/develop/merge-rpm-test-deps](http://platform-jenkins.zenoss.eng/job/ControlCenter/job/develop/job/merge-rpm-test-deps/)
each time a new CC RPM is produced.

The [offline/create_serviced_bom.py](https://github.com/zenoss/zenoss-deploy/blob/develop/offline/create_serviced_bom.py) script
is used to construct the CC BOM file that defines the inputs to appliance build process, including the base ISO name.

## How to Change dependencies for the CC RPM
There is a chicken-and-egg problem with modifying the dependencies for CC because the CC build which produces a new CC RPM containing the dependency change needs a corresponding CC ISO containing the dependent RPMs. However, the CC ISO cannot be rebuilt to package the dependent RPMS until a new CC RPM is published. 

By the same token, attempts to build a Zenoss appliance with the new CC RPM will fail because the new CC RPM requires dependent RPMs to be packaged in the CC ISO.

Use the following procedure to workaround that circular dependency.  

1. Make the necessary changes to the CC packaging in the CC github repo. 
When those changes are merged, the CC `merge-start` build will run automatically. Typically, this build will fail during the `merge-rpm-test-deps` job because the new dependencies are not yet in the CC ISO.
1. Rerun the CC `merge-start` build manually, but enable the build parameter `SKIP_RPM_TEST_DEPS`. This will repeat the build process, but it will skip the `merge-rpm-test-deps` job. Alternatively, you can manually execute the CC `merge-rpm-build` job and also enable the build parameter `SKIP_RPM_TEST_DEPS`. 
1. After the new CC RPM has been pushed to the Zenoss RPM repo, execute the `serviced-centos-iso-build` job specifying the RPM that was just built.
1. After the `serviced-centos-iso-build` job has finished, update the [jenkinsTestServicedBuildDeps.sh](jenkinsTestServicedBuildDeps.sh) script in this repo to reference the new ISO; see the `SERVICED_ARTIFACT_BASENAME` definition in that script. The next time the CC `merge-start` script is run it should execute the `merge-rpm-test-deps` job which should pass.
1. Also, update the [offline/create_serviced_bom.py](https://github.com/zenoss/zenoss-deploy/blob/develop/offline/create_serviced_bom.py) script to specify the new ISO as well.  The next time the Zenoss appliance build runs, it should package the right CC RPM.

# Process Details

The specific CentOS ISO images used as a baseline are hard-coded in `jenkins-build.sh`.

The specific CC RPM is specified via two environment variables: CC_RPM and CC_REPO.

The resultant ISO and yum mirror RPM files have the same base file name with the following
format:

`<cc-rpm>-<cc_repo>-<centos-base>-bld-<build-number>`

where:
* `<cc-rpm>` is the serviced RPM used to determine what dependencies are added to the mirror RPM
* `<cc-repo>` the repo name where `<cc-rpm>` resides; i.e. one of `unstable`, `testing`, or `stable`
* `<centos-base>` the CentOS base version; one of `centos7.3.1611`, `centos7.2.1511` or `centos7.1.1503`
* `<build-number>` the Jenkins build number from the environment variable `BUILD_NUMBER`; defaults to `dev` if the `BUILD_NUMBER` is not defined

Conceptually, the yum mirror RPM contains 3 sets of components:

1. The result of `yum update` relative to the base CentOS image. In other words, the latest
update for any components in the base image.
1. The set of 3rd-party dependencies required by the specified serviced RPM
1. A handful of utilities that we would like to have in the appliances. Examples include telnet and nmap
for debugging Zookeeper issues and unzip for installing inspector.

Note that the yum mirror RPM does NOT include any RPMs from zenoss.
These will always be delivered separately

FYI - for convenience, the image is created with a default `centos` user.
