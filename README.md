# ChronoTracker

> **⚠️ PRE-ALPHA SOFTWARE** - This is experimental software under active development. Use at your own risk and expect bugs, breaking changes, and incomplete features.

**Automatic UI screenshot tracking for your macOS app development.**

Never lose track of your app's visual evolution again. ChronoTracker automatically captures screenshots of your app's UI every time you commit code, creating a visual timeline of your development progress.

![ChronoTracker Demo](https://via.placeholder.com/800x400/2d3748/ffffff?text=ChronoTracker+Demo+%28Coming+Soon%29)

## ✨ What It Does

- 📸 **Automatic Screenshots** - Captures your app's UI ~15 seconds after every git commit
- 🕰️ **Visual Timeline** - Creates a timestamped history of your app's evolution
- 🔄 **Historical Import** - Scan your git history and generate screenshots retroactively
- 🎯 **Zero Maintenance** - Install once, forget it exists
- 🔒 **Privacy-First** - Everything stays local, no cloud, no telemetry
- ⚙️ **Configurable** - Control frequency, exclude windows, customize settings

## 🚀 Quick Install

Copy and paste this into your terminal from your Xcode project directory:

```bash
curl -sL https://raw.githubusercontent.com/johockin/chrono-tracker/main/ChronoTracker-Installer.sh | sh
```

That's it! ChronoTracker will automatically:
- Set up git repository if needed
- Install screenshot capture system
- Configure git hooks
- Give you next steps

## 📋 Requirements

- **macOS 12.3+** (for ScreenCaptureKit)
- **Xcode project** (SwiftUI, AppKit, or Objective-C)
- **Git repository** (local only, no remote needed)
- **Screen Recording permission** (macOS will prompt on first use)

## 🎯 How It Works

1. **Make a commit** to your project: `git commit -m "Add new feature"`
2. **Wait ~15 seconds** while ChronoTracker:
   - Builds your app invisibly
   - Launches it headlessly (no UI flicker)
   - Captures screenshots of all windows
   - Saves them with timestamps
3. **Check your screenshots** in the `ChronoTracker/` folder

## 📁 What Gets Created

```
YourProject/
├── YourApp.xcodeproj
├── Sources/...
└── ChronoTracker/                    ← New folder
    ├── 2025-07-28_14-32-15_MainWindow.png
    ├── 2025-07-28_14-35-22_Settings.png
    ├── 2025-07-25_[H]_Login.png      ← Historical import
    ├── ChronoTracker Config.app      ← Settings
    ├── README.md                     ← Documentation
    └── Scripts/...                   ← Internal files
```

## ⚙️ Configuration

Build and open the config app:

```bash
cd ChronoTracker/Config && ./build.sh
open "../ChronoTracker Config.app"
```

Configure:
- **Capture frequency** (every commit, every 2nd, every 3rd)
- **Window exclusion** (skip debug/system windows)
- **Error handling** (auto-open error log)
- **Enable/disable** tracking

## 🕰️ Historical Import

Want to see your app's evolution from the beginning? Import screenshots from your git history:

```bash
./ChronoTracker/Scripts/historical-import.sh
```

This will:
- Scan commits that modified UI files
- Skip commits within 1 hour of each other
- Build and capture screenshots from each commit
- Mark historical screenshots with `[H]` prefix

## 🔧 Troubleshooting

### No Screenshots Appearing?

1. **Check permissions**: Go to System Preferences > Security & Privacy > Privacy > Screen Recording and enable your terminal app
2. **Check errors**: Look at `ChronoTracker/❗️ERRORS.txt` for error messages  
3. **Verify build**: Make sure your app builds with `xcodebuild -list`

### Permission Denied?

```bash
# Check screen recording permission
system_profiler SPPrivacyDataType | grep -A 3 "Screen Recording"
```

### Build Failures?

ChronoTracker tries multiple fallback options:
- Existing app in `/Applications`
- Previous builds in `~/Library/Developer/Xcode/DerivedData`

## 🛠️ Advanced Usage

### Manual Screenshots

```bash
# Take screenshots right now (without committing)
./ChronoTracker/Scripts/screenshot.swift "/path/to/your.app"
```

### Disable Temporarily

```bash
touch ChronoTracker/.disabled    # Disable
rm ChronoTracker/.disabled       # Re-enable
```

### Update ChronoTracker

Just run the installer again - it will preserve your screenshots:

```bash
curl -sL https://raw.githubusercontent.com/johockin/chrono-tracker/main/ChronoTracker-Installer.sh | sh
```

## 🚨 Pre-Alpha Warnings

**This software is experimental. Known limitations:**

- ⚠️ **Breaking Changes** - Updates may break your setup
- ⚠️ **macOS Only** - No Windows/Linux support yet  
- ⚠️ **Limited Testing** - May not work with all project configurations
- ⚠️ **Active Development** - Features may change without notice
- ⚠️ **Backup Your Work** - Always backup important projects before installing
- ⚠️ **Brief Window Flash** - Apps must be briefly visible for screenshot capture (macOS limitation)

**Use in production at your own risk.**

## 📋 Known Technical Limitations

### Window Visibility Requirement
ChronoTracker faces a fundamental macOS constraint: ScreenCaptureKit can only capture windows that are "on-screen" (visible). This means:

- **Brief Flash**: Your app windows will appear briefly (~0.5 seconds) during capture
- **Not Truly Invisible**: While we minimize disruption with positioning and transparency, complete invisibility isn't possible
- **Architectural Trade-off**: This is a limitation of the script-based approach, not a bug

### Current Optimizations
- ⚡ **Fast Capture**: 0.5-second window visibility (down from 15 seconds)
- 👻 **Near Transparency**: Windows set to 10% opacity during capture
- 📍 **Off-Screen Positioning**: Windows moved just outside screen bounds
- 🔄 **Parallel Processing**: Multiple windows captured simultaneously

### Future Solutions
- 🍎 **Menu Bar App**: Long-term solution for truly invisible capture
- 🔬 **Private APIs**: Exploring deeper macOS integration (may require signed app)

## 🤝 Contributing

This is a passion project in early development. Issues, suggestions, and pull requests welcome!

- 🐛 **Report bugs**: [GitHub Issues](https://github.com/johockin/chrono-tracker/issues)
- 💡 **Suggest features**: Start a discussion
- 🛠️ **Submit fixes**: Pull requests appreciated

## 📜 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

Built with love for the indie developer community. Special thanks to the Swift and macOS development communities for inspiration and tools.

---

**Remember: This is pre-alpha software. Use at your own risk and always backup your projects.**