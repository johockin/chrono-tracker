#!/bin/bash

# ChronoTracker Installation Script
# Installs Git hooks and LaunchAgent for automatic UI screenshot tracking

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"
CHRONO_DIR="$PROJECT_ROOT/ChronoTracker"

echo "🚀 Installing ChronoTracker..."

# Check if we're in a git repository (should be handled by outer installer)
if ! git -C "$PROJECT_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a Git repository. ChronoTracker requires Git."
    echo "   Run: git init && git add . && git commit -m 'Initial commit'"
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

# Check screen recording permission
check_permission() {
    # Test if we can access screen capture
    if ! system_profiler SPPrivacyDataType 2>/dev/null | grep -q "Screen Recording"; then
        return 1
    fi
    
    # Try a simple screen capture test (will fail gracefully if no permission)
    return 0
}

# Give the developer a moment to continue working
sleep 15

# Quick permission check
if ! check_permission; then
    log_error "Screen recording permission may be required. Enable in System Preferences > Security & Privacy > Privacy > Screen Recording"
fi

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

# Get build info using JSON for robust parsing
get_build_info() {
    local json_output
    if [ -n "$WORKSPACE" ]; then
        json_output=$(xcodebuild -list -workspace "$WORKSPACE" -json 2>/dev/null)
    else
        json_output=$(xcodebuild -list -project "$PROJECT" -json 2>/dev/null)
    fi
    
    # Extract first scheme using Python (available on all macOS)
    echo "$json_output" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'workspace' in data and 'schemes' in data['workspace']:
        schemes = data['workspace']['schemes']
    elif 'project' in data and 'schemes' in data['project']:
        schemes = data['project']['schemes']
    else:
        sys.exit(1)
    
    if schemes:
        print(schemes[0])
    else:
        sys.exit(1)
except:
    sys.exit(1)
"
}

SCHEME=$(get_build_info)

if [ -z "$SCHEME" ]; then
    log_error "Could not determine Xcode scheme using JSON parsing"
    
    # Fallback to legacy parsing
    SCHEME=$(xcodebuild -list $BUILD_TARGET 2>/dev/null | awk '/Schemes:/{getline; print $1}')
    
    if [ -z "$SCHEME" ]; then
        log_error "Could not determine Xcode scheme (fallback also failed)"
        exit 1
    fi
fi

# Try to build the app
BUILD_DIR="$CHRONO_DIR/.build"
xcodebuild $BUILD_TARGET -scheme "$SCHEME" -configuration Debug -derivedDataPath "$BUILD_DIR" build > /dev/null 2>&1

APP_PATH=""

if [ $? -eq 0 ]; then
    # Build successful, find the built app
    APP_PATH=$(find "$BUILD_DIR" -name "*.app" -type d | head -1)
    
    if [ -n "$APP_PATH" ]; then
        echo "Built app successfully: $APP_PATH"
    fi
fi

# Graceful fallback: if build failed or app not found, try existing app
if [ -z "$APP_PATH" ]; then
    log_error "Build failed or app not found, trying fallback options..."
    
    # Try to find existing app in /Applications
    APP_NAME=$(basename "$SCHEME" .xcodeproj)
    FALLBACK_PATHS=(
        "/Applications/$APP_NAME.app"
        "/Applications/$SCHEME.app"
        "$HOME/Applications/$APP_NAME.app"
        "$HOME/Applications/$SCHEME.app"
    )
    
    for path in "${FALLBACK_PATHS[@]}"; do
        if [ -d "$path" ]; then
            APP_PATH="$path"
            log_error "Using existing app: $APP_PATH"
            break
        fi
    done
    
    # Last resort: try to find any .app in DerivedData
    if [ -z "$APP_PATH" ]; then
        DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"
        APP_PATH=$(find "$DERIVED_DATA_PATH" -name "*$SCHEME*.app" -type d 2>/dev/null | head -1)
        
        if [ -n "$APP_PATH" ]; then
            log_error "Using DerivedData app: $APP_PATH"
        fi
    fi
fi

if [ -z "$APP_PATH" ]; then
    log_error "Could not find any usable app (build failed and no fallback found)"
    exit 1
fi

# Launch app and capture screenshots
"$CHRONO_DIR/Scripts/screenshot.swift" "$APP_PATH"

# Clean up build artifacts
rm -rf "$BUILD_DIR"
EOF

chmod +x "$CHRONO_DIR/Scripts/capture.sh"

echo "✅ ChronoTracker installed successfully!"
echo ""
echo "🔐 IMPORTANT: Screen Recording Permission Required"
echo ""
echo "When you make your first commit, macOS will ask for permission:"
echo "  \"Terminal would like to record this computer's screen\""
echo ""
echo "Click 'Open System Preferences' and enable Screen Recording for your terminal."
echo "This is required to capture app screenshots."
echo ""
echo "📸 Screenshots will be captured ~15 seconds after each commit"
echo "📁 Check the ChronoTracker folder for your UI history"
echo ""
echo "🎯 Quick test: Make a commit and wait ~15 seconds!"
echo "   git add . && git commit -m \"Test ChronoTracker\""