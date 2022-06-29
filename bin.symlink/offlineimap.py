#!/usr/bin/env python

from subprocess import check_output
import sys
import platform


def get_pass(kind, account):
    if platform.uname()[0] == "Darwin":
        return check_output(
            "security find-generic-password -w -s '{kind}-pass' -a '{account}'".format(
                kind=kind, account=account
            ),
            shell=True,
        ).splitlines()[0]
    else:
        return check_output(
            "secret-tool lookup {kind}-pass '{account}'".format(
                kind=kind, account=account
            ),
            shell=True,
        ).splitlines()[0]


if __name__ == "__main__":
    print(get_pass(sys.argv[1], sys.argv[2]))
