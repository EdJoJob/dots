#!/usr/bin/env python3

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
        ).splitlines()[0].decode()
    else:
        return check_output(
            "secret-tool lookup {kind}-pass '{account}'".format(
                kind=kind, account=account
            ),
            shell=True,
        ).splitlines()[0].decode()


if __name__ == "__main__":
    print(get_pass(sys.argv[1], sys.argv[2]))
