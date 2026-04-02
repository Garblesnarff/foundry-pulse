import SwiftUI

/// Battery status indicator showing charge level, health, and time remaining.
struct BatteryIndicator: View {
    let percent: Int
    let health: BatteryHealth
    let timeToEmpty: TimeInterval?
    
    var body: some View {
        HStack(spacing: 12) {
            // Battery icon with fill
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(batteryColor, lineWidth: 2)
                    .frame(width: 30, height: 16)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(batteryColor.opacity(0.3))
                    .frame(width: (30 - 4) * CGFloat(percent) / 100, height: 16 - 4)
                    .padding(.leading, 2)
                
                // Battery tip
                Rectangle()
                    .fill(batteryColor)
                    .frame(width: 3, height: 8)
                    .offset(x: 16)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("\(percent)%")
                        .font(.system(.callout, design: .monospaced))
                        .fontWeight(.medium)
                    
                    if let time = timeToEmpty {
                        Text("(\(formattedTime(time)))")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(health.displayName)
                    .font(.system(.caption2, design: .default))
                    .foregroundColor(healthColor)
            }
            
            Spacer()
            
            // Charging indicator (if needed - for future)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var batteryColor: Color {
        if percent <= 20 {
            return .forgeCritical
        } else if percent <= 50 {
            return .forgeWarning
        }
        return .forgeGood
    }
    
    private var healthColor: Color {
        switch health {
        case .excellent, .good:
            return .forgeGood
        case .fair:
            return .forgeWarning
        case .poor:
            return .forgeCritical
        case .unknown:
            return .secondary
        }
    }
    
    private func formattedTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - BatteryHealth Extension

extension BatteryHealth {
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Replace Soon"
        case .unknown: return "Unknown"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        BatteryIndicator(
            percent: 85,
            health: .good,
            timeToEmpty: 4 * 3600
        )
        
        BatteryIndicator(
            percent: 15,
            health: .fair,
            timeToEmpty: 45 * 60
        )
    }
    .frame(width: 280)
    .padding()
}
