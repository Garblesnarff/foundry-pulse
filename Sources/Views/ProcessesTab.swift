import SwiftUI

/// Processes tab showing top CPU and memory consumers.
///
/// Provides:
/// - Top 5 processes by CPU %
/// - Top 5 processes by memory
/// - Sortable table
/// - Force-quit functionality
struct ProcessesTab: View {
    @ObservedObject var sensorMonitor: SensorMonitor
    @State private var sortOrder: ProcessSortOrder = .cpu
    @State private var showForceQuitAlert = false
    @State private var selectedProcess: ProcessMonitor.ProcessInfo?
    
    private var cpuProcesses: [ProcessMonitor.ProcessInfo] {
        ProcessMonitor.topProcessesByCPU(count: 5)
    }
    
    private var memoryProcesses: [ProcessMonitor.ProcessInfo] {
        ProcessMonitor.topProcessesByMemory(count: 5)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // CPU Processes
            processSection(title: "Top CPU", processes: cpuProcesses, icon: "cpu")
            
            Divider()
            
            // Memory Processes
            processSection(title: "Top Memory", processes: memoryProcesses, icon: "memorychip")
            
            Spacer()
            
            // Info text
            Text("Data refreshes every \(Int(sensorMonitor.pollingInterval)) seconds")
                .font(.system(.caption2, design: .default))
                .foregroundColor(.secondary)
        }
        .alert("Force Quit Process", isPresented: $showForceQuitAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Force Quit", role: .destructive) {
                if let process = selectedProcess {
                    forceQuitProcess(process)
                }
            }
        } message: {
            if let process = selectedProcess {
                Text("Are you sure you want to force quit \(process.name)? This may cause data loss.")
            }
        }
    }
    
    // MARK: - Process Section
    
    private func processSection(title: String, processes: [ProcessMonitor.ProcessInfo], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.forgeAccent)
                Text(title)
                    .font(.system(.caption, design: .default))
                    .fontWeight(.medium)
            }
            
            if processes.isEmpty {
                Text("No processes to display")
                    .font(.system(.caption, design: .default))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                // Table header
                HStack {
                    Text("Name")
                        .font(.system(.caption2, design: .default))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("PID")
                        .font(.system(.caption2, design: .default))
                        .frame(width: 50, alignment: .center)
                    Text("CPU")
                        .font(.system(.caption2, design: .default))
                        .frame(width: 50, alignment: .trailing)
                    Text("Memory")
                        .font(.system(.caption2, design: .default))
                        .frame(width: 60, alignment: .trailing)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                
                // Process rows
                ForEach(processes) { process in
                    ProcessRow(process: process) {
                        selectedProcess = process
                        showForceQuitAlert = true
                    }
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func forceQuitProcess(_ process: ProcessMonitor.ProcessInfo) {
        if ProcessMonitor.forceQuit(process.pid) {
            forgeLog("Process \(process.name) (PID: \(process.pid)) terminated.")
        } else {
            forgeLog("Failed to terminate process \(process.name).")
        }
    }
}

// MARK: - Process Sort Order

enum ProcessSortOrder {
    case cpu
    case memory
}

// MARK: - Preview

#Preview {
    ProcessesTab(sensorMonitor: SensorMonitor(pollingInterval: 2.0))
        .frame(width: 300, height: 500)
}
