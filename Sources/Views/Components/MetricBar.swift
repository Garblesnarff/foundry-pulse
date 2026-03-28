import SwiftUI

/// Horizontal bar for displaying usage metrics (RAM, Disk).
///
/// Shows:
/// - Label on left
/// - Progress bar
/// - Used/Total values on right
/// - Optional pressure indicator
struct MetricBar: View {
    let title: String
    let used: Double
    let total: Double
    let unit: String
    var showPressure: Bool = false
    var pressurePercent: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label row
            HStack {
                Text(title)
                    .font(.system(.caption, design: .default))
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(formattedValues)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geometry.size.width * CGFloat(percentUsed / 100))
                        .animation(.easeInOut(duration: 0.3), value: percentUsed)
                }
            }
            .frame(height: 8)
            
            // Memory pressure (if showing)
            if showPressure {
                HStack {
                    Text("Pressure:")
                        .font(.system(.caption2, design: .default))
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(pressurePercent))%")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(pressureColor)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var percentUsed: Double {
        guard total > 0 else { return 0 }
        return min((used / total) * 100, 100)
    }
    
    private var formattedValues: String {
        if unit == "%" {
            return "\(Int(used))%"
        } else {
            return String(format: "%.1f / %.0f %@", used, total, unit)
        }
    }
    
    private var barColor: Color {
        ForgeColors.colorForValue(percentUsed)
    }
    
    private var pressureColor: Color {
        ForgeColors.colorForValue(pressurePercent, thresholds: (warning: 60, critical: 90))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        MetricBar(
            title: "RAM",
            used: 12.4,
            total: 16,
            unit: "GB",
            showPressure: true,
            pressurePercent: 77
        )
        
        MetricBar(
            title: "Disk",
            used: 45,
            total: 100,
            unit: "%",
            showPressure: false
        )
    }
    .padding()
    .frame(width: 280)
}
