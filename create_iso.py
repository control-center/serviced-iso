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

# If you do not have access to docker-registry-v2.zenoss.eng:
# 1. Build the image in ./builder with "docker build ."
# 2. Tag the resulting image as iso-build:latest
# 3. Set the environment variable ISO_BUILD_IMAGE to 'iso-build'
if os.environ.get("ISO_BUILD_IMAGE"):
    DOCKER_BUILDER = os.environ.get("ISO_BUILD_IMAGE")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description= 'Make an ISO.')
    parser.add_argument('--manifest', required=True,
                        help='where to find manifest file (can be filepath or URL)')
    parser.add_argument('--build-dir', type=str, required=True,
                        help='where to find appliance artifacts')
    parser.add_argument('--zenoss-type', choices=('resmgr', 'core', 'ucspm', 'nfvimon'),
                        help='appliance hypervisor to use')
    args = parser.parse_args()

    build_dir = os.path.abspath(args.build_dir)

    # Get build
    if args.manifest.startswith('http'):
        # If manifest is from URL, download the build to a local dir
        manifest = json.loads(urlopen(args.manifest).read())
        urldir = args.manifest.rsplit('/', 1)[0] + '/'

        log.info('Removing old build dir')
        shutil.rmtree(build_dir, ignore_errors=True)

        log.info('Making build dir and dumping manifest')
        os.mkdir(build_dir)
        json.dump(manifest,
                  open(os.path.join(build_dir, 'manifest.%s.json' % args.zenoss_type), 'w'),
                  sort_keys=True, indent=4)
        for f in manifest['images'].values() + manifest['rpms'].values():
            log.info('Downloading %s' % f)
            urlretrieve(urldir + f, os.path.join(build_dir, f))
    else:
        manifest = json.load(open(args.manifest))
        build_dir = os.path.abspath(os.path.dirname(args.manifest))

    # Update builder image
    if DOCKER_BUILDER.startswith('docker-registry-v2.zenoss.eng'):
        log.info('Calling docker pull to update ISO builder image')
        check_call('docker pull %s' % DOCKER_BUILDER, shell=True)

    # Create ISO
    log.info('Calling docker run to create ISO')
    check_call('docker run --privileged=true --rm -v=%s:/build -v=%s:/common -v=%s:/output %s' % (
                build_dir, COMMON_DIR, OUTPUT_DIR, DOCKER_BUILDER), shell=True)
