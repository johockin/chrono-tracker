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
            
            // Capture each window
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = dateFormatter.string(from: Date())
            
            for (index, window) in windows.enumerated() {
                await captureWindow(window, timestamp: timestamp, index: index)
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
            return content.windows.filter { window in
                window.owningApplication?.processID == pid && 
                window.isOnScreen &&
                window.frame.width > 100 && window.frame.height > 100  // Skip tiny windows
            }
        } catch {
            logError("Failed to get windows: \(error)")
            return []
        }
    }
    
    @available(macOS 12.3, *)
    func captureWindow(_ window: SCWindow, timestamp: String, index: Int) async {
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
            
            // Convert to PNG and save
            if let tiffData = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                
                try pngData.write(to: URL(fileURLWithPath: outputPath))
            }
            
        } catch {
            logError("Failed to capture window '\(windowTitle)': \(error)")
        }
    }
}

// Main execution
@available(macOS 12.3, *)
@main
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

// Fallback for older macOS versions
if #available(macOS 12.3, *) {
    // Modern implementation above
} else {
    print("ChronoTracker requires macOS 12.3 or later")
    exit(1)
}