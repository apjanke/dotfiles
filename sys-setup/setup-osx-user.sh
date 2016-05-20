#!/bin/bash
#
# Updates the current user's settings to my preferred state.
# This script is idempotent, so it can be run repeatedly on the same machine
# and account.
#
# The coding style has a lot of copy-and-paste instead of being factored in to
# functions. This is intentional, to allow easy interactive copy-and-pasting of
# individual commands to the terminal.

# I'm not bothering with the kill right now because it screws up the session, and you
# need to log out and back in anyway
DO_KILL=0

function CFPreferencesAppSynchronize() {
  python - <<END
from Foundation import CFPreferencesAppSynchronize
CFPreferencesAppSynchronize('$1')
END
}

# Delete a default quietly and idempotently
function defaults-delete() {
  defaults delete "$1" "$2" 2>/dev/null
  true
}

MYDIR="$( dirname "${BASH_SOURCE[0]}" )"
DROPBOX="$HOME/Dropbox"
SERIALS_DIR="$DROPBOX/records/licenses and serials"

################################################
# Dock
################################################

# Left side of screen
defaults write com.apple.dock orientation -string left
defaults write com.apple.dock pinning -string middle

# Dim icons of hidden apps
defaults write com.apple.dock showhidden -bool true

# Dock icon size
defaults write com.apple.dock tilesize -float 32

# Autohide dock
defaults write com.apple.dock autohide -bool true
# Auto-hiding delay: killed, because I prefer the default behavior
# Remove the auto-hiding Dock delay
#defaults write com.apple.dock autohide-delay -float 0
defaults-delete com.apple.dock autohide-delay
# Remove the animation when hiding/showing the Dock
#defaults write com.apple.dock autohide-time-modifier -float 0
defaults-delete com.apple.dock autohide-time-modifier

# Change minimize/maximize window effect
defaults write com.apple.dock mineffect -string "scale"

# Don’t animate opening applications from the Dock
defaults write com.apple.dock launchanim -bool false

# Speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.1

# Don’t group windows by application in Mission Control
# (i.e. use the old Exposé behavior instead)
defaults write com.apple.dock expose-group-by-app -bool false

# Disable Dashboard
defaults write com.apple.dashboard mcx-disabled -bool true

# Don’t show Dashboard as a Space
defaults write com.apple.dock dashboard-in-overlay -bool true

# Remove unwanted apps
unwanted_apps=(
  Launchpad
  Mail
  Contacts
  Notes
  Reminders
  Maps
  Messages
  FaceTime
  iBooks
  "App Store"
  "Photo Booth"
  "System Preferences"
  Pages
  Numbers
  Keynote
  Photos
  )
for app in "${unwanted_apps[@]}"; do
  dloc=$(defaults read com.apple.dock persistent-apps | grep file-label | awk "/$app/  {print NR}")
  if [ -n "$dloc" ]; then
    dloc=$[$dloc-1]
    /usr/libexec/PlistBuddy -c "Delete persistent-apps:$dloc" ~/Library/Preferences/com.apple.dock.plist
  fi
done

killall Dock

################################################
# Misc OS UI stuff
################################################

# Hot corners
# Key names: wvous-<loc>-corner, wvous-<loc>-modifier
#   where <loc> may be: tl, tr, bl, br
# Possible "corner" values:
#  0: no-op
#  2: Mission Control
#  3: Show application windows
#  4: Desktop
#  5: Start screen saver
#  6: Disable screen saver
#  7: Dashboard
# 10: Put display to sleep
# 11: Launchpad
# 12: Notification Center

# Top left screen corner → Start screen saver
defaults write com.apple.dock wvous-tl-corner -int 5
defaults write com.apple.dock wvous-tl-modifier -int 0
# Top right screen corner → Desktop
defaults write com.apple.dock wvous-tr-corner -int 4
defaults write com.apple.dock wvous-tr-modifier -int 0

# Disable transparency in the menu bar and elsewhere on Yosemite
defaults write com.apple.universalaccess reduceTransparency -bool true

# Set sidebar icon size to medium
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 1

