#!/usr/bin/env python2
# This has been modified from://github.com/haifengkao/nfasd and as such is
# under MIT license
# Copyright 2017 Edward Evands @haldengkao
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import os     # to execute nvim
import platform  # to find XDG_DATA_HOME
import msgpack  # to parse shada
from sets import Set
from collections import namedtuple, Counter

FASD_Line = namedtuple('FASD_Line', ['filename', 'weight', 'timestamp'])


def shada_path():
    # Unix:     ~/.local/share/nvim/
    # Windows:  ~/AppData/Local/nvim-data/
    key = 'XDG_DATA_HOME'
    path = None
    if key in os.environ:
        path = os.environ[key]
    if not path:
        if platform.system() == 'Windows':
            path = '~/AppData/Local'
        else:
            path = '~/.local/share'
            if platform.system() == 'Windows':
                path = os.path.join(path, 'nvim-data')
            else:
                path = os.path.join(path, 'nvim')
    path = os.path.join(path, 'shada', 'main.shada')
    return path


def nvim_oldfiles(shada_path):
    '''return an array of v:oldfiles'''
    shada_path = os.path.expanduser(shada_path)
    f = open(shada_path, 'rb')
    unpacker = msgpack.Unpacker(f)

    # see https://neovim.io/doc/user/starting.html#shada-format

    # 1. First goes type of the entry.  Object type must be an unsigned integer.
    #    Object type must not be equal to zero.
    # 2. Second goes entry timestamp.  It must also be an unsigned integer.
    # 3. Third goes the length of the fourth entry.  Unsigned integer as well, used
    #    for fast skipping without parsing.
    # 4. Fourth is actual entry data.  All currently used ShaDa entries use
    #    containers to hold data: either map or array.  Exact format depends on the
    #    entry type:

    # 7 (GlobalMark)
    # 8 (Jump)
    # 10 (LocalMark)
    # 11 (Change)
    valid_types = [7, 8, 10, 11]

    recent_files = dict()

    try:
        while True:
            object_type = unpacker.unpack()

            timestamp = unpacker.unpack()  # timestamp
            unpacker.skip()  # data_length in bytes
            if object_type not in valid_types:
                unpacker.skip()
            else:
                data = unpacker.unpack()
                filename = data['f']
                if not filename.startswith('/'):
                    continue
                if filename not in recent_files:
                    weight = 1
                else:
                    weight = recent_files[filename].weight + 1
                recent_files[filename] = FASD_Line(
                    filename=filename, weight=weight, timestamp=timestamp)

    except msgpack.exceptions.OutOfData as e:
        # all data are processed
        pass
    return recent_files


if __name__ == '__main__':
    for f in nvim_oldfiles(shada_path()).values():
        print '%s|%d|%d' % (f.filename, f.weight, f.timestamp)
