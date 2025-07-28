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
echo "   Installing to: $PROJECT_ROOT"
echo ""

# Check if we're in a git repository FIRST (before any folder operations)
if ! git rev-parse --git-dir > /dev/null 2>&1; then
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
            git init
            
            echo "📁 Adding project files..."
            git add .
            
            echo "📝 Creating initial commit..."
            git commit -m "Initial commit - before ChronoTracker installation"
            
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
        # Piped installation - auto-initialize
        echo "🔧 Auto-initializing git repository for piped installation..."
        echo ""
        
        if git init && git add . && git commit -m "Initial commit - before ChronoTracker installation"; then
            echo "✅ Git repository initialized!"
            echo ""
        else
            echo "❌ Failed to initialize git repository"
            echo ""
            echo "🔧 Run these commands manually, then try the installer again:"
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

echo "🔧 Setting up Git hooks..."

# Run the install script
if "$PROJECT_ROOT/ChronoTracker/Scripts/install.sh"; then
    echo ""
    
    # Restore backed up screenshots if they exist
    if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
        echo "📸 Restoring your screenshots..."
        
        if ls "$BACKUP_DIR"/*.png > /dev/null 2>&1; then
            cp "$BACKUP_DIR"/*.png "$PROJECT_ROOT/ChronoTracker/" 2>/dev/null || true
            RESTORED_COUNT=$(ls "$BACKUP_DIR"/*.png 2>/dev/null | wc -l)
            echo "  ✅ Restored $RESTORED_COUNT screenshots"
        fi
        
        if [ -f "$BACKUP_DIR/config.json" ]; then
            cp "$BACKUP_DIR/config.json" "$PROJECT_ROOT/ChronoTracker/" 2>/dev/null || true
            echo "  ✅ Restored config.json"
        fi
        
        # Clean up backup directory
        rm -rf "$BACKUP_DIR"
        echo "🧹 Cleaned up temporary backup"
        echo ""
    fi
    
    echo "✅ ChronoTracker installed successfully!"
    echo ""
    echo "📖 What's next:"
    echo "   • Screenshots will be captured ~15 seconds after each commit"
    echo "   • Check ChronoTracker/ folder for your UI history"
    echo "   • Build config app: cd ChronoTracker/Config && ./build.sh"
    echo "   • Import history: ./ChronoTracker/Scripts/historical-import.sh"
    echo ""
    echo "📚 Documentation: $PROJECT_ROOT/ChronoTracker/README.md"
else
    echo "❌ Installation failed. Check the error messages above."
    exit 1
fi

echo "🧹 Cleaning up installer..."

# Self-destruct: remove the installer
rm -f "$INSTALLER_PATH"

echo "✨ Installation complete. Installer removed."
echo "   Happy coding! Your UI evolution is now being tracked."