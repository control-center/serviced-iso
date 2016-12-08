#!/usr/bin/env python

import argparse
import json
import logging as log
import os
import shutil

from subprocess import check_call, check_output
from urllib import urlretrieve
from urllib2 import urlopen

log.basicConfig(level=log.INFO)

# Default location for 'build' dir in CWD
BUILD_DIR = os.path.abspath('build')

# Default location for output is CWD
OUTPUT_DIR = os.path.abspath('.')

# Common dir is one dir up from this source file
COMMON_DIR = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '../common'))

# ISO Builder docker image.
DOCKER_BUILDER = 'docker-registry-v2.zenoss.eng/iso-build'

if os.environ.get("BUILD_NUMBER"):
    BUILD_NUMBER = os.environ.get("BUILD_NUMBER")
else:
    BUILD_NUMBER = "dev"

# If you do not have access to docker-registry-v2.zenoss.eng:
# 1. Build the image in ./builder with "docker build ."
# 2. Tag the resulting image as iso-build:latest
# 3. Set the environment variable ISO_BUILD_IMAGE to 'iso-build'
if os.environ.get("ISO_BUILD_IMAGE"):
    DOCKER_BUILDER = os.environ.get("ISO_BUILD_IMAGE")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description= 'Make a CentOS ISO.')
    parser.add_argument('--build-dir', type=str, required=True,
                        help='where to find appliance artifacts')
    parser.add_argument('--centos-version', choices=('7.2.1511', '7.1.1503'),
                        help='CentOS version to use')
    args = parser.parse_args()

    build_dir = os.path.abspath(args.build_dir)
    if args.centos_version:
        centos_version = args.centos_version
    else:
        centos_version = '7.2.1511'

    # Update builder image
    if DOCKER_BUILDER.startswith('docker-registry-v2.zenoss.eng'):
        log.info('Calling docker pull to update ISO builder image')
        check_call('docker pull %s' % DOCKER_BUILDER, shell=True)

    # Create ISO
    log.info('Calling docker run to create ISO')
    check_call('docker run -e "BUILD_NUMBER=%s" -e "CENTOS_VERSION=%s" --privileged=true --rm -v=%s:/build -v=%s:/common -v=%s:/output %s' % (
                BUILD_NUMBER, centos_version, build_dir, COMMON_DIR, OUTPUT_DIR, DOCKER_BUILDER), shell=True)
