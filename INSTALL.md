# Install ChronoTracker

**Automatic UI screenshot tracking for your Mac app development.**

## One-Line Install

Copy and paste this into your terminal from your Xcode project directory:

```bash
curl -sL https://raw.githubusercontent.com/johockin/chrono-tracker/main/ChronoTracker-Installer.sh | sh
```

## What This Does

1. Downloads the ChronoTracker installer
2. Sets up screenshot capture on git commits  
3. Creates a `ChronoTracker/` folder in your project
4. Self-destructs the installer when done

## First Use

After installation, make any commit:

```bash
git add . && git commit -m "Test ChronoTracker"
```

Wait ~15 seconds and check the `ChronoTracker/` folder for screenshots of your app!

## Permission Required

macOS will ask for **Screen Recording** permission the first time. Just click "Open System Preferences" and enable it for your terminal.

---

**That's it!** ChronoTracker will now automatically capture screenshots ~15 seconds after every commit, showing the evolution of your app's UI over time.

For advanced configuration, build the config app:
```bash
cd ChronoTracker/Config && ./build.sh
```