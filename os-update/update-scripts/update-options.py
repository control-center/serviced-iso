#!/usr/bin/env python
##############################################################################
#
# Copyright (C) Zenoss, Inc. 2017, all rights reserved.
#
# This content is made available according to terms specified in
# License.zenoss under the directory where your Zenoss product is installed.
#
##############################################################################

import os
import subprocess

# Import snack (newt for Python)
from snack import *

UPDATE_OS=os.path.join(os.path.dirname(os.path.realpath(__file__)), 'update-os.sh')

HELP="Use this iso to update the operating system for the appliance."

# Helper 'callback' for help screen
def help(screen, text):
    ButtonChoiceWindow(screen, "Help", text, help="Help on help", buttons=('OK',))

def get_screen():
    screen = SnackScreen()
    screen.helpCallback(help)
    screen.pushHelpLine('Press F1 for help, arrow keys to navigate, and Enter to select an option')
    return screen

def main_menu():
    while True:
        screen = get_screen()
        bcw = ButtonChoiceWindow(screen, 'Upgrade Operating System',
                        'This iso will update the operating system.\n\nContinue?',
                        buttons=('OK', 'Cancel'),
                        help=HELP)
        screen.finish()
        if bcw == 'cancel':
            return

        # They chose to continue. Update the operating system.
        subprocess.call('bash ' + UPDATE_OS, shell=True)

if __name__ == '__main__':
    main_menu()
