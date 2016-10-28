'''Test output of {bookmark}.'''

from nose import *
from util import *

@with_setup(setup_sandbox, teardown_sandbox)
def test_bookmark():
    hg_bookmark('test')

    output = prompt(fs='{bookmark}')
    assert output == 'test'

@with_setup(setup_sandbox, teardown_sandbox)
def test_no_bookmark():
    hg_bookmark('test')
    hg_deactivate_bookmark()

    output = prompt(fs='{bookmark}')
    assert output == ''
