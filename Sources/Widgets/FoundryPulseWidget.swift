import SwiftUI
import WidgetKit

/// Foundry Pulse WidgetKit extension.
///
/// Provides small (2×2) and medium (3×3) widgets for macOS desktop.
///
/// Important: Widgets run in separate process, cannot directly poll sensors.
/// Solution: App writes cached data to shared UserDefaults (app groups).
/// Widget reads cache and updates every 10 seconds (WidgetKit minimum).
///
/// Availability: macOS 14+ (Sonoma and later)

@available(macOS 14.0, *)
struct FoundryPulseWidget: Widget {
    let kind: String = "com.foundry.pulse.widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FoundryPulseWidgetView(entry: entry)
                .containerBackground(.fill, for: .widget)
        }
        .configurationDisplayName("Foundry Pulse")
        .description("Real-time hardware monitoring")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    /// Placeholder while loading.
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            cpuPercent: 0,
            gpuPercent: 0,
            ramUsedGB: 0,
            ramTotalGB: 16,
            diskUsedPercent: 0
        )
    }
    
    /// Snapshot for preview.
    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        let entry = loadCurrentEntry()
        completion(entry)
    }
    
    /// Timeline of updates.
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let entry = loadCurrentEntry()
        
        // Update every 10 seconds (WidgetKit minimum)
        let nextUpdate = Calendar.current.date(byAdding: .second, value: 10, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    /// Load data from shared app group UserDefaults.
    private func loadCurrentEntry() -> WidgetEntry {
        let defaults = UserDefaults(suiteName: "group.com.foundry.pulse")
        
        // Fallback to defaults if data unavailable
        let cpuPercent = defaults?.double(forKey: "cpuPercent") ?? 0
        let gpuPercent = defaults?.double(forKey: "gpuPercent") ?? 0
        let ramUsedGB = defaults?.double(forKey: "ramUsedGB") ?? 0
        let ramTotalGB = defaults?.double(forKey: "ramTotalGB") ?? 16
        let diskUsedPercent = defaults?.double(forKey: "diskUsedPercent") ?? 0
        
        return WidgetEntry(
            date: Date(),
            cpuPercent: cpuPercent,
            gpuPercent: gpuPercent,
            ramUsedGB: ramUsedGB,
            ramTotalGB: ramTotalGB,
            diskUsedPercent: diskUsedPercent
        )
    }
}

// MARK: - Widget Entry

struct WidgetEntry: TimelineEntry {
    let date: Date
    let cpuPercent: Double
    let gpuPercent: Double
    let ramUsedGB: Double
    let ramTotalGB: Double
    let diskUsedPercent: Double
}

// MARK: - Widget Views

struct FoundryPulseWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        VStack {
            Text("Foundry Pulse")
                .font(.system(.caption, design: .default))
                .foregroundColor(.secondary)
            
            // Render appropriate widget based on size
            #if os(macOS)
            if #available(macOS 14, *) {
                SmallWidgetContent(entry: entry)
            }
            #endif
        }
    }
}

// MARK: - Small Widget (2×2)

struct SmallWidgetContent: View {
    let entry: WidgetEntry
    
    var body: some View {
        VStack(spacing: 0) {
            // Large CPU percentage
            Text("\(Int(entry.cpuPercent))%")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(cpuColor(for: entry.cpuPercent))
            
            Text("CPU")
                .font(.system(size: 9, weight: .regular, design: .default))
                .foregroundColor(.secondary)
            
            // Mini sparkline (placeholder)
            Canvas { context, size in
                let width = 60.0
                let height = 8.0
                
                // Draw simple bar
                var path = Path()
                path.addRect(CGRect(x: 0, y: height - (height * entry.cpuPercent / 100), width: width, height: height * entry.cpuPercent / 100))
                
                context.fill(
                    path,
                    with: .color(cpuColor(for: entry.cpuPercent))
                )
            }
            .frame(height: 8)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func cpuColor(for percent: Double) -> Color {
        if percent < 50 {
            return Color(red: 0.063, green: 0.725, blue: 0.51)  // Green
        } else if percent < 80 {
            return Color(red: 0.965, green: 0.62, blue: 0.067)  // Yellow
        } else {
            return Color(red: 0.937, green: 0.267, blue: 0.267)  // Red
        }
    }
}

// MARK: - Medium Widget (3×3)

struct MediumWidgetContent: View {
    let entry: WidgetEntry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // CPU
                MetricQuadrant(
                    label: "CPU",
                    value: Int(entry.cpuPercent),
                    unit: "%",
                    color: cpuColor(for: entry.cpuPercent)
                )
                
                // GPU
                MetricQuadrant(
                    label: "GPU",
                    value: Int(entry.gpuPercent),
                    unit: "%",
                    color: gpuColor(for: entry.gpuPercent)
                )
            }
            
            HStack(spacing: 8) {
                // RAM
                BarQuadrant(
                    label: "RAM",
                    used: entry.ramUsedGB,
                    total: entry.ramTotalGB,
                    color: .purple
                )
                
                // Disk
                BarQuadrant(
                    label: "Disk",
                    used: entry.diskUsedPercent,
                    total: 100,
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func cpuColor(for percent: Double) -> Color {
        if percent < 50 {
            return Color(red: 0.063, green: 0.725, blue: 0.51)
        } else if percent < 80 {
            return Color(red: 0.965, green: 0.62, blue: 0.067)
        } else {
            return Color(red: 0.937, green: 0.267, blue: 0.267)
        }
    }
    
    private func gpuColor(for percent: Double) -> Color {
        if percent < 50 {
            return Color(red: 0.024, green: 0.714, blue: 0.831)
        } else if percent < 80 {
            return Color(red: 0.976, green: 0.62, blue: 0.067)
        } else {
            return Color(red: 0.937, green: 0.267, blue: 0.267)
        }
    }
}

// MARK: - Widget Components

struct MetricQuadrant: View {
    let label: String
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .regular, design: .default))
                .foregroundColor(.secondary)
            
            Text("\(value)\(unit)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(4)
    }
}

struct BarQuadrant: View {
    let label: String
    let used: Double
    let total: Double
    let color: Color
    
    var percent: Double {
        (used / total) * 100
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .regular, design: .default))
                .foregroundColor(.secondary)
            
            ProgressView(value: used / total)
                .tint(color)
            
            Text("\(Int(used))/\(Int(total))")
                .font(.system(size: 8, weight: .regular, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(4)
        .padding(4)
    }
}

// MARK: - Preview

#if DEBUG
struct FoundryPulseWidget_Previews: PreviewProvider {
    static var previews: some View {
        let sampleEntry = WidgetEntry(
            date: Date(),
            cpuPercent: 45,
            gpuPercent: 25,
            ramUsedGB: 10.4,
            ramTotalGB: 16,
            diskUsedPercent: 42
        )
        
        FoundryPulseWidgetView(entry: sampleEntry)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
#endif
