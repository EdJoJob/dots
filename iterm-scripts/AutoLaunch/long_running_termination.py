#!/usr/bin/env python3.7

import subprocess
import sys
import traceback

import iterm2

# This script was created with the "basic" environment which does not support adding dependencies
# with pip.

COMMAND = "longrun"

# printf "\033]1337;Custom=id=%s:%s\a" "longrun" "some real words"
async def main(connection):
    async with iterm2.CustomControlSequenceMonitor(connection, COMMAND, r'^.*$') as mon:
        while True:
            match = await mon.async_get()
            try:
                subprocess.run(['say', match.group(0)])
            except:
                traceback.print_tb(sys.exec_info()[2])


iterm2.run_until_complete(main)