# Increase window resize speed for Cocoa applications
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Disable Application Resume
defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false

# Disable the over-the-top focus ring animation
defaults write NSGlobalDomain NSUseAnimatedFocusRing -bool false

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable the “Are you sure you want to open this application?” dialog
#defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable automatic termination of inactive apps
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

# Set Help Viewer windows to non-floating mode
defaults write com.apple.helpviewer DevMode -bool true

# Reveal IP address, hostname, OS version, etc. when clicking the clock
# in the login window
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# Check for software updates daily, not just once per week
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

################################################
# Trackpad, mouse, keyboard, and other HCI peripheral stuff
################################################

# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Note: the pinch-to-zoom and two-finger-rotate settings here seem to work, but they may
# not be reflected in the System Preferences thing. Running this seems to disable the behavior for
# me, but the boxes are still checked in System Preferences > Trackpad
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad UserPreferences -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFiveFingerPinchGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadPinch -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRotate -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadTwoFingerDoubleTapGesture -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadTwoFingerFromRightEdgeSwipeGesture -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerTapGesture -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerVertSwipeGesture -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerHorizSwipeGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerPinchGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerVertSwipeGesture -int 2

defaults write com.apple.AppleMultitouchTrackpad UserPreferences -int 1
defaults write com.apple.AppleMultitouchTrackpad TrackpadRotate -bool false
defaults write com.apple.AppleMultitouchTrackpad TrackpadPinch -bool false
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerDoubleTapGesture -int 0
defaults write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerFromRightEdgeSwipeGesture -int 0
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 0
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 0
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 0
defaults write com.apple.AppleMultitouchTrackpad TrackpadFiveFingerPinchGesture -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerHorizSwipeGesture -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerPinchGesture -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerHorizSwipeGesture -int 0
defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerVertSwipeGesture -int 2

defaults write com.apple.AppleMultitouchTrackpad UserPreferences -int 1

defaults write com.apple.dock showMissionControlGestureEnabled -bool true
defaults write com.apple.dock showAppExposeGestureEnabled -bool true
defaults write com.apple.dock showDesktopGestureEnabled -bool true
defaults write com.apple.dock showLaunchpadGestureEnabled -bool false

# Smart zoom disabled (this doesn't seem to actually work)
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseOneFingerDoubleTapGesture -int 0
# Double-tap to define disabled (this doesn't seem to actually work)
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseTwoFingerDoubleTapGesture -int 0

# Disable “natural” (Lion-style) scrolling
# (In VMware guest VMs, re-enable it, since it doesn't interact well there)
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Always show scrollbars
# Possible values: 'WhenScrolling', 'Automatic' and 'Always'
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"

# Swipe between pages with two fingers
defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool false

# Enable full keyboard access for all controls
# (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Use F1, F2, etc. as standard function keys
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true

# Analog clock in menu bar
defaults write com.apple.menuextra.clock IsAnalog -bool true

# Remove duplicates in the “Open With” menu (also see `lscleanup` alias)
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

###############################################################################
# Screen                                                                      #
###############################################################################

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Configure screen saver
# (Careful with this; it seems to break things)
if false; then
defaults -currentHost delete com.apple.screensaver moduleDict
defaults -currentHost write com.apple.screensaver "CleanExit" -string "YES"
defaults -currentHost write com.apple.screensaver "PrefsVersion" -int 100
defaults -currentHost write com.apple.screensaver moduleDict -dict-add "displayName" -string Random
defaults -currentHost write com.apple.screensaver moduleDict -dict-add "moduleName" -string Random
defaults -currentHost write com.apple.screensaver moduleDict -dict-add "path" -string "/System/Library/Screen Savers/Random.saver"
defaults -currentHost write com.apple.screensaver moduleDict -dict-add "type" -int 8
fi

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# Enable spring loading for directories
defaults write NSGlobalDomain com.apple.springing.enabled -bool false

# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Desktop wallpaper
osascript -e 'tell application "Finder" to set desktop picture to POSIX file "/Library/Desktop Pictures/Wave.jpg"'

################################################
# Finder & Spotlight
################################################

