# CHRONO TRACKER – PROJECT_SPEC.md

**This is the living spec and source of truth for the Chrono Tracker project.**

## 🔰 PROJECT OVERVIEW

Chrono Tracker is a lightweight, plug-and-play screenshot tracking library for macOS desktop apps (primarily Xcode/SwiftUI projects), designed for solo devs and small teams. It automatically captures interface screenshots of key app views on every local Git commit, archiving the evolution of your UI over time. Screenshots are saved locally, time-stamped, and browsable in your file manager.

- **Target audience:** Solo developers, indie app creators, students, small product teams
- **Main value:** Effortless UI history. Visual changelog. Personal record. Instant feedback loop on interface changes.
- **Philosophy:** Hands-off by default, with full user control and clear config. No cloud or analytics. Privacy-first.
- **Distribution:** Intended to be easy to install in any project and open source, potentially via CocoaPods, Swift Package Manager, or just a script/folder drop-in.

---

## 🧭 LEVEL SET SUMMARY

- **Project name:** Chrono Tracker
- **Purpose:** Automatically capture UI state and design progress over time. Visual “black box” for app UIs.
- **Audience/users:** Indie devs, small teams, code educators, anyone who values UI/process documentation.
- **Performance priority:** High (must not slow down dev workflow or app launch).
- **Design/UX priority:** Simple, invisible, “just works.” Minimal config; browseable output folder.
- **QA workflow:** User-driven. Testing via simulated commits, different UI states, and manual review of screenshot output.
- **Deployment targets:** macOS, Xcode projects (SwiftUI, AppKit). Potential future: other platforms.
- **Tech constraints/requests:** No third-party cloud, no telemetry, local-only. CLI and optional GUI for config.
- **Other notes:** Must allow user to tune frequency (e.g. every commit, every X commits), select which screens to track, and disable at any time.

---

## 🏗️ INITIAL TECH ARCHITECTURE

- **Language:** Swift
- **App types supported:** SwiftUI, AppKit; possibly Objective-C/Cocoa
- **Trigger mechanism:** Git pre-commit hook or local script. Future: other VCS?
- **Screenshot capture:** Uses built-in macOS screenshot APIs, ideally running “headless” (no UI pop-up), capturing specific app scenes/views.
- **Config:** `chrono-tracker.json` or similar in project root. Tiny companion GUI app for setup/tweaks.
- **Output structure:** `/ChronoTracker/Screenshots/YYYY-MM-DD_HHMMSS_viewName.png`
- **Optional UI:** Small menu bar app for status/config, or a simple dialog launched on demand.

---

## 📒 CHANGELOG

- **2025-07-xx**: Project spec initiated, first ideas and roadmap by Johnny Hockin.
- **2025-07-28**: Initial implementation complete with:
  - Git post-commit hook integration (non-blocking)
  - Headless app build & launch using Xcode CLI
  - ScreenCaptureKit for modern screenshot capture
  - Self-contained ChronoTracker folder structure
  - Config app built with SwiftUI (lives in folder)
  - Smart error handling with auto-open option
  - Capture frequency control (every/alternate/3rd commit)
  - View exclusion via config
  - Historical Git Import Scanner (MVP) - retroactive screenshot generation
  - Git repository initialized: https://github.com/johockin/chrono-tracker.git
  - Architecture review by code-architect agent with recommendations
  - Production hardening complete:
    - Robust build detection with JSON parsing + fallback
    - Graceful fallback for failed builds (try /Applications, DerivedData)
    - Smart window filtering (skip system/debug/tiny windows)
    - Capture retry logic with exponential backoff
    - Self-extracting installer that downloads and self-destructs
  - Self-Extracting Installer System:
    - Single-file installer downloads latest from GitHub
    - Smart git initialization (interactive + piped modes)
    - Backup/restore screenshots during updates
    - Auto-destruct after installation
    - Handles both git and non-git project directories
    - Comprehensive README with pre-alpha warnings

---

## 🧱 ROADMAP & PIPELINE

**NOW**
- [x] Define core workflow and integration (Git post-commit hook, CLI entry point)
- [x] Implement basic screenshot function for running macOS app (SwiftUI demo project)
- [x] Save screenshots to dated folders, with view name & timestamp
- [x] Build minimum config system (SwiftUI app in folder)
- [x] Manual run: test from CLI, capture main window

**NEXT (Phase 2 - Historical Import)**
- [x] Historical Git Import Scanner - MVP
  - [x] Basic script to iterate through git history
  - [x] Filter commits touching UI files (.swift/.xib/.storyboard)
  - [x] Skip commits <1hr apart (avoid duplicates)
  - [x] Build each commit and capture screenshots
  - [x] Progress output with commit messages
- [ ] Auto-discover available views/scenes in SwiftUI (if possible)

**LATER (Phase 2 - Full Historical Import)**
- [ ] Import Dialog with smart sampling
  - [ ] Scan and count relevant commits
  - [ ] Calculate estimated screenshots and size
  - [ ] Resolution options (Original/1024px/512px)
  - [ ] Date range and branch selection
  - [ ] Max one screenshot per day default
- [ ] Background processing with cancellation
- [ ] Handle build failures gracefully
- [ ] Stash/restore working directory

**NEXT (Phase 3 - Architecture Improvements)**
- [x] Robust build detection with JSON parsing
- [x] Graceful fallback for failed builds
- [x] Smart window filtering (skip system/debug windows) 
- [x] Capture retry logic for reliability
- [x] Self-extracting installer pattern

**FUTURE**
- [ ] Support for AppKit, hybrid apps
- [ ] Cross-platform hooks (Windows, Linux?)
- [ ] Advanced browsing app for viewing time series ("replay")
- [ ] GitHub Action or CI/CD support
- [ ] Export as movie/timelapse

