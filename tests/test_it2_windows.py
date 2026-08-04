"""Regression tests for it2-last-output's line-window arithmetic.

Run:  uv run --with pytest pytest tests/

These pin the two functions that translate iTerm2 line coordinates, because
that arithmetic was once wrong in both directions at once and nothing caught
it: the errors cancel whenever `overflow == 0`, which is every pane that has
not yet filled its scrollback — and iTerm2's default profile here has
unlimited scrollback, so `overflow` stays 0 and the bug is invisible.

it2-last-output has no .py extension, so importlib cannot pick a loader from
the suffix and `spec_from_file_location` alone returns None; the loader is
passed explicitly. The module imports iterm2 at import time and assigns
`iterm2.auth.authenticate`, so the stub must expose `auth` as an attribute of
the parent module — seeding sys.modules is not enough on its own. The helpers
under test need neither.
"""

import importlib.util
import pathlib
import sys
import types
from importlib.machinery import SourceFileLoader

import pytest

SCRIPT = str(
    pathlib.Path(__file__).resolve().parent.parent
    / "packages/iterm-client/.bin/it2-last-output"
)


def _load():
    for name in ("iterm2", "iterm2.auth"):
        sys.modules.setdefault(name, types.ModuleType(name))
    setattr(sys.modules["iterm2"], "auth", sys.modules["iterm2.auth"])
    loader = SourceFileLoader("it2_last_output", SCRIPT)
    spec = importlib.util.spec_from_file_location(
        "it2_last_output", SCRIPT, loader=loader
    )
    assert spec is not None
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


it2 = _load()


class TestTailWindow:
    def test_no_overflow_matches_historical_behaviour(self):
        # The case that masked the bug: with nothing discarded, the old
        # `total - fetch` and the correct `overflow + total - fetch` agree.
        first, fetch = it2.tail_window(10, 50, 950, 0)
        assert (first, fetch) == (1000 - 60, 60)

    def test_overflow_is_included_in_first_line(self):
        # The live bug: 1000 retained lines with 500 already discarded means
        # the newest content sits at [500, 1500). Asking from 0 loses the
        # newest 500 lines — exactly the output the user just produced.
        first, fetch = it2.tail_window(2000, 50, 950, 500)
        assert fetch == 1000  # saturated at total
        assert first == 500  # not 0

    def test_fetch_saturates_at_total(self):
        first, fetch = it2.tail_window(10_000, 50, 950, 500)
        assert fetch == 1000
        assert first == 500

    def test_overfetches_one_screen_for_blank_rows(self):
        _, fetch = it2.tail_window(10, 50, 950, 0)
        assert fetch == 60  # requested + mutable, so trailing blanks can be cut


class TestPromptWindow:
    def test_absolute_start_is_passed_through(self):
        # start_y is already absolute; subtracting overflow would fetch a
        # window `overflow` lines too early — an older command's output.
        assert it2.prompt_window(800, 900, 0, 500) == (800, 100)

    def test_no_overflow_is_unchanged(self):
        assert it2.prompt_window(100, 150, 0, 0) == (100, 50)

    def test_partial_trim_clamps_and_shortens_once(self):
        # Output starting at 400 with 500 discarded: 100 lines aged out, so
        # read from 500 and drop exactly 100 from the count. Applying the
        # clamp twice would return 100 and lose real lines.
        assert it2.prompt_window(400, 700, 0, 500) == (500, 200)

    def test_trailing_partial_line_included_only_when_end_x_set(self):
        assert it2.prompt_window(100, 150, 0, 0)[1] == 50
        assert it2.prompt_window(100, 150, 7, 0)[1] == 51

    def test_fully_aged_out_returns_none(self):
        assert it2.prompt_window(100, 200, 0, 500) is None

    def test_empty_range_returns_none(self):
        assert it2.prompt_window(300, 300, 0, 0) is None


class TestPositiveInt:
    @pytest.mark.parametrize("bad", ["0", "-5"])
    def test_rejects_non_positive(self, bad):
        # -n 0 would slice rows[0:] and dump the whole buffer; a negative
        # value slices from the front and returns the oldest lines.
        with pytest.raises(Exception):
            it2.positive_int(bad)

    def test_accepts_one(self):
        assert it2.positive_int("1") == 1
