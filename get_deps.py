#!/usr/bin/env python

from __future__ import print_function

import json
import logging as log
import os
import shutil
import sys

from subprocess import check_call, check_output, CalledProcessError
from urllib import urlretrieve
from urllib2 import urlopen

log.basicConfig(level=log.INFO)

# Default location for 'output' dir in CWD
SCRIPTPATH = os.path.realpath(__file__)
SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))


class GetDepsException(Exception):
    pass


def get_rpm_list(zenoss_type, build_dir, vm_dir):
    # Get deps list by running "rpm -qa"
    log.info('Calling packer to check appliance dependencies')
    vm_deps_dir = '%s-deps' % vm_dir
    if os.path.exists(vm_deps_dir):
        shutil.rmtree(vm_deps_dir)
    command = [
        'packer -machine-readable build',
        '-var "zenosstype=%s"' % zenoss_type,
        '-var "inputdir=%s"' % vm_dir,
        '-var "outputdir=%s"' % vm_deps_dir,
        '%s/vm-dependencies.json' % SCRIPT_DIR,
    ]

    rawoutput = None
        
    error_log = os.path.join(build_dir, 'get_deps.error.log')
    if os.path.exists(error_log):
        os.remove(error_log)
    try:
        log.info("PACKER: %s" % ' '.join(command))
        rawoutput = check_output(' '.join(command), shell=True)
    except (CalledProcessError, ) as e:
        with open(error_log) as fd:
            fd.write('Error running get_deps.py:')
            fd.write(e.output)
        raise GetDepsException("Packer run failed. Check get_deps.error.log for details.")

    # Break raw input into lines of comma-separated data.
    rpm_qa = rawoutput.split('\n')

    # Filter for lines whose fourth column is 'message'.
    rpm_qa = [line for line in rpm_qa
                if line and line.split(',')[3] == 'message']

    # Filter each line into just its fifth column, and cut off the 'vmware-vmx:' prefix.
    rpm_qa = [line.split(',')[4].strip()[12:]
                for line in rpm_qa]

    if not rpm_qa:
        raise GetDepsException("Packer output is empty.")

    rpm_bof = 'START RPM LIST'
    rpm_eof = 'END RPM LIST'

    if rpm_bof not in rpm_qa:
        raise GetDepsException("START RPM LIST not found in rpm -qa output.")

    if rpm_eof not in rpm_qa:
        raise GetDepsException("END RPM LIST not found in rpm -qa output.")

    # Remove all input up to START RPM LIST and everything from END RPM LIST on.
    rpm_bof_i = rpm_qa.index(rpm_bof) + 1
    rpm_eof_i = rpm_qa.index(rpm_eof)
    rpm_list = rpm_qa[rpm_bof_i:rpm_eof_i]

    return rpm_list

    
# Remove version and architecture from package names
def get_package_name(rawpkg):
    pkgname = ''
    for token in rawpkg.split('-'):
        if not token[0].isdigit():
            if pkgname: pkgname += '-'
            pkgname += token
        else:
            break
    return pkgname


def get_dependency_list(zenoss_type, build_dir, vm_dir):
    rpm_list = get_rpm_list(zenoss_type, build_dir, vm_dir)
    
    # Remove version and architecture from each package name.
    rpm_list = [get_package_name(rpm) for rpm in rpm_list]

    # Filter out the serviced* and zenoss* packages.
    rpm_list = [rpm for rpm in rpm_list
                if not rpm.startswith('zenoss') and rpm != 'serviced']

    # Alphabetize and return.
    return sorted(rpm_list)


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Get dependencies for an appliance.')
    parser.add_argument('--zenoss-type', choices=('resmgr', 'core', 'ucspm', 'nfvimon'),
                        help='appliance hypervisor to use')
    parser.add_argument('--build-dir', type=str, required=True,
                        help='where to save the dependency file')
    parser.add_argument('--vm-dir', type=str, required=True,
                        help='where to find vmx file')
    args = parser.parse_args()

    build_dir = os.path.abspath(args.build_dir)
    vm_dir = os.path.abspath(args.vm_dir)

    try:

        dependencies = get_dependency_list(args.zenoss_type, build_dir, vm_dir)
        dep_file = os.path.join(build_dir, 'dependencies.txt')

        # Output list to file
        with open(dep_file, 'w') as outf:
            for line in dependencies:
                print(line, file=outf)

    except (GetDepsException,) as e:
        log.error(e.message)
        vmwarelog = os.path.join(SCRIPTPATH, 'vm-%s-deps' % args.zenoss_type, 'vmware.log')
        if os.path.isfile(vmwarelog):
            shutil.copy(vmwarelog, os.path.join(build_dir, 'get_deps.vmware.log'))
        sys.exit(1)