# Finder: disable window animations and Get Info animations
defaults write com.apple.finder DisableAllAnimations -bool true

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Do not display tags
defaults write com.apple.finder ShowRecentTags -boolean false

# Use list view in all Finder windows by default
# Modes: 'Nlsv' = list, 'icnv', `clmv` = column, 'Flwv'
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Set default location for new Finder windows
# For home dir, use "PfHm"
# For desktop, use "PfDe"
# For arbitrary paths, use "PfLo" and `file:///full/path/here/`
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file:///Users/$USER/"

# Show icons for hard drives, servers, and removable media on the desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false

# Finder: show hidden files by default
#defaults write com.apple.finder AppleShowAllFiles -bool true

# Finder: show all filename extensions
#defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Disable the warning before emptying the Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Spring loading for directories
defaults write NSGlobalDomain com.apple.springing.enabled -bool false

# Show the ~/Library folder
chflags nohidden ~/Library

# Remove Dropbox’s green checkmark icons in Finder
#file=/Applications/Dropbox.app/Contents/Resources/emblem-dropbox-uptodate.icns
#[ -e "${file}" ] && mv -f "${file}" "${file}.bak"

# Expand the following File Info panes:
# “General”, “Open with”, and “Sharing & Permissions”
defaults write com.apple.finder FXInfoPanesExpanded -dict \
  General -bool true \
  OpenWith -bool true \
  Privileges -bool true


# Hide Spotlight tray-icon (and subsequent helper)
#sudo chmod 600 /System/Library/CoreServices/Search.bundle/Contents/MacOS/Search
# Disable Spotlight indexing for any volume that gets mounted and has not yet
# been indexed before.
# Use `sudo mdutil -i off "/Volumes/foo"` to stop indexing any volume.
sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes"
# Change indexing order and disable some search results
# Yosemite-specific search results (remove them if you are using OS X 10.9 or older):
#   MENU_DEFINITION
#   MENU_CONVERSION
#   MENU_EXPRESSION
#   MENU_SPOTLIGHT_SUGGESTIONS (send search queries to Apple)
#   MENU_WEBSEARCH             (send search queries to Apple)
#   MENU_OTHER
spotlight_items=(
  '{"enabled" = 1;"name" = "APPLICATIONS";}'
  '{"enabled" = 1;"name" = "SYSTEM_PREFS";}'
  '{"enabled" = 1;"name" = "DIRECTORIES";}'
  '{"enabled" = 1;"name" = "PDF";}'
  '{"enabled" = 1;"name" = "CONTACT";}'
  '{"enabled" = 1;"name" = "EVENT_TODO";}'
  '{"enabled" = 1;"name" = "IMAGES";}'
  '{"enabled" = 1;"name" = "MESSAGES";}'
  '{"enabled" = 0;"name" = "FONTS";}'
  '{"enabled" = 0;"name" = "DOCUMENTS";}'
  '{"enabled" = 0;"name" = "BOOKMARKS";}'
  '{"enabled" = 0;"name" = "MUSIC";}'
  '{"enabled" = 0;"name" = "MOVIES";}'
  '{"enabled" = 0;"name" = "PRESENTATIONS";}'
  '{"enabled" = 0;"name" = "SPREADSHEETS";}'
  '{"enabled" = 0;"name" = "SOURCE";}'
  )
# If Yosemite or later:
if false; then
  spotlight_items=("${spotlight_items[@]}"
  '{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
  '{"enabled" = 0;"name" = "MENU_OTHER";}' \
  '{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
  '{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
  '{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
  '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'
  )
fi
defaults write com.apple.spotlight orderedItems -array "${spotlight_items[@]}"

################################################
# Safari & WebKit
################################################

# Enable Safari’s debug menu
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

# Make Safari’s search banners default to Contains instead of Starts With
defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false

# Remove useless icons from Safari’s bookmarks bar
defaults write com.apple.Safari ProxiesInBookmarksBar "()"

# Enable the Develop menu and the Web Inspector in Safari
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Add a context menu item for showing the Web Inspector in web views
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

