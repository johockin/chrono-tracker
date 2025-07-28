# ChronoTracker Testing Guide

## Quick Start Testing

### Option 1: Use the Self-Extracting Installer
1. Download the installer:
   ```bash
   curl -O https://raw.githubusercontent.com/johockin/chrono-tracker/main/ChronoTracker-Installer.sh
   chmod +x ChronoTracker-Installer.sh
   ```

2. Go to any Xcode project directory:
   ```bash
   cd /path/to/your/xcode/project
   ./ChronoTracker-Installer.sh
   ```

### Option 2: Manual Installation
1. Clone this repo into your Xcode project:
   ```bash
   cd /path/to/your/xcode/project
   git clone https://github.com/johockin/chrono-tracker.git
   cp -r chrono-tracker/ChronoTracker .
   rm -rf chrono-tracker
   ```

2. Run the installer:
   ```bash
   ./ChronoTracker/Scripts/install.sh
   ```

## Required Permissions

ChronoTracker needs **Screen Recording** permission to capture screenshots.

### First Run Setup
1. Make a commit in your project:
   ```bash
   git add . && git commit -m "Test ChronoTracker"
   ```

2. macOS will show a permission dialog:
   ```
   "Terminal" would like to record this computer's screen.
   Screen recording is needed to take screenshots of your app.
   ```

3. Click **"Open System Preferences"**

4. In **Security & Privacy > Privacy > Screen Recording**:
   - Check the box next to **Terminal** (or your terminal app)
   - You may need to restart Terminal

### Alternative: Pre-authorize
Go to **System Preferences > Security & Privacy > Privacy > Screen Recording** and manually add your terminal app.

## Testing the Installation

### 1. Basic Functionality Test
```bash
# Make a test commit
echo "// Test change" >> some-file.swift
git add . && git commit -m "Test ChronoTracker capture"

# Wait ~15 seconds, then check for screenshots
ls ChronoTracker/*.png
```

### 2. Config App Test
```bash
# Build and open the config app
cd ChronoTracker/Config
./build.sh
open "../ChronoTracker Config.app"
```

### 3. Historical Import Test
```bash
# Import screenshots from git history
./ChronoTracker/Scripts/historical-import.sh
```

## What Should Happen

✅ **After first commit:**
- Wait ~15 seconds
- Screenshots appear in `ChronoTracker/` folder
- Named like: `2025-07-28_14-32-15_Main-Window.png`

✅ **Config app:**
- Opens a simple macOS app
- Shows enable/disable toggle
- Frequency settings
- View exclusion options

✅ **Historical import:**
- Scans git history
- Shows progress for each commit
- Creates `[H]` prefixed historical screenshots

## Troubleshooting

### No Screenshots Appearing
1. Check `ChronoTracker/❗️ERRORS.txt` for error messages
2. Verify screen recording permission is granted
3. Ensure your app builds successfully: `xcodebuild -list`

### Permission Denied Errors
```bash
# Check if Terminal has screen recording permission
system_profiler SPPrivacyDataType | grep -A 3 "Screen Recording"
```

### Build Failures
ChronoTracker will try fallback options:
- Existing app in `/Applications`
- Previous builds in `~/Library/Developer/Xcode/DerivedData`

## Test Projects

### Create a Simple Test App
```bash
# Create a new SwiftUI project for testing
mkdir TestApp && cd TestApp
git init

# Create a minimal Xcode project
# (Use Xcode: File > New > Project > iOS > App)
# Name: TestApp, Interface: SwiftUI
```

### Test Different Scenarios
1. **Normal commit** - should capture after 15 seconds
2. **Rapid commits** - frequency settings should work
3. **App not running** - should build and launch headlessly
4. **Build failure** - should try fallback locations
5. **No windows** - should handle gracefully

## Expected File Structure After Testing
```
YourProject/
├── YourApp.xcodeproj
├── Sources/...
└── ChronoTracker/
    ├── 2025-07-28_14-32-15_Main-Window.png
    ├── 2025-07-28_14-35-22_Settings.png
    ├── 2025-07-25_[H]_Main-Window.png (historical)
    ├── ChronoTracker Config.app
    ├── Scripts/...
    ├── Config/...
    ├── README.md
    └── config.json
```

## Performance Notes

- Screenshots are captured **after** commits (non-blocking)
- Build time: ~10-30 seconds depending on project size
- Screenshot time: ~2-3 seconds per window
- Total delay: ~15-45 seconds per commit
- Disk usage: ~50-200KB per screenshot (PNG)

## Uninstalling

To remove ChronoTracker:
```bash
rm -rf ChronoTracker/
git config --unset core.hooksPath  # if hooks path was changed
rm .git/hooks/post-commit  # remove the hook
```