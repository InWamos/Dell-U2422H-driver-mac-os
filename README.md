# Dell-U2422H-driver-mac-os

A lightweight macOS menu-bar replacement for Dell Display and Peripheral Manager, for the Dell U2422H.
It talks to the monitor over DDC/CI; for now it controls brightness.

## Install

Download the latest `U2422HControl-<version>.zip` from [Releases](../../releases/latest).
Install steps, including getting past Gatekeeper for this un-notarized app, are in the release notes
([packaging/release-notes.md](packaging/release-notes.md)).

Requires an Apple Silicon Mac on macOS 14 or later.

## Build from source

```bash
swift build -c release                    # menu-bar app + `ddc` CLI in .build/release/
packaging/bundle-app.sh 0.0.0-dev         # dist/U2422HControl.app and a zip
.build/release/ddc get 10                 # read brightness (VCP 0x10)
```

Every push to `main` that touches the app builds it and publishes a GitHub release `v0.1.<run number>`.