# Safari opens with: A new window
defaults write com.apple.Safari AlwaysRestoreSessionAtLaunch -bool false

# New windows open with: Empty Page
defaults write com.apple.Safari NewWindowBehavior -int 1

# New tabs open with: Empty Page
defaults write com.apple.Safari NewTabBehavior -int 1

# Homepage
defaults write com.apple.Safari HomePage -string "about:blank"

# Open pages in tabs instead of windows: automatically
defaults write com.apple.Safari TabCreationPolicy -int 1

# Don't make new tabs active
defaults write com.apple.Safari OpenNewTabsInFront -bool false

# Command-clicking a link creates tabs
defaults write com.apple.Safari CommandClickMakesTabs -bool true

# Do not track
defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true

# Don't even ask about the push notifications
defaults write com.apple.Safari CanPromptForPushNotifications -bool false

# Enable the Develop menu and the Web Inspector in Safari
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Add a context menu item for showing the Web Inspector in web views
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

################################################
# Mail.app
################################################

# Disable send and reply animations in Mail.app
defaults write com.apple.mail DisableReplyAnimations -bool true
defaults write com.apple.mail DisableSendAnimations -bool true

# Copy email addresses as `foo@example.com` instead of `Foo Bar <foo@example.com>` in Mail.app
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

# Add the keyboard shortcut ⌘ + Enter to send an email in Mail.app
defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Send" -string "@\\U21a9"

################################################
# iTerm2
################################################

# Don’t display the annoying prompt when quitting iTerm
defaults write com.googlecode.iterm2 PromptOnQuit -bool false

################################################
# Time Machine
################################################

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

################################################
# Activity Monitor
################################################

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Update Frequency: Often (2 sec)
defaults write com.apple.ActivityMonitor UpdatePeriod -int 2

################################################
# Tweetbot
################################################

# Display only username
defaults write com.tapbots.TweetbotMac displayNameType -int 1

# Don't pin timeline to top
defaults write com.tapbots.TweetbotMac streamingPinToTopEnabled -bool false

# No sounds
defaults write com.tapbots.TweetbotMac soundType -int 2

# Image Thumbnails: Small
defaults write com.tapbots.TweetbotMac statusViewImageType -int 1

# Bypass the annoyingly slow t.co URL shortener
defaults write com.tapbots.TweetbotMac OpenURLsDirectly -bool true

################################################
# Terminal.app
################################################

# Copy the Basic profile to "Basic Improved"
pathToTerminalPrefs="${HOME}/Library/Preferences/com.apple.Terminal.plist"
/usr/libexec/PlistBuddy -c "Copy :Window\ Settings:Basic :Window\ Settings:Basic\ Improved" ${pathToTerminalPrefs}
/usr/libexec/PlistBuddy -c "Set :Window\ Settings:Basic\ Improved:name Basic\ Improved" ${pathToTerminalPrefs}

# Modify the "Basic Improved" profile
# Close if the shell exited cleanly
/usr/libexec/PlistBuddy -c "Add :Window\ Settings:Basic\ Improved:shellExitAction integer 1" ${pathToTerminalPrefs}
# Make the window a bit larger
/usr/libexec/PlistBuddy -c "Add :Window\ Settings:Basic\ Improved:columnCount integer 100" ${pathToTerminalPrefs}
/usr/libexec/PlistBuddy -c "Add :Window\ Settings:Basic\ Improved:rowCount integer 30" ${pathToTerminalPrefs}

# Set the "Basic Improved" as the default
defaults write com.apple.Terminal "Startup Window Settings" -string "Basic Improved"
defaults write com.apple.Terminal "Default Window Settings" -string "Basic Improved"

# Open with: default login shell
defaults write com.apple.Terminal Shell -string ""

# Disable the line/prompt marker display (El Capitan+)
defaults write com.apple.Terminal ShowLineMarks -bool false

CFPreferencesAppSynchronize "com.apple.Terminal"

################################################
# Miscellaneous
################################################

# Use plain text mode for new TextEdit documents
defaults write com.apple.TextEdit RichText -int 0
# Open and save files as UTF-8 in TextEdit
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

