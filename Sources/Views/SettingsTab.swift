import SwiftUI
import UniformTypeIdentifiers

/// Settings tab for app preferences.
///
/// Provides:
/// - Polling interval slider
/// - Menu bar graph style
/// - Export functionality
/// - About section
struct SettingsTab: View {
    @ObservedObject var sensorMonitor: SensorMonitor
    @ObservedObject var preferences = UserPreferences.shared
    @State private var showExportSuccess = false
    @State private var isExporting = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Polling interval
                settingsSection(title: "Polling") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Check metrics every:")
                            .font(.system(.caption, design: .default))
                        
                        HStack {
                            Slider(
                                value: $preferences.pollingInterval,
                                in: 1...5,
                                step: 1
                            )
                            .onChange(of: preferences.pollingInterval) { _, newValue in
                                sensorMonitor.pollingInterval = newValue
                            }
                            
                            Text("\(Int(preferences.pollingInterval))s")
                                .font(.system(.caption, design: .monospaced))
                                .frame(width: 30)
                        }
                        
                        Text("Lower = more responsive, higher = less battery drain")
                            .font(.system(.caption2, design: .default))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Menu bar graph
                settingsSection(title: "Menu Bar") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Show sparkline for:")
                            .font(.system(.caption, design: .default))
                        
                        Picker("", selection: $preferences.menuBarGraph) {
                            ForEach(MenuBarMetric.allCases, id: \.self) { metric in
                                Text(metric.displayName).tag(metric)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                // Display options
                settingsSection(title: "Display") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Show battery status", isOn: $preferences.showBattery)
                            .font(.system(.caption, design: .default))
                        
                        Toggle("Show network stats", isOn: $preferences.showNetwork)
                            .font(.system(.caption, design: .default))
                    }
                }
                
                Divider()
                
                // Export
                settingsSection(title: "Export") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Export last hour of data as CSV")
                            .font(.system(.caption, design: .default))
                            .foregroundColor(.secondary)
                        
                        Button {
                            exportCSV()
                        } label: {
                            HStack {
                                if isExporting {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                Text(isExporting ? "Exporting..." : "Export CSV")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(isExporting)
                    }
                }
                
                Divider()
                
                // About
                settingsSection(title: "About") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Foundry Pulse")
                                .font(.system(.callout, design: .default))
                                .fontWeight(.semibold)
                            Spacer()
                            Text("v1.0")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Real-time hardware monitoring for Apple Silicon Macs.")
                            .font(.system(.caption, design: .default))
                            .foregroundColor(.secondary)
                        
                        Text("Made with ⚒️ in San Francisco")
                            .font(.system(.caption2, design: .default))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                
                // Reset button
                Button("Reset to Defaults") {
                    preferences.resetToDefaults()
                    sensorMonitor.pollingInterval = preferences.pollingInterval
                    forgeLog("Preferences forged.")
                }
                .buttonStyle(.bordered)
                .foregroundColor(.secondary)
                .padding(.top, 8)
                
                Spacer()
            }
        }
        .alert("Vitals exported.", isPresented: $showExportSuccess) {
            Button("OK", role: .cancel) {}
        }
    }
    
    // MARK: - Settings Section
    
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.caption, design: .default))
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            content()
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
        }
    }
    
    // MARK: - Export
    
    private func exportCSV() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Generate CSV data
            let history = sensorMonitor.history
            var csvData = "timestamp,cpu_percent,gpu_percent,ram_mb,disk_percent,network_up_mbps,network_down_mbps\n"
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            for reading in history {
                let line = "\(dateFormatter.string(from: reading.timestamp)),\(Int(reading.cpuPercent)),\(Int(reading.gpuPercent)),\(reading.memoryUsedMB),\(Int(reading.diskUsedPercent)),\(String(format: "%.1f", reading.networkUpMbps)),\(String(format: "%.1f", reading.networkDownMbps))\n"
                csvData += line
            }
            
            // Save to Downloads folder
            let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            let exportDir = downloadsURL?.appendingPathComponent("FoundryPulse-exports")
            
            do {
                // Create export directory if needed
                if let exportDir = exportDir {
                    try FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)
                    
                    // Generate filename with timestamp
                    let timestampFormatter = DateFormatter()
                    timestampFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
                    let filename = "vitals_\(timestampFormatter.string(from: Date())).csv"
                    let fileURL = exportDir.appendingPathComponent(filename)
                    
                    // Write file
                    try csvData.write(to: fileURL, atomically: true, encoding: .utf8)
                    
                    DispatchQueue.main.async {
                        isExporting = false
                        showExportSuccess = true
                        forgeLog("Vitals exported.")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isExporting = false
                    forgeLog("Export failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsTab(sensorMonitor: SensorMonitor(pollingInterval: 2.0))
        .frame(width: 300, height: 500)
}
