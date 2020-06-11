-- vim: foldmethod=marker
-- IMPORTS {{{
    -- Base {{{
import XMonad
import System.IO (hPutStrLn)
import System.Exit (exitSuccess)
import Control.Monad (liftM2)
import Text.Printf (printf)
import qualified XMonad.StackSet as W
import qualified Data.Map as M
    -- }}}
    -- Actions {{{
import XMonad.Actions.CycleWS
    -- }}}
    -- Hooks {{{
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.SetWMName
    -- }}}
    -- Layout modifiers {{{
import XMonad.Layout.NoBorders
import XMonad.Layout.PerWorkspace
import XMonad.Layout.Reflect
import XMonad.Layout.ToggleLayouts
    -- }}}
    -- Layouts {{{
import XMonad.Layout.IM
import XMonad.Layout.Mosaic
import XMonad.Layout.ResizableTile
    -- }}}
    -- Utilities {{{
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.SpawnOnce
    -- }}}
-- }}}

-- VARIABLES {{{

myBaseConfig = defaultConfig
myFont :: [Char]
myFont = "xft:mononoki-Regular Nerd Font Complete Mono:pixelsize=12"

myModMask :: KeyMask
myModMask = (mod4Mask) -- Sets mod to super

myTerminal :: [Char]
myTerminal = "gnome-terminal" -- Set default terminal

myBorderWidth :: Dimension
myBorderWidth = 2          -- Sets border width for windows

myWorkspaces = ["1:code", "2:web", "3:term", "4:mail", "5:gimp", "6:misc", "7:junk", "8:fullscreen", "9:im"]
myNormalBorderColor = "#dddddd"
myFocusedBorderColor = "#ffff00"
-- }}}

