#!/usr/bin/env python3

import asyncio
import iterm2


async def isDefaultTheme(session):
    profile = await session.async_get_profile()
    return "default" in profile.name.lower()


async def changeTheme(theme_parts, connection, app):
    to_be_changed = [
        session
        for window in app.windows
        for tab in window.tabs
        for session in tab.sessions
        if await isDefaultTheme(session)
    ]

    # Themes have space-delimited attributes, one of which will be light or dark.
    if "dark" in theme_parts:
        preset = await iterm2.ColorPreset.async_get(connection, "material-dark")
    else:
        preset = await iterm2.ColorPreset.async_get(connection, "material")

    for session in to_be_changed:
        profile = await session.async_get_profile()
        await profile.async_set_color_preset(preset)


async def main(connection):
    # Set color scheme correctly at app start
    app = await iterm2.async_get_app(connection)
    parts = await app.async_get_theme()
    await changeTheme(parts, connection, app)

    async with iterm2.VariableMonitor(
        connection, iterm2.VariableScopes.APP, "effectiveTheme", None
    ) as mon:
        while True:
            # Block until theme changes
            theme = await mon.async_get()
            parts = theme.split(" ")
            await changeTheme(parts, connection, app)


iterm2.run_forever(main)
