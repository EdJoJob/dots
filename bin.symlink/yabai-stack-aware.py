#!/usr/bin/python3
"""
The job of this script is to toggle the current window in and out of being yabai stacked
"""

import json
import logging
import os
import subprocess
import sys
from dataclasses import dataclass
from enum import Enum

log = logging.getLogger(__name__)

yabai = "/opt/homebrew/bin/yabai"


@dataclass
class DirectionMixin:
    direction: str
    opposite: str

    def __eq__(self, __value: object) -> bool:
        if isinstance(__value, str):
            return self.direction == __value
        if isinstance(__value, self.__class__):
            return self.direction == __value.direction
        return False


class Direction(DirectionMixin, Enum):
    north = "north", "south"
    south = "south", "north"
    east = "east", "west"
    west = "west", "east"


def checked_run(args, check_output=True):
    result = None
    log.debug("[checked_run] call %s", (args))
    try:
        result = subprocess.run(args, capture_output=True, check=check_output)
    except:
        log.exception("poop")
        raise
    finally:
        log.debug("[checked_run] call %s complete, result: %d", args, getattr(result, 'returncode', -1))
    return result


def yabai_find_relevant_windows():
    proc = checked_run([yabai, "-m", "query", "--windows", "--space"])
    result = json.loads(proc.stdout)

    visible_windows = [
        window
        for window in result
        if window["is-visible"]
        # Teams has sise 0 windows on all spaces
        if window["frame"]["w"] > 0
    ]

    active_windows = [w for w in visible_windows if w["has-focus"]]
    if len(active_windows) != 0:
        active_window = active_windows[0]
    else:
        active_window = None

    return (visible_windows, active_window)


def yabai_stack(window_id):
    return checked_run([yabai, "-m", "window", "--stack", str(window_id)])


def yabai_insert(window_id, direction):
    return checked_run([yabai, "-m", "window", str(window_id), "--insert", direction])


def yabai_toggle_float(window_id):
    return checked_run([yabai, "-m", "window", str(window_id), "--toggle", "float"])


def toggle_stack():
    windows, active_window = yabai_find_relevant_windows()
    if active_window is None:
        return

    if active_window["stack-index"] == 0:
        stack_windows(windows, active_window)
    else:
        unstack_windows(windows, active_window)


def stack_windows(windows, active_window):
    frame = active_window["frame"]
    center_point = (frame["x"] + frame["w"] / 2, frame["y"] + frame["h"] / 2)
    windows_in_column = sorted(
        [
            (w["frame"]["y"], w)
            for w in windows
            if w["id"] != active_window["id"]
            if w["frame"]["x"] < center_point[0]
            if (w["frame"]["x"] + w["frame"]["w"]) > center_point[0]
        ],
        key=lambda x: x[0],
    )
    for _, other in windows_in_column:
        yabai_stack(other["id"])


def find_stacked_windows(windows, active_window):
    frame = active_window["frame"]
    return [
        w
        for w in windows
        if w["id"] != active_window["id"]
        if w["frame"]["x"] == frame["x"]
        if w["frame"]["y"] == frame["y"]
        if w["stack-index"] != 0
    ]


def unstack_windows(windows, active_window):
    for other in find_stacked_windows(windows, active_window):
        yabai_insert(other["id"], "south")
        yabai_toggle_float(other["id"])
        yabai_toggle_float(other["id"])


def change_focus(direction: Direction) -> int:
    log.debug("START change_focus")
    windows, active_window = yabai_find_relevant_windows()
    log.debug("[change_focus] active_window: %s, windows: %s", active_window, windows)
    if active_window is None:
        return 1

    actual = direction.direction
    opposite = direction.opposite

    stack_index = active_window["stack-index"]
    if actual in ("east", "west") or stack_index == 0:
        if checked_run([yabai, "-m", "window", "--focus", actual], False).returncode != 0:
            if checked_run([yabai, "-m", "display", "--focus", actual], False).returncode == 0:
                while (
                    checked_run([yabai, "-m", "window", "--focus", opposite], False).returncode == 0
                ):
                    pass
                return 0
            else:
                return 1

    if stack_index == 1 and actual == "north":
        return checked_run([yabai, "-m", "window", "--focus", actual], False).returncode

    delta = -1 if actual == "north" else 1
    target_index = active_window["stack-index"] + delta

    for other in find_stacked_windows(windows, active_window):
        if other["stack-index"] == target_index:
            return checked_run([yabai, "-m", "window", "--focus", str(other["id"])]).returncode

    return checked_run([yabai, "-m", "window", "--focus", "south"], False).returncode


def main():
    log.setLevel(logging.CRITICAL)
    fh = logging.FileHandler(os.path.expanduser("~/tmp/yabai-stack-aware.log"))
    fh.setLevel(logging.CRITICAL)
    log.addHandler(fh)

    log.debug("main call: %s", (sys.argv))

    if sys.argv[1] == "toggle":
        log.debug("toggling")
        result = toggle_stack()
    else:
        log.debug("focusing")
        direction = next(d for d in Direction if d == sys.argv[2])
        result = change_focus(direction)
    log.debug("overall: %s", (result))


if __name__ == "__main__":
    main()
