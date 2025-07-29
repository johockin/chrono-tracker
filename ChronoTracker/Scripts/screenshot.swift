#!/usr/bin/swift

// ChronoTracker Screenshot Capture
// Launches app headlessly and captures all windows

import Foundation
import AppKit
import ScreenCaptureKit

@available(macOS 12.3, *)
class ScreenshotCapture {
    let appPath: String
    var outputDir: String
    let errorLog: String
    let configPath: String
    var excludedViews: Set<String> = []
    
    init(appPath: String) {
        self.appPath = appPath
        let chronoDir = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent().path
        self.outputDir = chronoDir
        self.errorLog = "\(chronoDir)/❗️ERRORS.txt"
        self.configPath = "\(chronoDir)/config.json"
        
        loadConfig()
    }
    
    struct Config: Codable {
        let excludedViews: [String]
    }
    
    func loadConfig() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
              let config = try? JSONDecoder().decode(Config.self, from: data) else {
            return
        }
        excludedViews = Set(config.excludedViews)
    }
    
    func logError(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        let errorMessage = "[\(timestamp)] \(message)\n"
        
        if let data = errorMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: errorLog) {
                if let fileHandle = FileHandle(forWritingAtPath: errorLog) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: URL(fileURLWithPath: errorLog))
            }
        }
    }
    
    func capture() async {
        // Launch the app
        let appURL = URL(fileURLWithPath: appPath)
        let config = NSWorkspace.OpenConfiguration()
        config.activates = false
        config.hides = true
        config.addsToRecentItems = false
        
        do {
            let app = try await NSWorkspace.shared.openApplication(at: appURL, configuration: config)
            
            // Give app time to fully launch and render
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            // Get all windows for this app
            let windows = await getWindows(for: app.processIdentifier)
            
            if windows.isEmpty {
                logError("No windows found for app")
                app.terminate()
                return
            }
            
            // Capture each window with retry logic
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = dateFormatter.string(from: Date())
            
            for (index, window) in windows.enumerated() {
                await captureWindowWithRetry(window, timestamp: timestamp, index: index)
            }
            
            // Terminate the app
            app.terminate()
            
        } catch {
            logError("Failed to launch app: \(error)")
        }
    }
    
    @available(macOS 12.3, *)
    func getWindows(for pid: pid_t) async -> [SCWindow] {
        do {
            let content = try await SCShareableContent.current
            let allAppWindows = content.windows.filter { window in
                window.owningApplication?.processID == pid
            }
            
            print("DEBUG: Found \(allAppWindows.count) total windows for PID \(pid)")
            for (i, window) in allAppWindows.enumerated() {
                print("  Window \(i): '\(window.title ?? "no title")' size=\(Int(window.frame.width))x\(Int(window.frame.height)) onScreen=\(window.isOnScreen)")
            }
            
            let filteredWindows = allAppWindows.filter { window in
                window.isOnScreen &&
                window.frame.width > 50 && window.frame.height > 50 &&  // Less restrictive size
                isAppWindow(window)  // Smart filtering
            }
            
            print("DEBUG: After filtering: \(filteredWindows.count) windows")
            return filteredWindows
        } catch {
            logError("Failed to get windows: \(error)")
            return []
        }
    }
    
    // Smart window filtering to exclude system/debug windows
    func isAppWindow(_ window: SCWindow) -> Bool {
        // Accept windows without titles for now (some valid app windows don't have titles)
        let title = window.title ?? ""
        
        // Skip Xcode debugger, system dialogs, and development tools
        let systemPrefixes = [
            "Debugger", "Console", "Memory Graph", "Simulator", "Preview",
            "Interface Builder", "Storyboard", "SwiftUI Preview",
            "Accessibility Inspector", "Instruments", "Activity Monitor",
            "Terminal", "Xcode", "CoreSimulator", "iOS Simulator"
        ]
        
        let systemSuffixes = [
            "Debugger", "Console", "Inspector", "Simulator"
        ]
        
        // Check prefixes
        for prefix in systemPrefixes {
            if title.hasPrefix(prefix) {
                return false
            }
        }
        
        // Check suffixes
        for suffix in systemSuffixes {
            if title.hasSuffix(suffix) {
                return false
            }
        }
        
        // Skip windows that are clearly system dialogs
        let systemKeywords = ["Alert", "Dialog", "Popup", "Menu"]
        for keyword in systemKeywords {
            if title.contains(keyword) && title.count < 50 {  // Short titles are usually system dialogs
                return false
            }
        }
        
        // Skip windows that are too small to be main app windows
        if window.frame.width < 200 || window.frame.height < 150 {
            return false
        }
        
        return true
    }
    
    // Capture window with retry logic for reliability
    @available(macOS 12.3, *)
    func captureWindowWithRetry(_ window: SCWindow, timestamp: String, index: Int, maxAttempts: Int = 3) async {
        for attempt in 1...maxAttempts {
            do {
                try await captureWindow(window, timestamp: timestamp, index: index)
                return // Success, exit retry loop
            } catch {
                if attempt == maxAttempts {
                    let windowTitle = window.title?.replacingOccurrences(of: "/", with: "-")
                        .replacingOccurrences(of: ":", with: "-")
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? "window"
                    logError("Failed to capture '\(windowTitle)' after \(maxAttempts) attempts: \(error)")
                } else {
                    // Wait before retry (exponential backoff)
                    let delay = TimeInterval(attempt) * 0.5 // 0.5s, 1s, 1.5s...
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
    }
    
    @available(macOS 12.3, *)
    func captureWindow(_ window: SCWindow, timestamp: String, index: Int) async throws {
        // Clean window title for filename
        let windowTitle = window.title?.replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "window"
        
        // Check if this view is excluded
        if excludedViews.contains(windowTitle) {
            return
        }
        
        let filename = "\(timestamp)_\(windowTitle).png"
        let outputPath = "\(outputDir)/\(filename)"
        
        // Configure capture
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let config = SCStreamConfiguration()
        config.width = Int(window.frame.width) * 2  // Retina resolution
        config.height = Int(window.frame.height) * 2
        config.scalesToFit = true
        config.showsCursor = false
        config.capturesAudio = false
        
        do {
            // Create screenshot
            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            
            // Convert CGImage to NSImage first, then to PNG
            let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
            if let tiffData = nsImage.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                
                try pngData.write(to: URL(fileURLWithPath: outputPath))
            }
            
        } catch {
            // Re-throw error for retry logic to handle
            throw error
        }
    }
}

// Main execution
@available(macOS 12.3, *)
struct ChronoTrackerScreenshot {
    static func main() async {
        let args = CommandLine.arguments
        
        guard args.count > 1 else {
            print("Usage: screenshot.swift <app-path> [output-dir]")
            exit(1)
        }
        
        var capture = ScreenshotCapture(appPath: args[1])
        
        // Override output directory if provided
        if args.count > 2 {
            capture.outputDir = args[2]
        }
        
        await capture.capture()
    }
}

// Execute main function
if #available(macOS 12.3, *) {
    await ChronoTrackerScreenshot.main()
} else {
    print("ChronoTracker requires macOS 12.3 or later")
    exit(1)
}