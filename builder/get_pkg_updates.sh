#!/bin/bash

# Gets a list of packages to be updated
mkdir -p /working/Packages
yum update -y --downloadonly --downloaddir=/working/Packages
echo "$(date): get_pkg_updates done"
