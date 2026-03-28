import SwiftUI

/// Main menu bar popover view.
///
/// Contains:
/// - Header with system info
/// - Tab content (Overview, Graphs, Processes, Settings)
/// - Tab navigation bar
///
/// Forge language: "Forge pulse online." on appear
struct MenuBarView: View {
    @ObservedObject var sensorMonitor: SensorMonitor
    @ObservedObject var preferences = UserPreferences.shared
    @State private var selectedTab: TabSelection = .overview
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Tab content
            TabView(selection: $selectedTab) {
                OverviewTab(sensorMonitor: sensorMonitor)
                    .tag(TabSelection.overview)
                
                GraphsTab(sensorMonitor: sensorMonitor)
                    .tag(TabSelection.graphs)
                
                ProcessesTab(sensorMonitor: sensorMonitor)
                    .tag(TabSelection.processes)
                
                SettingsTab(sensorMonitor: sensorMonitor)
                    .tag(TabSelection.settings)
            }
            .tabViewStyle(.automatic)
            .padding()
            
            Divider()
            
            // Tab navigation
            tabNavigation
        }
        .frame(
            width: preferences.popoverWidth,
            height: preferences.popoverHeight
        )
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            forgeLog("Forge pulse online.")
        }
        .onChange(of: selectedTab) { _, newValue in
            preferences.selectedTab = newValue
        }
        .onChange(of: preferences.selectedTab) { _, newValue in
            selectedTab = newValue
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Foundry Pulse")
                    .font(.system(.headline, design: .default))
                    .fontWeight(.semibold)
                    .foregroundColor(.forgeAccent)
                
                Text(sensorMonitor.currentReading.systemChipName)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Sparkline mini-graph
            SparklineGraph(
                data: Array(sensorMonitor.history.suffix(8).map { $0.cpuPercent }),
                color: ForgeColors.colorForValue(sensorMonitor.currentReading.cpuPercent)
            )
            .frame(width: 50, height: 20)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Tab Navigation
    
    private var tabNavigation: some View {
        HStack(spacing: 0) {
            ForEach(TabSelection.allCases, id: \.self) { tab in
                TabButton(
                    label: tab.displayName,
                    isSelected: selectedTab == tab
                ) {
                    selectedTab = tab
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

// MARK: - Tab Button Component

struct TabButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(.caption, design: .default))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(isSelected ? Color.forgeAccent.opacity(0.2) : Color.clear)
                .foregroundColor(isSelected ? .forgeAccent : .secondary)
        }
        .buttonStyle(.plain)
        .overlay(
            Rectangle()
                .fill(isSelected ? Color.forgeAccent : Color.clear)
                .frame(height: 2),
            alignment: .bottom
        )
    }
}

// MARK: - Tab Selection Extension

extension TabSelection {
    var displayName: String {
        switch self {
        case .overview: return "Overview"
        case .graphs: return "Graphs"
        case .processes: return "Processes"
        case .settings: return "Settings"
        }
    }
}
