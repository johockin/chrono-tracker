#!/bin/bash

# ChronoTracker Installation Script
# Installs Git hooks and LaunchAgent for automatic UI screenshot tracking

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"
CHRONO_DIR="$PROJECT_ROOT/ChronoTracker"

echo "🚀 Installing ChronoTracker..."

# Check if we're in a git repository
if ! git -C "$PROJECT_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a Git repository. ChronoTracker requires Git."
    exit 1
fi

GIT_DIR=$(git -C "$PROJECT_ROOT" rev-parse --git-dir)
HOOKS_DIR="$GIT_DIR/hooks"

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Install Git post-commit hook
cat > "$HOOKS_DIR/post-commit" << 'EOF'
#!/bin/bash
# ChronoTracker Git Hook - Triggers screenshot capture after commit

PROJECT_ROOT=$(git rev-parse --show-toplevel)
CHRONO_DIR="$PROJECT_ROOT/ChronoTracker"

# Check if ChronoTracker is enabled
if [ -f "$CHRONO_DIR/.disabled" ]; then
    exit 0
fi

# Trigger screenshot capture asynchronously
"$CHRONO_DIR/Scripts/capture.sh" &

exit 0
EOF

chmod +x "$HOOKS_DIR/post-commit"

# Create capture script
cat > "$CHRONO_DIR/Scripts/capture.sh" << 'EOF'
#!/bin/bash

# ChronoTracker Capture Script
# Builds and launches app headlessly, captures screenshots

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CHRONO_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
PROJECT_ROOT="$( cd "$CHRONO_DIR/.." && pwd )"
ERROR_LOG="$CHRONO_DIR/❗️ERRORS.txt"
CONFIG_FILE="$CHRONO_DIR/config.json"
COMMIT_COUNT_FILE="$CHRONO_DIR/.commit_count"

# Log function
log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$ERROR_LOG"
    
    # Check if we should open error log
    if [ -f "$CONFIG_FILE" ]; then
        OPEN_LOG=$(cat "$CONFIG_FILE" | grep -o '"openErrorLogOnFailure":[^,}]*' | cut -d: -f2 | tr -d ' ')
        if [ "$OPEN_LOG" = "true" ]; then
            # Check if it's been >5 min since last open (to avoid spam)
            LAST_OPEN_FILE="$CHRONO_DIR/.last_error_open"
            NOW=$(date +%s)
            
            if [ -f "$LAST_OPEN_FILE" ]; then
                LAST_OPEN=$(cat "$LAST_OPEN_FILE")
                DIFF=$((NOW - LAST_OPEN))
                
                if [ $DIFF -gt 300 ]; then  # 5 minutes
                    open "$ERROR_LOG"
                    echo $NOW > "$LAST_OPEN_FILE"
                fi
            else
                open "$ERROR_LOG"
                echo $NOW > "$LAST_OPEN_FILE"
            fi
        fi
    fi
}

# Check capture frequency
should_capture() {
    # Default to every commit
    FREQUENCY="every"
    
    # Read frequency from config if exists
    if [ -f "$CONFIG_FILE" ]; then
        FREQ_VALUE=$(cat "$CONFIG_FILE" | grep -o '"captureFrequency":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$FREQ_VALUE" ]; then
            FREQUENCY="$FREQ_VALUE"
        fi
    fi
    
    # Track commit count
    COUNT=1
    if [ -f "$COMMIT_COUNT_FILE" ]; then
        COUNT=$(cat "$COMMIT_COUNT_FILE")
        COUNT=$((COUNT + 1))
    fi
    echo $COUNT > "$COMMIT_COUNT_FILE"
    
    # Determine if we should capture
    case "$FREQUENCY" in
        "every")
            return 0
            ;;
        "alternate")
            if [ $((COUNT % 2)) -eq 0 ]; then
                return 0
            fi
            ;;
        "third")
            if [ $((COUNT % 3)) -eq 0 ]; then
                return 0
            fi
            ;;
    esac
    
    return 1
}

# Check if we should capture this commit
if ! should_capture; then
    exit 0
fi

# Give the developer a moment to continue working
sleep 15

# Find .xcodeproj or .xcworkspace
WORKSPACE=$(find "$PROJECT_ROOT" -name "*.xcworkspace" -not -path "*/xcuserdata/*" -not -path "*/.build/*" | head -1)
PROJECT=$(find "$PROJECT_ROOT" -name "*.xcodeproj" -not -path "*/xcuserdata/*" -not -path "*/.build/*" | head -1)

if [ -z "$WORKSPACE" ] && [ -z "$PROJECT" ]; then
    log_error "No Xcode project or workspace found"
    exit 1
fi

# Use workspace if available, otherwise project
if [ -n "$WORKSPACE" ]; then
    BUILD_TARGET="-workspace $WORKSPACE"
else
    BUILD_TARGET="-project $PROJECT"
fi

# Get scheme name (simplified - in reality we'd parse or config this)
SCHEME=$(xcodebuild -list $BUILD_TARGET 2>/dev/null | awk '/Schemes:/{getline; print $1}')

if [ -z "$SCHEME" ]; then
    log_error "Could not determine Xcode scheme"
    exit 1
fi

# Build the app
BUILD_DIR="$CHRONO_DIR/.build"
xcodebuild $BUILD_TARGET -scheme "$SCHEME" -configuration Debug -derivedDataPath "$BUILD_DIR" build > /dev/null 2>&1

if [ $? -ne 0 ]; then
    log_error "Build failed"
    exit 1
fi

# Find the built app
APP_PATH=$(find "$BUILD_DIR" -name "*.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    log_error "Could not find built app"
    exit 1
fi

# Launch app and capture screenshots
"$CHRONO_DIR/Scripts/screenshot.swift" "$APP_PATH"

# Clean up build artifacts
rm -rf "$BUILD_DIR"
EOF

chmod +x "$CHRONO_DIR/Scripts/capture.sh"

echo "✅ ChronoTracker installed successfully!"
echo "📸 Screenshots will be captured ~15 seconds after each commit"
echo "📁 Check the ChronoTracker folder for your UI history"