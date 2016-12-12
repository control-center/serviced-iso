#!/usr/bin/env python

import argparse
import json
import logging as log
import os

from subprocess import check_call, check_output


log.basicConfig(level=log.INFO)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description= 'Make a CentOS ISO.')
    parser.add_argument('--build-dir', type=str, required=True,
                        help='where to find all of the inputs and outputs')
    parser.add_argument('--build-number', type=str, default="dev",
                        help='the build number')
    parser.add_argument('--base-iso', type=str, required=True,
                        help='CentOS original ISO to start from')
    parser.add_argument('--cc-rpm', type=str, required=True,
                        help='The serviced RPM used for dependencies')
    parser.add_argument('--cc-repo', type=str, required=True,
                        help='The yum repo were the serviced RPM resides')
    parser.add_argument('--rpm-tarfile', type=str, required=True,
                        help='the name of the tar file containing RPM updates')
    args = parser.parse_args()

    scripts_dir = os.getcwd()
    mirror_file = "yum-mirror-{}-{}-{}-{}".format(
        args.base_iso, args.cc_rpm, args.cc_repo, args.build_number)

    mirror_dir = os.path.join(os.path.abspath(args.build_dir), "mirror")
    rpmroot = os.path.join(mirror_dir, "rpmroot")
    cleanup_cmd = "sudo rm -rf {}".format(rpmroot)
    check_call(cleanup_cmd, shell=True)

    log.info("Creating zenoss-mirror repo definition")
    reposdir = os.path.join(rpmroot, "etc/yum.repos.d")
    os.makedirs(reposdir)
    zenoss_mirror_def = """[zenoss-mirror]
name=Local Zenoss mirror for offline installs
baseurl=file:///opt/zenoss-repo-mirror
enabled=1
gpgcheck=0
"""
    with open(os.path.join(reposdir, "zenoss-mirror.repo"), 'w') as f:
        f.write(zenoss_mirror_def)

    log.info("Untarring RPMs ...")
    mirror_rpm_dir = os.path.join(rpmroot, "opt/zenoss-repo-mirror")
    os.makedirs(mirror_rpm_dir)
    os.chdir(mirror_rpm_dir)
    untar_cmd="tar xvf ../../../../{}".format(args.rpm_tarfile)
    check_call(untar_cmd, shell=True)

    log.info("Building mirror RPM ...")
    docker_run="docker run --rm -e MIRROR_FILE={} -e MIRROR_VERSION=1.2.0 -v {}:/scripts -v {}:/shared zenoss/fpm /scripts/convert-repo-mirror.sh".format(
        mirror_file, scripts_dir, mirror_dir)
    check_call(docker_run, shell=True)

    check_call(cleanup_cmd, shell=True)
