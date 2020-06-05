import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig(additionalKeys)
import XMonad.Actions.CycleWS
import System.IO

main = do
    xmproc <- spawnPipe "xmobar"
    xmonad $ docks defaultConfig
        { layoutHook = avoidStruts $ layoutHook defaultConfig
          , modMask = (mod1Mask .|. controlMask)
          , logHook = dynamicLogWithPP xmobarPP
              { ppOutput = hPutStrLn xmproc
                , ppTitle = xmobarColor "green" "" . shorten 50
              }
        }
        `additionalKeys`
        [ (( mod1Mask .|. controlMask, xK_z ), spawn "killall espeak")
          , (( controlMask .|. mod4Mask, xK_l), nextWS)
          , (( controlMask .|. mod4Mask, xK_h), prevWS)
          , (( controlMask .|. mod4Mask .|. mod1Mask, xK_l), shiftToNext >> nextWS)
          , (( controlMask .|. mod4Mask .|. mod1Mask, xK_h), shiftToPrev >> prevWS)
        ]
