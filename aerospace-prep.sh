#!/bin/sh
defaults write -g NSWindowShouldDragOnGesture -bool true
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false
defaults write com.apple.spaces spans-displays -bool true && killall SystemUIServer
defaults write com.apple.dock expose-roup-apps -bool true && killall Dock
