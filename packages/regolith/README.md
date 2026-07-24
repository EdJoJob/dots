# regolith (opt-in Linux desktop package)

Regolith 3 config: Xresources key overrides plus i3 `config.d` drop-ins.
The Regolith 2 → 3 update was done without a live R3 session to test
against, so two things are parked here for the next time this actually
deploys somewhere:

## Verify on the next real Regolith session

- `flags/show-shortcuts` and `flags/term-profile` are Regolith-2-era flag
  files and may be inert under Regolith 3 — confirm they still do
  anything, and delete them if not.

## Clipboard history is X11-only

greenclip (unit in the `systemd` package, rofi binding in
`config.d/95_greenclip`) is the lightweight X11 answer. If a Regolith 3
upgrade lands on a **Wayland** session, greenclip stops working — switch
to `cliphist` or `clipse` and rewire the rofi binding.
