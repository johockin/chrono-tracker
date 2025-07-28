#!/bin/bash

# Build ChronoTracker Config app

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR="$SCRIPT_DIR"
OUTPUT_DIR="$SCRIPT_DIR/.."

echo "Building ChronoTracker Config app..."

cd "$CONFIG_DIR"

# Build the app
swift build -c release --arch arm64 --arch x86_64

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

# Create app bundle structure
APP_NAME="ChronoTracker Config.app"
APP_PATH="$OUTPUT_DIR/$APP_NAME"
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# Copy executable
cp ".build/apple/Products/Release/ChronoTracker Config" "$APP_PATH/Contents/MacOS/"

# Create Info.plist
cat > "$APP_PATH/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ChronoTracker Config</string>
    <key>CFBundleIdentifier</key>
    <string>com.chronotracker.config</string>
    <key>CFBundleName</key>
    <string>ChronoTracker Config</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.3</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Clean up build artifacts
rm -rf .build

echo "✅ ChronoTracker Config app built successfully!"
echo "📍 Location: $APP_PATH"