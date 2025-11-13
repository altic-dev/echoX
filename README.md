# EchoX

A minimal macOS menubar app that records your voice and plays it back with a configurable delay.

## Features

- Record audio by pressing and holding a keyboard shortcut
- Playback with configurable delay (0-5 seconds)
- Customizable keyboard shortcuts
- Visual recording indicator
- Menubar-only interface (no dock icon)

## Requirements

- macOS 14.0+
- Xcode 15.0+

## Installation

### Build from Source

1. Clone the repository:
```bash
git clone https://github.com/yourusername/EchoX.git
cd EchoX
```

2. Open the project in Xcode:
```bash
open EchoX.xcodeproj
```

3. Build and run (⌘R)

## Setup

### Required Permissions

EchoX requires two permissions to function:

1. **Microphone Access** - Required for recording audio
   - Grant when prompted on first launch
   - Or enable in: System Settings → Privacy & Security → Microphone

2. **Accessibility Access** - Required for global keyboard shortcuts
   - Enable in: System Settings → Privacy & Security → Accessibility
   - Add EchoX and toggle it on

Check permission status in the app's Settings window.

## Usage

1. Launch EchoX (waveform icon appears in menubar)
2. Press and hold your shortcut key (default: Option+G)
3. Speak while holding the shortcut
4. Release to stop recording
5. Audio plays back after the configured delay

### Settings

Click the menubar icon → Settings to configure:

- **Playback Delay** - Time between recording and playback (0-5s)
- **Keyboard Shortcut** - Click to record a new shortcut
- **Audio Input** - Select your microphone device
- **Permissions** - Check and enable required permissions

## Troubleshooting

### App Interface

EchoX does not have a traditional window or dock icon. After launching, look for the waveform icon in your menubar (top-right corner of your screen). Click this icon to access Settings and other options.

### Permission Issues

Both Microphone and Accessibility permissions must be granted for EchoX to work properly:

- **Microphone** - Required for audio recording
- **Accessibility** - Required for global keyboard shortcuts to function

You can verify both permissions are granted in the Settings window (menubar icon → Settings).

### Accessibility Permission Not Working

If the app shows "Accessibility: Denied" even after you have added EchoX to the Accessibility list in System Settings:

1. Quit EchoX completely
2. Verify EchoX is checked/enabled in: System Settings → Privacy & Security → Accessibility
3. Relaunch EchoX

The app should automatically restart when permission is granted, but a manual restart may be needed if the permission state is not updating correctly.

### Common Issues

- **Shortcuts not working** - Verify Accessibility permission is granted
- **No audio recording** - Verify Microphone permission is granted
- **Can't find the app** - Look for the waveform icon in the menubar (top-right)

## Default Settings

- Shortcut: cmd + shift + Z [configurable in settings]  
- Delay: 0.5 seconds
- Audio: System default microphone

If you have any issues - create an issue on github so I can take a look at it.

Please ⭐️ the repo if you like it and if it's useful.  


## License

MIT
