# Website Installation Instructions

## For Your Website/Documentation:

### Simple Copy-Paste Box:

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│ Install ChronoTracker (paste in terminal):                                     │
│                                                                                 │
│ curl -sL https://raw.githubusercontent.com/johockin/chrono-tracker/main/       │
│ ChronoTracker-Installer.sh | sh                                                │
│                                                                                 │
│ Then make a commit to see your first screenshot!                               │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Full Instructions:

**Install ChronoTracker in 30 seconds:**

1. **Open Terminal in your Xcode project folder**
2. **Paste this command:**
   ```bash
   curl -sL https://raw.githubusercontent.com/johockin/chrono-tracker/main/ChronoTracker-Installer.sh | sh
   ```
3. **Make a commit:**
   ```bash
   git commit -m "Test ChronoTracker" --allow-empty
   ```
4. **Wait 15 seconds** - screenshots appear in `ChronoTracker/` folder!

### Marketing Copy:

> **Never lose track of your app's evolution again.**
> 
> ChronoTracker automatically captures screenshots of your app on every commit, creating a visual timeline of your development progress. Install once, forget it exists - screenshots just appear.
>
> ✨ **Zero maintenance** • 📸 **Automatic capture** • 🔒 **Privacy-first** • 🚀 **Works with any Mac app**

### Technical Details for Developers:

- **Trigger:** Git post-commit hook (non-blocking)
- **Capture:** ScreenCaptureKit (macOS 12.3+)
- **Storage:** Local PNG files with timestamps
- **Privacy:** No cloud, no telemetry, no analytics
- **Compatibility:** SwiftUI, AppKit, Objective-C projects