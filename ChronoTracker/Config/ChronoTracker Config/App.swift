import SwiftUI

@main
struct ChronoTrackerConfigApp: App {
    @StateObject private var configManager = ConfigurationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(configManager)
                .frame(minWidth: 500, minHeight: 400)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

class ConfigurationManager: ObservableObject {
    @Published var excludedViews: Set<String> = []
    @Published var openErrorLogOnFailure = true
    @Published var captureFrequency: CaptureFrequency = .everyCommit
    @Published var isEnabled = true
    
    private let configURL: URL
    private let disabledMarkerURL: URL
    
    init() {
        let chronoDir = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        
        configURL = chronoDir.appendingPathComponent("config.json")
        disabledMarkerURL = chronoDir.appendingPathComponent(".disabled")
        
        loadConfiguration()
        checkEnabledStatus()
    }
    
    enum CaptureFrequency: String, CaseIterable, Codable {
        case everyCommit = "every"
        case everyOther = "alternate"
        case everyThird = "third"
        
        var displayName: String {
            switch self {
            case .everyCommit: return "Every commit"
            case .everyOther: return "Every other commit"
            case .everyThird: return "Every 3rd commit"
            }
        }
    }
    
    struct Configuration: Codable {
        let excludedViews: [String]
        let openErrorLogOnFailure: Bool
        let captureFrequency: CaptureFrequency
    }
    
    func save() {
        let config = Configuration(
            excludedViews: Array(excludedViews),
            openErrorLogOnFailure: openErrorLogOnFailure,
            captureFrequency: captureFrequency
        )
        
        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: configURL)
        } catch {
            print("Failed to save configuration: \(error)")
        }
        
        // Handle enabled/disabled state
        if isEnabled {
            try? FileManager.default.removeItem(at: disabledMarkerURL)
        } else {
            FileManager.default.createFile(atPath: disabledMarkerURL.path, contents: nil)
        }
    }
    
    private func loadConfiguration() {
        guard FileManager.default.fileExists(atPath: configURL.path),
              let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(Configuration.self, from: data) else {
            return
        }
        
        excludedViews = Set(config.excludedViews)
        openErrorLogOnFailure = config.openErrorLogOnFailure
        captureFrequency = config.captureFrequency
    }
    
    private func checkEnabledStatus() {
        isEnabled = !FileManager.default.fileExists(atPath: disabledMarkerURL.path)
    }
}

struct ContentView: View {
    @EnvironmentObject var config: ConfigurationManager
    @State private var discoveredViews: [String] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading) {
                        Text("ChronoTracker Config")
                            .font(.title)
                            .fontWeight(.semibold)
                        Text("UI screenshot tracking for your commits")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("Enabled", isOn: $config.isEnabled)
                        .toggleStyle(.switch)
                        .onChange(of: config.isEnabled) { _ in
                            config.save()
                        }
                }
                .padding()
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Capture Settings
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Capture Settings", systemImage: "gearshape")
                                .font(.headline)
                            
                            Picker("Frequency", selection: $config.captureFrequency) {
                                ForEach(ConfigurationManager.CaptureFrequency.allCases, id: \.self) { freq in
                                    Text(freq.displayName).tag(freq)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 200)
                            
                            Toggle("Open error log automatically when capture fails", 
                                   isOn: $config.openErrorLogOnFailure)
                        }
                    }
                    
                    // Excluded Views
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Excluded Views", systemImage: "eye.slash")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button("Discover Views") {
                                    discoverViews()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                            
                            if discoveredViews.isEmpty {
                                Text("Click 'Discover Views' to find windows in your app")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 20)
                                    .frame(maxWidth: .infinity)
                            } else {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(discoveredViews, id: \.self) { view in
                                        HStack {
                                            Toggle(view, isOn: Binding(
                                                get: { !config.excludedViews.contains(view) },
                                                set: { included in
                                                    if included {
                                                        config.excludedViews.remove(view)
                                                    } else {
                                                        config.excludedViews.insert(view)
                                                    }
                                                }
                                            ))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Info
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Info", systemImage: "info.circle")
                                .font(.headline)
                            
                            Text("Screenshots are captured ~15 seconds after each commit")
                                .font(.caption)
                            Text("Check ❗️ERRORS.txt if screenshots aren't appearing")
                                .font(.caption)
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            HStack {
                Button("Open Screenshots Folder") {
                    openScreenshotsFolder()
                }
                
                Spacer()
                
                Button("Save") {
                    config.save()
                    NSApp.terminate(nil)
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
    }
    
    func discoverViews() {
        // For now, just add some example views
        // In a real implementation, this would scan the project
        discoveredViews = [
            "Main Window",
            "Settings",
            "Preferences",
            "About"
        ]
    }
    
    func openScreenshotsFolder() {
        let chronoDir = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        
        NSWorkspace.shared.open(chronoDir)
    }
}