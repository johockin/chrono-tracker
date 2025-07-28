# ChronoTracker

Automatic UI screenshot tracking for your macOS app development.

## Installation

1. Run the install script:
   ```bash
   ./ChronoTracker/Scripts/install.sh
   ```

2. Build the config app (optional):
   ```bash
   cd ChronoTracker/Config && ./build.sh
   ```

3. That's it! ChronoTracker will now capture screenshots ~15 seconds after each commit.

## Historical Import (NEW!)

Want to see your UI evolution from the beginning? Import screenshots from your Git history:

```bash
./ChronoTracker/Scripts/historical-import.sh
```

This will:
- Scan commits that modified UI files (.swift, .xib, .storyboard)
- Skip commits within 1 hour of each other
- Build and capture screenshots from each commit
- Mark historical screenshots with [H] prefix

## How it works

- Git post-commit hook triggers capture
- Your app is built and launched invisibly
- All windows are captured as PNG screenshots
- Files are saved with timestamps and window names
- Everything lives in the `ChronoTracker/` folder

## Configuration

Open `ChronoTracker Config.app` to:
- Enable/disable tracking
- Set capture frequency (every/alternate/3rd commit)
- Exclude specific windows
- Configure error log auto-opening

## Disabling

To temporarily disable ChronoTracker:
```bash
touch ChronoTracker/.disabled
```

To re-enable:
```bash
rm ChronoTracker/.disabled
```

## Troubleshooting

Check `ChronoTracker/❗️ERRORS.txt` if screenshots aren't appearing.

## Requirements

- macOS 12.3 or later
- Xcode project in the repository
- Git repository