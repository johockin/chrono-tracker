#!/bin/bash

# ChronoTracker Self-Extracting Installer
# Downloads and installs ChronoTracker in the current project directory
# GitHub sync fix: 2025-07-28

set -e

INSTALLER_PATH="$0"
PROJECT_ROOT="$(pwd)"
REPO_URL="https://github.com/johockin/chrono-tracker.git"
TEMP_DIR="/tmp/chrono-tracker-install-$$"

echo "🚀 ChronoTracker Self-Extracting Installer"
echo "   Version: 0.1.04"
echo "   Installing to: $PROJECT_ROOT"
echo ""

# Check Xcode configuration first
echo "🔧 Checking Xcode configuration..."

current_xcode=$(xcode-select -p 2>/dev/null || echo "not-found")
if [[ "$current_xcode" == *"CommandLineTools"* ]] && [ -d "/Applications/Xcode.app" ]; then
    echo "⚠️  Switching from Command Line Tools to full Xcode..."
    echo "   (You may be prompted for your password)"
    if sudo xcode-select -s /Applications/Xcode.app/Contents/Developer; then
        echo "✅ Xcode configured successfully"
    else
        echo "❌ Failed to configure Xcode. Please run:"
        echo "   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
        exit 1
    fi
elif [ ! -d "/Applications/Xcode.app" ]; then
    echo "❌ ChronoTracker requires full Xcode installation"
    echo "   Please install Xcode from the App Store and run installer again"
    echo ""
    echo "   Note: Command Line Tools alone are not sufficient."
    echo "   ChronoTracker needs Xcode to build and capture your app."
    exit 1
else
    echo "✅ Xcode properly configured"
fi

echo ""

# Check if we're in a git repository FIRST (before any folder operations)
if ! git -C "$PROJECT_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ ChronoTracker requires a Git repository to work"
    echo ""
    echo "💡 Why? ChronoTracker captures screenshots on git commits."
    echo "   You don't need GitHub/remote - local git repo is fine!"
    echo ""
    
    # Check if we're in a pipe (can't read user input)
    if [ -t 0 ]; then
        # Interactive terminal - can ask user
        echo "🔧 Would you like me to initialize git for you? (y/n)"
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo "📦 Initializing git repository..."
            git -C "$PROJECT_ROOT" init
            
            echo "📁 Adding project files..."
            git -C "$PROJECT_ROOT" add .
            
            echo "📝 Creating initial commit..."
            git -C "$PROJECT_ROOT" commit -m "Initial commit - before ChronoTracker installation"
            
            echo "✅ Git repository initialized!"
            echo ""
        else
            echo ""
            echo "🔧 Run these commands manually, then try the installer again:"
            echo "   git init"
            echo "   git add ."
            echo "   git commit -m \"Initial commit\""
            exit 1
        fi
    else
        # Piped installation - be more explicit about what we're doing
        echo "🔧 No git repository found. ChronoTracker needs git to work."
        echo ""
        echo "📦 Initializing git repository automatically..."
        echo "   (To avoid this, run 'git init' before installing)"
        echo ""
        
        if git -C "$PROJECT_ROOT" init; then
            echo "✅ Git repository created"
            
            echo "📁 Adding your project files..."
            git -C "$PROJECT_ROOT" add .
            
            echo "📝 Creating initial commit..."
            git -C "$PROJECT_ROOT" commit -m "Initial commit - before ChronoTracker installation" || true
            
            echo "✅ Git repository initialized successfully!"
            echo ""
        else
            echo "❌ Failed to initialize git repository"
            echo ""
            echo "🔧 Please run these commands manually, then try again:"
            echo "   git init"
            echo "   git add ."
            echo "   git commit -m \"Initial commit\""
            exit 1
        fi
    fi
fi

