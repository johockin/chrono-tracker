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

---

## 🧱 ROADMAP & PIPELINE

**NOW**
- [x] Define core workflow and integration (Git post-commit hook, CLI entry point)
- [x] Implement basic screenshot function for running macOS app (SwiftUI demo project)
- [x] Save screenshots to dated folders, with view name & timestamp
- [x] Build minimum config system (SwiftUI app in folder)
- [x] Manual run: test from CLI, capture main window

**NEXT (Phase 2 - Historical Import)**
- [ ] Historical Git Import Scanner - MVP
  - [ ] Basic script to iterate through git history
  - [ ] Filter commits touching UI files (.swift/.xib/.storyboard)
  - [ ] Skip commits <1hr apart (avoid duplicates)
  - [ ] Build each commit and capture screenshots
  - [ ] Progress output with commit messages
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

**FUTURE**
- [ ] Support for AppKit, hybrid apps
- [ ] Cross-platform hooks (Windows, Linux?)
- [ ] Advanced browsing app for viewing time series (“replay”)
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

**File Structure:**
```
ProjectRoot/
└── ChronoTracker/
    ├── 2025-07-28_14-32-15_Main-Window.png
    ├── 2025-07-28_14-32-15_Settings.png
    ├── ChronoTracker Config.app
    ├── Scripts/
    │   ├── install.sh
    │   ├── capture.sh
    │   └── screenshot.swift
    ├── Config/
    │   └── [Config app source]
    ├── Resources/
    ├── config.json
    ├── ❗️ERRORS.txt (when errors exist)
    ├── .disabled (when disabled)
    ├── .commit_count (internal)
    └── .last_error_open (internal)
```

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
