#!/bin/bash

# ChronoTracker Historical Import Scanner - MVP
# Scans git history and captures screenshots from past commits

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CHRONO_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
PROJECT_ROOT="$( cd "$CHRONO_DIR/.." && pwd )"
ERROR_LOG="$CHRONO_DIR/❗️ERRORS.txt"
HISTORICAL_DIR="$CHRONO_DIR/Historical"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🕰️  ChronoTracker Historical Import Scanner${NC}"
echo ""

# Check if we're in a git repository
if ! git -C "$PROJECT_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Not in a Git repository${NC}"
    exit 1
fi

# Save current state
CURRENT_BRANCH=$(git -C "$PROJECT_ROOT" branch --show-current)
CURRENT_COMMIT=$(git -C "$PROJECT_ROOT" rev-parse HEAD)
HAS_CHANGES=$(git -C "$PROJECT_ROOT" status --porcelain)

if [ -n "$HAS_CHANGES" ]; then
    echo -e "${YELLOW}⚠️  You have uncommitted changes. Stashing them...${NC}"
    git -C "$PROJECT_ROOT" stash push -m "ChronoTracker: Auto-stash before historical import"
    STASHED=true
else
    STASHED=false
fi

# Create historical directory
mkdir -p "$HISTORICAL_DIR"