-- KEYS {{{
myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $
      -- launching and killing programs
    [ ((modMask .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf)

      -- %! Launch dmenu
    , ((modMask,               xK_p     ), spawn $ printf "exe=`dmenu_path | dmenu -sf '#ffffff' -sb '#008800' -nb '#333333' -nf '#aaaaaa' -fn %s` && eval \"exec $exe\"" (show myFont))

     -- %! Close the focused window
    , ((modMask .|. shiftMask, xK_c     ), kill)

    -- Layouts {{{
     -- %! Rotate through the available layout algorithms
    , ((modMask,               xK_space ), sendMessage NextLayout)
 -- %!  Reset the layouts on the current workspace to default
    , ((modMask .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook conf)

     -- %! Resize viewed windows to the correct size
    , ((modMask,               xK_n     ), refresh)
    -- }}}

    -- move focus up or down the window stack {{{
    , ((mod1Mask,               xK_Tab   ), windows W.focusDown   )
    , ((modMask,                xK_j     ), windows W.focusDown   )

    , ((mod1Mask .|. shiftMask, xK_Tab   ), windows W.focusUp     )
    , ((modMask,                xK_k     ), windows W.focusUp     )

    , ((modMask .|. shiftMask,   xK_m     ), windows W.focusMaster)
    -- }}}

    -- modifying the window order {{{
    , ((modMask,               xK_Return), windows W.swapMaster)
    , ((modMask .|. shiftMask, xK_j     ), windows W.swapDown  )
    , ((modMask .|. shiftMask, xK_k     ), windows W.swapUp    )
    -- }}}

    -- resizing the master/slave ratio {{{
    , ((modMask,               xK_h     ), sendMessage Shrink)
    , ((modMask,               xK_l     ), sendMessage Expand)
    -- }}}

    -- floating layer support {{{
    -- Push window back into tiling
    , ((modMask,               xK_t     ), withFocused $ windows . W.sink)
    -- }}}

    -- increase or decrease number of windows in the master area {{{
    , ((modMask              , xK_comma ), sendMessage (IncMasterN 1))
    , ((modMask              , xK_period), sendMessage (IncMasterN (-1)))
    -- }}}

    -- toggle the status bar gap {{{
    , ((modMask              , xK_b     ), sendMessage $ ToggleStruts)
    -- }}}

    -- quit, or restart {{{
    , ((modMask              , xK_q     ), spawn "xmonad --recompile && xmonad --restart")
    , ((modMask .|. shiftMask, xK_q     ), io (exitSuccess))
    -- }}}

    -- NON-DEFAULT MOD Combinations {{{
    -- kill long running command announcement
    , (( mod1Mask .|. controlMask, xK_z ), spawn "killall espeak")

    -- Scratchpads {{{
    , ((mod4Mask .|. mod1Mask, xK_Return), namedScratchpadAction myScratchPads "terminal")
    , ((controlMask .|. mod1Mask .|. mod4Mask, xK_Return), namedScratchpadAction myScratchPads "wiki")
    , ((modMask, xK_m), namedScratchpadAction myScratchPads "music")
    -- }}}

    -- Lock the screen
    , (( mod1Mask .|. controlMask, xK_l), spawn "slock")

    -- Movements
    , (( controlMask .|. mod4Mask, xK_l ), nextWS)
    , (( controlMask .|. mod4Mask, xK_h), prevWS)
    , (( controlMask .|. mod4Mask .|. mod1Mask, xK_l), shiftToNext >> nextWS)
    , (( controlMask .|. mod4Mask .|. mod1Mask, xK_h), shiftToPrev >> prevWS)

    ]
    ++
    -- CTRL-META-[1..9] %! Switch to workspace N
    -- CTRL-META-SHIFT-[1..9] %! Move client to workspace N
    [((m .|. controlMask .|. mod4Mask, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (liftM2 (.) W.greedyView W.shift, mod1Mask)]]
    ++
    -- CTRL-META-{w,e,r} %! Switch to physical/Xinerama screens 1, 2, or 3
    -- CTRL-META-SHIFT-{w,e,r} %! Move client to screen 1, 2, or 3
    [((m .|. controlMask .|. mod4Mask, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_w, xK_e, xK_r] [0..]
        , (f, m) <- [(W.view, 0), (W.shift, mod1Mask)]]
    -- }}}
-- }}}

-- workspaces{{{
myLayoutHook = avoidStruts $ toggleLayouts (noBorders Full)
    ( tiled ||| Full ||| mosaic 2 [3,2] ||| Mirror tiled)
    where
        tiled   = avoidStruts $ ResizableTall nmaster delta ratio []
        nmaster = 1
        delta   = 2/100
        ratio   = 1/2
--- }}}

-- scratchPads {{{
myScratchPads = [ NS "terminal" spawnTerm findTerm manageTerm
                , NS "wiki" spawnWiki findWiki manageWiki
                , NS "music" spawnMusic findMusic manageMusic
                ]
    where
    spawnTerm = "alacritty --class scratchpad"
    findTerm = resource =? "scratchpad"
    manageTerm = customFloating $ W.RationalRect l t w h
        where
            h = 0.9
            w = 0.9
            t = 0.95 - h
            l = 0.95 - w
    spawnWiki = "alacritty --working-directory ~/Dropbox/wiki --class wiki --command /usr/bin/nvim +VimwikiIndex &"
    findWiki = resource =? "wiki"
    manageWiki = customFloating $ W.RationalRect l t w h
        where
            h = 0.5
            w = 0.5
            t = 0
            l = 0.25
    spawnMusic = "spotify"
    findMusic = resource =? "spotify"
    manageMusic = customFloating $ W.RationalRect l t w h
        where
            h = 0.9
            w = 0.9
            t = 0.95 - h
            l = 0.95 - w

-- }}}

-- manageHook {{{
myManageHook = manageDocks <+> composeAll
      [ className =? "Vncviewer"     --> doFloat
        , className =? "Thunderbird"   --> doF (W.shift "4:mail")
        , className =? "Slack"         --> doF (W.shift "9:im")
      ] <+> namedScratchpadManageHook myScratchPads
-- }}}

-- logHook {{{
myLogHook xmproc = do
    dynamicLogWithPP xmobarPP
                    { ppOutput = hPutStrLn xmproc
                    , ppTitle = xmobarColor "green" "" . shorten 50
                    }
    fadeInactiveLogHook 0.8
-- }}}

-- startupHook {{{
{- startup command for window effects

"-cfF" "c" is for soft shadows and transparency support,
       "f" for fade in & fade out when creating and closing windows,
       and "F" for fade when changing a window's transparency.
"-t-9 -l-11" shadows are offset 9 pixels from top of the window
             and 11 pixels from the left edge
"-r9" shadow radius is 9 pixels
"-o.95" shadow opacity is set to 0.95
"-D6" the time between each step when fading windows is set to 6 milliseconds.
-}

myStartupHook        = do
  startupHook defaultConfig
  spawnOnce "compton -cfF -t-9 -l-11 -r9 -o.95 -D6 &"
  setWMName "LG3D"
-- }}}

-- MAIN {{{
main = do
    xmproc <- spawnPipe "xmobar"
    xmonad $ ewmh $ docks myBaseConfig
        { manageHook = myManageHook
          , layoutHook = myLayoutHook
          , borderWidth = 3
          , startupHook = myStartupHook
          , workspaces = myWorkspaces
          , modMask = myModMask
          , logHook = myLogHook xmproc
          , keys = myKeys
          , terminal = myTerminal
        }
-- }}}
