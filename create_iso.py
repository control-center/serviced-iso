#!/usr/bin/env python

import argparse
import json
import logging as log
import os

from subprocess import check_call, check_output


log.basicConfig(level=log.INFO)

# ISO Builder docker image.
DOCKER_BUILDER = 'docker-registry-v2.zenoss.eng/base-iso-build:1.0.0'

# If you do not have access to docker-registry-v2.zenoss.eng:
# 1. Build the image in ./builder with "docker build ."
# 2. Tag the resulting image as iso-build:latest
# 3. Set the environment variable ISO_BUILD_IMAGE to 'iso-build'
if os.environ.get("ISO_BUILD_IMAGE"):
    DOCKER_BUILDER = os.environ.get("ISO_BUILD_IMAGE")

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
    parser.add_argument('--output-name', type=str, required=True,
                        help='the name of the ISO file to be created')
    args = parser.parse_args()

    build_dir = os.path.abspath(args.build_dir)

    # Get builder image
    if DOCKER_BUILDER.startswith('docker-registry-v2.zenoss.eng'):
        log.info('Calling docker pull to update ISO builder image')
        check_call('docker pull %s' % DOCKER_BUILDER, shell=True)

    # Create the Zenoss CentOS ISO from base_iso + rpm_tarfile.
    # The result is saved as zenoss_centos_iso
    log.info('Calling docker run to create ISO')
    check_call('docker run -e "BASE_ISO_NAME=%s.iso" -e "RPM_TARFILE=%s" -e "ISO_FILENAME=%s" --privileged=true --rm -v=%s:/mnt/build -v=%s:/mnt/output %s' % (
                args.base_iso, args.rpm_tarfile, args.output_name,
                build_dir, build_dir,
                DOCKER_BUILDER), shell=True)