# Enable the debug menu in Disk Utility
defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
defaults write com.apple.DiskUtility advanced-image-options -bool true

# Enable Debug Menu in the Mac App Store
defaults write com.apple.appstore ShowDebugMenu -bool true

# Enable the WebKit Developer Tools in the Mac App Store
defaults write com.apple.appstore WebKitDeveloperExtras -bool true

# UI sound effects
# (requires logout and some time to take effect)
defaults write com.apple.systemsound com.apple.sound.uiaudio.enabled -int 0

################################################
# Google Chrome & Google Chrome Canary
################################################

# Disable the all too sensitive backswipe on trackpads
defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false
defaults write com.google.Chrome.canary AppleEnableSwipeNavigateWithScrolls -bool false

# Disable the all too sensitive backswipe on Magic Mouse
defaults write com.google.Chrome AppleEnableMouseSwipeNavigateWithScrolls -bool false
defaults write com.google.Chrome.canary AppleEnableMouseSwipeNavigateWithScrolls -bool false

# Use the system-native print preview dialog
defaults write com.google.Chrome DisablePrintPreview -bool true
defaults write com.google.Chrome.canary DisablePrintPreview -bool true

# Expand the print dialog by default
defaults write com.google.Chrome PMPrintingExpandedStateForPrint2 -bool true
defaults write com.google.Chrome.canary PMPrintingExpandedStateForPrint2 -bool true

# No birthdays in Calendar
defaults write com.apple.iCal "display birthdays calendar" -bool false

################################################
# Transmission.app
################################################

# Hide the donate message
defaults write org.m0k.transmission WarningDonate -bool false
# Hide the legal disclaimer
defaults write org.m0k.transmission WarningLegal -bool false

################################################
# Sublime Text
################################################

ST2_PREFS_DIR="$HOME/Library/Application Support/Sublime Text 2"
mkdir -p "$ST2_PREFS_DIR/Packages/User"
cp "$MYDIR/../settings-manual/Sublime Text 2/Preferences.sublime-settings" "$ST2_PREFS_DIR/Packages/User"
mkdir -p "$ST2_PREFS_DIR/Settings"
if [[ -e "$SERIALS_DIR/Sublime Text 2 license.txt" ]]; then
  cp "$SERIALS_DIR/Sublime Text 2 license.txt" "$ST2_PREFS_DIR/Settings/License.sublime_license"
fi

################################################
# F.lux
################################################

defaults write org.herf.Flux disable-com.apple.Aperture -int 1
defaults write org.herf.Flux lateColorTemp -int 3500
defaults write org.herf.Flux lateLoc -int 0
defaults write org.herf.Flux location -int 11231
defaults write org.herf.Flux locationTextField -string "11231"
defaults write org.herf.Flux locationType -string "Z"
defaults write org.herf.Flux nightColorTemp -float 4030
defaults write org.herf.Flux steptime -int 40
defaults write org.herf.Flux wakeTime -int 600

################################################
# File associations
################################################

if which duti >/dev/null; then
  if [[ -e "/Applications/BBEdit.app" ]]; then 
    duti -s com.barebones.bbedit .txt all
  fi
fi

################################################
# VM Guest specific stuff
################################################

# User settings for when running as a guest inside a VM

if pkgutil --pkg-info com.vmware.tools.macos.pkg.files &>/dev/null; then

  # Re-enable “natural” (Lion-style) scrolling
  # This will end up having old-style scrolling in effect, because of interaction
  # with the host's scrolling setup and/or the VM's mouse driver
  defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true

fi

################################################
# Kill affected applications
################################################

if [[ $DO_KILL == 1 ]]; then
  for app in "Activity Monitor" "Address Book" "Calendar" "Contacts" "cfprefsd" \
      "Dock" "Finder" "Google Chrome" "Google Chrome Canary" "Mail" "Messages" \
      "Opera" "Safari" "SizeUp" "Spectacle" "SystemUIServer" \
      "Transmission" "Twitter" "iCal"; do
    killall "${app}" > /dev/null 2>&1
  done
fi

echo "Done. Note that some of these changes require a logout/restart to take effect."