# Get commits that touched UI files
echo -e "${BLUE}📊 Analyzing git history...${NC}"
COMMITS=$(git -C "$PROJECT_ROOT" log --pretty=format:"%H|%ai|%s" --name-only --diff-filter=AM -- "*.swift" "*.xib" "*.storyboard" | \
    awk 'BEGIN{commit=""} 
         /^[a-f0-9]{40}\|/{if(commit && found){print commit} commit=$0; found=0} 
         /\.(swift|xib|storyboard)$/{found=1} 
         END{if(commit && found){print commit}}' | \
    tac)  # Reverse to process oldest first

TOTAL_COMMITS=$(echo "$COMMITS" | grep -c '^' || echo 0)

if [ "$TOTAL_COMMITS" -eq 0 ]; then
    echo -e "${YELLOW}No commits found that modified UI files${NC}"
    exit 0
fi

echo -e "${GREEN}Found $TOTAL_COMMITS commits with UI changes${NC}"
echo ""

# Filter commits (skip if within 1 hour of previous)
FILTERED_COMMITS=""
LAST_TIMESTAMP=0
SKIPPED=0

while IFS='|' read -r hash timestamp message; do
    # Convert timestamp to epoch
    COMMIT_TIMESTAMP=$(date -j -f "%Y-%m-%d %H:%M:%S %z" "$timestamp" "+%s" 2>/dev/null || date -d "$timestamp" "+%s")
    
    # Skip if within 1 hour (3600 seconds) of last commit
    if [ $LAST_TIMESTAMP -ne 0 ]; then
        DIFF=$((COMMIT_TIMESTAMP - LAST_TIMESTAMP))
        if [ $DIFF -lt 3600 ] && [ $DIFF -gt -3600 ]; then
            ((SKIPPED++))
            continue
        fi
    fi
    
    FILTERED_COMMITS="${FILTERED_COMMITS}${hash}|${timestamp}|${message}\n"
    LAST_TIMESTAMP=$COMMIT_TIMESTAMP
done <<< "$COMMITS"

FILTERED_COUNT=$(echo -e "$FILTERED_COMMITS" | grep -c '^' || echo 0)
echo -e "${GREEN}Processing $FILTERED_COUNT commits (skipped $SKIPPED within 1hr)${NC}"
echo ""

# Process each commit
COUNT=0
SUCCESS=0
FAILED=0

echo -e "$FILTERED_COMMITS" | while IFS='|' read -r hash timestamp message; do
    [ -z "$hash" ] && continue
    
    ((COUNT++))
    
    # Clean message for display (truncate if needed)
    CLEAN_MESSAGE=$(echo "$message" | cut -c1-60)
    [ ${#message} -gt 60 ] && CLEAN_MESSAGE="${CLEAN_MESSAGE}..."
    
    echo -e "${BLUE}[$COUNT/$FILTERED_COUNT]${NC} Processing: $CLEAN_MESSAGE"
    echo -e "  ${YELLOW}→${NC} Commit: ${hash:0:8} from $timestamp"
    
    # Checkout the commit
    if ! git -C "$PROJECT_ROOT" checkout -q "$hash" 2>/dev/null; then
        echo -e "  ${RED}✗${NC} Failed to checkout commit"
        ((FAILED++))
        continue
    fi
    
    # Convert timestamp to filename format
    CAPTURE_DATE=$(date -j -f "%Y-%m-%d %H:%M:%S %z" "$timestamp" "+%Y-%m-%d_%H-%M-%S" 2>/dev/null || \
                   date -d "$timestamp" "+%Y-%m-%d_%H-%M-%S")
    
    # Try to build and capture
    BUILD_DIR="$CHRONO_DIR/.historical-build"
    
    # Find project/workspace
    WORKSPACE=$(find "$PROJECT_ROOT" -name "*.xcworkspace" -not -path "*/xcuserdata/*" -not -path "*/.build/*" | head -1)
    PROJECT=$(find "$PROJECT_ROOT" -name "*.xcodeproj" -not -path "*/xcuserdata/*" -not -path "*/.build/*" | head -1)
    
    if [ -n "$WORKSPACE" ]; then
        BUILD_TARGET="-workspace $WORKSPACE"
    elif [ -n "$PROJECT" ]; then
        BUILD_TARGET="-project $PROJECT"
    else
        echo -e "  ${RED}✗${NC} No Xcode project found"
        ((FAILED++))
        continue
    fi
    
    # Get scheme
    SCHEME=$(xcodebuild -list $BUILD_TARGET 2>/dev/null | awk '/Schemes:/{getline; print $1}')
    
    if [ -z "$SCHEME" ]; then
        echo -e "  ${RED}✗${NC} Could not determine scheme"
        ((FAILED++))
        continue
    fi
    
    echo -e "  ${YELLOW}→${NC} Building $SCHEME..."
    
    # Build (suppress output)
    if xcodebuild $BUILD_TARGET -scheme "$SCHEME" -configuration Debug -derivedDataPath "$BUILD_DIR" build >/dev/null 2>&1; then
        # Find the built app
        APP_PATH=$(find "$BUILD_DIR" -name "*.app" -type d | head -1)
        
        if [ -n "$APP_PATH" ]; then
            echo -e "  ${YELLOW}→${NC} Capturing screenshots..."
            
            # Create output directory for this commit
            OUTPUT_DIR="$HISTORICAL_DIR/$CAPTURE_DATE"
            mkdir -p "$OUTPUT_DIR"
            
            # Run screenshot capture with custom output directory
            if "$CHRONO_DIR/Scripts/screenshot.swift" "$APP_PATH" "$OUTPUT_DIR" 2>/dev/null; then
                echo -e "  ${GREEN}✓${NC} Captured successfully"
                ((SUCCESS++))
            else
                echo -e "  ${RED}✗${NC} Screenshot capture failed"
                ((FAILED++))
                rmdir "$OUTPUT_DIR" 2>/dev/null || true
            fi
        else
            echo -e "  ${RED}✗${NC} Could not find built app"
            ((FAILED++))
        fi
    else
        echo -e "  ${RED}✗${NC} Build failed"
        ((FAILED++))
    fi
    
    # Clean up build
    rm -rf "$BUILD_DIR"
    
    echo ""
done

# Return to original state
echo -e "${BLUE}🔄 Returning to original state...${NC}"
git -C "$PROJECT_ROOT" checkout -q "$CURRENT_BRANCH" || git -C "$PROJECT_ROOT" checkout -q "$CURRENT_COMMIT"

if [ "$STASHED" = true ]; then
    echo -e "${YELLOW}📦 Restoring stashed changes...${NC}"
    git -C "$PROJECT_ROOT" stash pop -q
fi

# Summary
echo ""
echo -e "${GREEN}✅ Historical import complete!${NC}"
echo -e "  • Processed: $COUNT commits"
echo -e "  • Successful: ${GREEN}$SUCCESS${NC}"
echo -e "  • Failed: ${RED}$FAILED${NC}"
echo -e "  • Screenshots saved to: $HISTORICAL_DIR"
echo ""

# Organize by date if we have screenshots
if [ "$SUCCESS" -gt 0 ]; then
    echo -e "${BLUE}📁 Organizing screenshots...${NC}"
    
    # Move historical screenshots to main directory with [H] prefix
    find "$HISTORICAL_DIR" -name "*.png" -type f | while read -r file; do
        filename=$(basename "$file")
        dir_date=$(basename "$(dirname "$file")")
        
        # Add [H] prefix to indicate historical
        new_name="${dir_date}_[H]_${filename#*_}"
        mv "$file" "$CHRONO_DIR/$new_name"
    done
    
    # Clean up empty directories
    find "$HISTORICAL_DIR" -type d -empty -delete
    
    echo -e "${GREEN}✓ Screenshots organized in main ChronoTracker folder${NC}"
fi