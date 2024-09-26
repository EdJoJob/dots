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
from collections import namedtuple
from typing import TypedDict, TypeVar, cast, Union
from enum import Enum

log = logging.getLogger(__name__)

yabai = "/opt/homebrew/bin/yabai"

Pos2d = namedtuple('Pos2d', ['x', 'y'])

T = TypeVar('T')

class FrameT(TypedDict):
    x: int
    y: int
    w: int
    h: int


class Window(TypedDict):
    id: int
    pid: int
    app: str
    title: str
    scratchpad: str
    frame: FrameT
    role: str
    subrole: str
    root_window: bool
    display: int
    space: int
    level: int
    sub_level: int
    layer: str
    sub_layer: str
    opacity: float
    split_type: str
    split_child: str
    stack_index: int
    can_move: bool
    can_resize: bool
    has_focus: bool
    has_shadow: bool
    has_parent_zoom: bool
    has_fullscreen_zoom: bool
    has_ax_reference: bool
    is_native_fullscreen: bool
    is_visible: bool
    is_minimized: bool
    is_hidden: bool
    is_floating: bool
    is_sticky: bool
    is_grabbed: bool


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


def pythonize_dict(original_dict: dict[str, T]) ->dict[str, T]:
    new_dict = {}
    for key, value in original_dict.items():
        new_key = key.replace('-', '_')
        new_dict[new_key] = value
    return new_dict


def yabai_run(args, check=True) -> subprocess.CompletedProcess[bytes]:
    cmd = [yabai]
    cmd.extend(args)
    result = None
    log.debug("[checked_run] call %s", (cmd))
    try:
        result = subprocess.run(cmd, capture_output=True, check=check)
    except:
        log.exception('poop')
        raise
    finally:
        log.debug("[checked_run] call %s complete, result: %d", cmd, getattr(result, 'returncode', -1))
    return result or subprocess.CompletedProcess(args, -1, b'', b'')


def yabai_query(args: list[str], check: bool = True) -> list[Window]:
    cmd = ["-m", "query"]
    cmd.extend(args)
    proc = yabai_run(cmd, check=check)

    result = json.loads(proc.stdout)
    windows: list[Window] = []
    for w in result:
        windows.append(cast(Window, pythonize_dict(w)))

    return windows

def yabai_find_relevant_windows() -> tuple[list[Window], Union[Window,None]]:
    windows = yabai_query(["--windows", "--space"])

    visible_windows = [
        window
        for window in windows
        if window["is_visible"]
        # Teams has sise 0 windows on all spaces
        if window["frame"]["w"] > 0
    ]

    active_windows = [w for w in visible_windows if w["has_focus"]]
    if len(active_windows) != 0:
        active_window = active_windows[0]
    else:
        active_window = None

    return (visible_windows, active_window)


def yabai_stack(window_id: int):
    return yabai_run([ "-m", "window", "--stack", str(window_id)])


def yabai_insert(window_id, direction):
    return yabai_run([ "-m", "window", str(window_id), "--insert", direction])


def yabai_toggle_float(window_id):
    return yabai_run([ "-m", "window", str(window_id), "--toggle", "float"])


def toggle_stack():
    windows, active_window = yabai_find_relevant_windows()
    if active_window is None:
        return

    if active_window["stack_index"] == 0:
        stack_windows(windows, active_window)
    else:
        unstack_windows(windows, active_window)


def stack_windows(windows: list[Window], active_window: Window) -> None:
    frame:FrameT = active_window["frame"]
    center_point = Pos2d(x=frame["x"] + frame["w"] / 2, y=frame["y"] + frame["h"] / 2)
    windows_in_column = sorted(
        [
            (w["frame"]["y"], w)
            for w in windows
            if w["id"] != active_window["id"]
            if w["frame"]["x"] < center_point.x
            if (w["frame"]["x"] + w["frame"]["w"]) > center_point.x
        ],
        key=lambda x: x[0],
    )
    for _, other in windows_in_column:
        yabai_stack(other["id"])


def find_stacked_windows(windows: list[Window], active_window: Window) -> list[Window]:
    frame: FrameT = active_window["frame"]
    return [
        w
        for w in windows
        if w["id"] != active_window["id"]
        if w["frame"]["x"] == frame["x"]
        if w["frame"]["y"] == frame["y"]
        if w["stack_index"] != 0
    ]


def unstack_windows(windows: list[Window], active_window: Window)-> None:
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

    stack_index = active_window["stack_index"]
    if actual in ("east", "west") or stack_index == 0:
        if yabai_run([ "-m", "window", "--focus", actual], False).returncode != 0:
            if yabai_run([ "-m", "display", "--focus", actual], False).returncode == 0:
                while (
                    yabai_run([ "-m", "window", "--focus", opposite], False).returncode == 0
                ):
                    pass
                return 0
            else:
                return 1
        else:
            return 0

    if stack_index == 1 and actual == "north":
        return yabai_run([ "-m", "window", "--focus", actual], False).returncode

    delta = -1 if actual == "north" else 1
    target_index = active_window["stack_index"] + delta

    for other in find_stacked_windows(windows, active_window):
        if other["stack_index"] == target_index:
            return yabai_run([ "-m", "window", "--focus", str(other["id"])]).returncode

    return yabai_run([ "-m", "window", "--focus", "south"], False).returncode


def main():
    log.setLevel(logging.CRITICAL)
    fh = logging.FileHandler(os.path.expanduser("~/tmp/yabai-stack-aware.log"))
    fh.setLevel(logging.DEBUG)
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