# Check if ChronoTracker already exists
if [ -d "$PROJECT_ROOT/ChronoTracker" ]; then
    echo "⚠️  ChronoTracker folder already exists"
    
    # Check version if exists
    if [ -f "$PROJECT_ROOT/ChronoTracker/.version" ]; then
        INSTALLED_VERSION=$(cat "$PROJECT_ROOT/ChronoTracker/.version")
        echo "   Current version: $INSTALLED_VERSION"
    fi
    
    echo ""
    echo "📸 Backing up existing screenshots..."
    
    # Create backup directory
    BACKUP_DIR="$PROJECT_ROOT/ChronoTracker_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup screenshots and config
    if ls "$PROJECT_ROOT/ChronoTracker"/*.png > /dev/null 2>&1; then
        cp "$PROJECT_ROOT/ChronoTracker"/*.png "$BACKUP_DIR/" 2>/dev/null || true
        SCREENSHOT_COUNT=$(ls "$PROJECT_ROOT/ChronoTracker"/*.png 2>/dev/null | wc -l)
        echo "  📁 Backed up $SCREENSHOT_COUNT screenshots to $BACKUP_DIR"
    fi
    
    if [ -f "$PROJECT_ROOT/ChronoTracker/config.json" ]; then
        cp "$PROJECT_ROOT/ChronoTracker/config.json" "$BACKUP_DIR/" 2>/dev/null || true
        echo "  ⚙️  Backed up config.json"
    fi
    
    echo "🗑️  Removing old installation..."
    rm -rf "$PROJECT_ROOT/ChronoTracker"
    echo "✅ Old installation removed (screenshots safely backed up)"
    echo ""
fi

echo "📥 Downloading ChronoTracker..."

# Create temp directory
mkdir -p "$TEMP_DIR"
trap "rm -rf $TEMP_DIR" EXIT

# Clone the repository
if ! git clone --depth 1 "$REPO_URL" "$TEMP_DIR/chrono-tracker" > /dev/null 2>&1; then
    echo "❌ Failed to download ChronoTracker from GitHub"
    echo "   Check your internet connection or clone manually:"
    echo "   git clone $REPO_URL"
    exit 1
fi

echo "📁 Installing ChronoTracker folder..."

# Copy ChronoTracker folder to project root
cp -r "$TEMP_DIR/chrono-tracker/ChronoTracker" "$PROJECT_ROOT/"

# Make scripts executable
chmod +x "$PROJECT_ROOT/ChronoTracker/Scripts"/*.sh
chmod +x "$PROJECT_ROOT/ChronoTracker/Scripts"/*.swift

echo "🚀 Installing ChronoTracker..."

# Run the install script (it will output "Configuring Git hooks...")
if "$PROJECT_ROOT/ChronoTracker/Scripts/install.sh" > /dev/null 2>&1; then
    echo "✅ Core files installed"
    
    # Restore backed up screenshots if they exist
    if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
        if ls "$BACKUP_DIR"/*.png > /dev/null 2>&1; then
            cp "$BACKUP_DIR"/*.png "$PROJECT_ROOT/ChronoTracker/" 2>/dev/null || true
            RESTORED_COUNT=$(ls "$BACKUP_DIR"/*.png 2>/dev/null | wc -l)
            echo "📸 Screenshots restored ($RESTORED_COUNT files)"
        fi
        
        if [ -f "$BACKUP_DIR/config.json" ]; then
            cp "$BACKUP_DIR/config.json" "$PROJECT_ROOT/ChronoTracker/" 2>/dev/null || true
        fi
        
        # Clean up backup directory
        rm -rf "$BACKUP_DIR"
    fi
    
    echo "🔧 Git hooks configured"
    echo ""
    echo "✅ ChronoTracker 0.1.04 installed successfully!"
    echo ""
    echo "🔐 IMPORTANT: Screen Recording Permission Required"
    echo "   When you make your first commit, macOS will prompt for permission."
    echo "   Click 'Allow' to enable screenshot capture."
    echo ""
    echo "📖 Next steps:"
    echo "   • Make a test commit: git add . && git commit -m \"Test\""
    echo "   • Screenshots appear in ChronoTracker/ folder instantly"
    echo "   • Config: cd ChronoTracker/Config && ./build.sh"
    echo "   • Import history: ./ChronoTracker/Scripts/historical-import.sh"
else
    echo "❌ Installation failed. Check the error messages above."
    exit 1
fi

echo ""
echo "✨ Installation complete. Happy coding!"

# Self-destruct: remove the installer
rm -f "$INSTALLER_PATH" 2>/dev/null