**SOMEDAY**
- [ ] Extensions for Figma/Sketch
- [ ] Optional integration with cloud storage (behind user toggle)
- [ ] iOS support (remote sim screenshots?)

---

## 📌 MILESTONE COMMITS

- **M1:** Core library scaffolding, working CLI
- **M2:** Screenshots taken on commit, saved and timestamped
- **M3:** Basic config works, per-view settings
- **M4:** GUI config utility
- **M5:** Open-source release candidate

---

## 📌 OPEN QUESTIONS

- Can SwiftUI reliably enumerate top-level scenes/views for screenshot automation? *Still investigating*
- ~~How to capture screenshots headlessly, without UI flicker or focus loss?~~ **SOLVED: ScreenCaptureKit + NSWorkspace config**
- Any existing tools/libraries doing 80% of this (to avoid reinventing the wheel)?
- How can we test screenshot accuracy across devices and app states?
- ~~Would menu bar utility add too much weight? Can it be purely CLI?~~ **SOLVED: Standalone app in folder**

## 🔧 IMPLEMENTATION DETAILS

**Architecture Decisions:**
- Post-commit hook (not pre-commit) for non-blocking operation
- 15-second delay to let developer continue working
- ScreenCaptureKit for macOS 12.3+ (modern, reliable screenshots)
- Config app lives in ChronoTracker folder (no system installation)
- Error log with smart auto-open (respects 5-min cooldown)
- JSON config for simplicity and Swift compatibility
- Self-extracting installer pattern (single file, downloads from GitHub, auto-destructs)
- Smart installation flow with git repository handling

**Architecture Review Findings (2025-07-28):**
- ✅ Core architecture validated as "remarkably sound" by code-architect
- ✅ SwiftUI config preferred over HTML (avoids browser security, CORS issues)
- ✅ Direct git hook execution preferred over LaunchAgents (simpler, debuggable)
- ✅ ScreenCaptureKit approach confirmed as modern best practice
- 🔄 Recommended improvements identified:
  - Robust build detection with JSON parsing (`xcodebuild -list -json`)
  - Graceful fallback for failed builds (try existing .app in /Applications)
  - Smart window filtering (skip system/debug windows)
  - Capture retry logic for reliability
  - Self-extracting installer pattern

**Key Learnings:**
- "Invisible magic" philosophy validated - install once, forget it exists
- No cloud dependencies eliminates 50% of potential issues
- No system daemons eliminates 30% of install problems
- No code signing requirements eliminates distribution friction
- Historical import creates immediate "wow" moment for users
- Self-extracting installer solves distribution complexity (no ZIP files, no manual steps)
- Git initialization handling is critical for novice developers
- Interactive vs piped installation modes require different UX approaches
- Screenshot backup/restore during updates prevents user data loss

**File Structure (Current):**
```
ProjectRoot/
├── ChronoTracker-Installer.sh (self-extracting installer, auto-destructs)
├── ChronoTracker-Installer-Fixed.sh (installer variant)
└── ChronoTracker/
    ├── 2025-07-28_14-32-15_Main-Window.png
    ├── 2025-07-28_14-32-15_[H]_Settings.png (historical)
    ├── ChronoTracker Config.app (built from source)
    ├── Scripts/
    │   ├── install.sh (sets up git hooks, handles git initialization)
    │   ├── capture.sh (auto-generated by install.sh)
    │   ├── screenshot.swift (core capture logic)
    │   └── historical-import.sh (retroactive screenshots)
    ├── Config/
    │   ├── Package.swift
    │   ├── ChronoTracker Config/App.swift
    │   └── build.sh (builds the config app)
    ├── Resources/
    ├── README.md (user documentation with pre-alpha warnings)
    ├── config.json (user settings)
    ├── ❗️ERRORS.txt (when errors exist, auto-opens if configured)
    ├── .disabled (when disabled via config)
    ├── .commit_count (internal frequency tracking)
    └── .last_error_open (internal cooldown tracking)
```

**Installation Flow:**
1. User runs `curl -sSL https://github.com/johockin/chrono-tracker/raw/main/ChronoTracker-Installer.sh | bash`
2. Installer checks for git repository (auto-initializes if needed)
3. Downloads latest ChronoTracker from GitHub
4. Backs up existing screenshots if upgrading
5. Installs/updates ChronoTracker folder
6. Runs inner install.sh for git hook setup
7. Restores backed-up screenshots
8. Auto-destructs installer file

---

## 🤖 AI COLLABORATOR INSTRUCTIONS

- Reference this file before starting any new work.
- Prompt user for missing info: e.g. preferred config file format, exact UI states to capture, frequency, exclusions.
- Document every feature addition, change, or roadblock here.
- All new ideas, features, or gotchas should be discussed and documented.
- Always propose tradeoffs if uncertain (e.g. screenshot method, UI config).
- No third-party dependencies without explicit user approval.
- Keep roadmap and changelog up to date after every meaningful step.

---

## 📁 FILES TO CREATE

- `/ChronoTracker/` folder in project root
  - `/Screenshots/` (organized by date)
  - `/config.json` or `/config.yaml`
  - `/README.md` (setup, usage, customization)
  - `/bin/` (CLI helper scripts)
- `.gitignore` update (optionally ignore screenshots or not, user’s choice)

---

## EXTRAS

- **Antialiasing:** Ensure screenshots use best-available settings for text legibility unless user opts out for “true to device” rendering.
- **Combinable:** Should play well with other local git hooks.
- **Manual override:** Allow user to take extra screenshot(s) from CLI if needed.
- **Solo dev “hygiene”:** All config and output stays local and clear.

---

This spec file is **the law**. All collaborators (human or AI) must treat it as gospel.
