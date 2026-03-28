import SwiftUI

/// Thermal strip showing CPU/GPU temperatures and fan speed.
///
/// Displays:
/// - Color-coded temperature indicators
/// - Fan speed indicator
/// - Thermal state indicator
struct ThermalStrip: View {
    let cpuTemp: Double?
    let gpuTemp: Double?
    let fanRPM: Int?
    let thermalState: ThermalState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "thermometer.medium")
                    .foregroundColor(.forgeAccent)
                Text("Thermal")
                    .font(.system(.caption, design: .default))
                    .fontWeight(.medium)
                
                Spacer()
                
                // Thermal state badge
                ThermalStateBadge(state: thermalState)
            }
            
            // Temperature indicators
            HStack(spacing: 12) {
                if let cpu = cpuTemp {
                    TemperatureIndicator(label: "CPU", temp: cpu)
                } else {
                    TemperatureIndicator(label: "CPU", temp: nil)
                }
                
                if let gpu = gpuTemp {
                    TemperatureIndicator(label: "GPU", temp: gpu)
                } else {
                    TemperatureIndicator(label: "GPU", temp: nil)
                }
                
                if let rpm = fanRPM {
                    FanIndicator(rpm: rpm)
                } else {
                    FanIndicator(rpm: nil)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Temperature Indicator

struct TemperatureIndicator: View {
    let label: String
    let temp: Double?
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(.caption2, design: .default))
                .foregroundColor(.secondary)
            
            if let temp = temp {
                Text("\(Int(temp))°C")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(tempColor)
            } else {
                Text("—")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            // Temperature bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                    
                    if let temp = temp {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(tempColor)
                            .frame(width: geometry.size.width * CGFloat(min(temp / 100, 1.0)))
                    }
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var tempColor: Color {
        guard let temp = temp else { return .secondary }
        return ForgeColors.colorForTemperature(temp)
    }
}

// MARK: - Fan Indicator

struct FanIndicator: View {
    let rpm: Int?
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Fan")
                .font(.system(.caption2, design: .default))
                .foregroundColor(.secondary)
            
            if let rpm = rpm {
                Text("\(rpm)")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(fanColor)
            } else {
                Text("—")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var fanColor: Color {
        guard let rpm = rpm else { return .secondary }
        // Fan above 5000 RPM is high
        if rpm > 5000 {
            return .forgeWarning
        }
        return .secondary
    }
}

// MARK: - Thermal State Badge

struct ThermalStateBadge: View {
    let state: ThermalState
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(stateColor)
                .frame(width: 6, height: 6)
            
            Text(state.displayName)
                .font(.system(.caption2, design: .default))
                .foregroundColor(stateColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(stateColor.opacity(0.1))
        .cornerRadius(4)
    }
    
    private var stateColor: Color {
        switch state {
        case .nominal:
            return .forgeGood
        case .powerLimited, .thermalLimited:
            return .forgeWarning
        case .critical:
            return .forgeCritical
        }
    }
}

// MARK: - ThermalState Extension

extension ThermalState {
    var displayName: String {
        switch self {
        case .nominal:
            return "Nominal"
        case .powerLimited:
            return "Power Limited"
        case .thermalLimited:
            return "Thermal Limited"
        case .critical:
            return "Critical"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ThermalStrip(
            cpuTemp: 65,
            gpuTemp: 58,
            fanRPM: 4200,
            thermalState: .nominal
        )
        
        ThermalStrip(
            cpuTemp: 85,
            gpuTemp: 78,
            fanRPM: 6200,
            thermalState: .thermalLimited
        )
    }
    .frame(width: 280)
    .padding()
}
