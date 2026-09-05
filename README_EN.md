# Silivue

English · [简体中文](README.md)

![Silivue icon](Design/Silivue-AppIcon-Source.png)

Silivue is a native, lightweight, and completely free macOS menu bar system monitor. It provides real-time CPU, memory, network, disk, battery, and temperature information, with historical charts and a detailed data window.

## Features

- Total, user, and system CPU utilization
- Memory usage, cache, swap, and memory pressure
- Network upload/download speed and connection details
- Disk capacity and read/write activity
- Battery level, charging state, and health information
- Temperature and fan status when supported by the Mac
- Quick access to macOS Activity Monitor from the details window
- Real-time charts and local historical data
- Private 24-hour and 7-day health summaries, period comparisons, and an anomaly timeline
- Actionable local explanations for CPU, memory, network, and disk conditions
- Configurable alerts for CPU, memory pressure, disk space, and thermal pressure
- CSV export for metric history in the selected period
- Multiple menu bar display modes and refresh intervals
- Launch at login

Every feature is free. There are no subscriptions, in-app purchases, or feature gates.

## Requirements

- macOS 13.0 or later
- Xcode 15 or a compatible Swift 5.9 toolchain

## Build and Run

```bash
git clone <repository-url>
cd Silivue
swift build
swift run Silivue
```

You can also open `Package.swift` in Xcode, select the `Silivue` scheme, and run the app.

## Tests

```bash
swift test
```

## Packaging

Create a debug package:

```bash
./Scripts/build-debug-package.sh
```

Create DMG and PKG distribution packages:

```bash
./Scripts/build-dmg.sh
```

Before distribution, configure signing in Xcode and Apple Developer using:

- Bundle ID: `com.upupdays.silivue`
- App Group: `group.com.upupdays.silivue`

## Privacy

Silivue performs system monitoring, health analysis, anomaly detection, and history storage locally. Notifications are delivered locally by macOS, and CSV files are created only at a location selected by the user. The current version does not upload network addresses, health summaries, or system-monitoring data.

## Project Structure

```text
Sources/MonitorEngine   System data providers and monitoring engine
Sources/DataLayer       Settings and historical data storage
Sources/UIComponents    SwiftUI and AppKit interface components
Sources/StatusStats     Application entry point (internal source directory name)
Tests                   Unit and integration tests
```

## License

No open-source license has been added yet. Unless a license is provided, no permission to copy, modify, or distribute this project is granted.
