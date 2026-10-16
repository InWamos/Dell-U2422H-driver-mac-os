## Install

1. Download `U2422HControl-<version>.zip` below, unzip it and move `U2422HControl.app` to `/Applications`.
2. The app is not notarized by Apple, so macOS blocks the first launch. Either run
   `xattr -dr com.apple.quarantine /Applications/U2422HControl.app`,
   or try to open it once, then go to **System Settings → Privacy & Security** and click **Open Anyway**.
3. The DELL icon appears in the menu bar.

Requires an Apple Silicon Mac on macOS 14 or later, with DDC/CI enabled in the monitor's on-screen menu.
Quit Dell Display and Peripheral Manager first — both apps talking DDC at once corrupt each other's messages.
