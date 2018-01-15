#!/bin/bash
##############################################################################
#
# Copyright (C) Zenoss, Inc. 2017, all rights reserved.
#
# This content is made available according to terms specified in
# License.zenoss under the directory where your Zenoss product is installed.
#
##############################################################################

# Previously this was the main entry point for upgrading
# CC and RM at the same time.  This is now broken into two
# steps using a python tui menu.
export ISOMOUNT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $ISOMOUNT/build

python ${ISOMOUNT}/update-options.py
