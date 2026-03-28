import SwiftUI

/// Circular gauge for displaying percentage metrics.
///
/// Shows:
/// - Circular progress indicator
/// - Current value (large)
/// - Title and subtitle
struct MetricCircle: View {
    let title: String
    let value: Double
    let maxValue: Double
    var subtitle: String = ""
    
    var body: some View {
        VStack(spacing: 8) {
            // Circular gauge
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: min(value / maxValue, 1.0))
                    .stroke(
                        colorForValue,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: value)
                
                // Value text
                VStack(spacing: 2) {
                    Text("\(Int(value))%")
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(colorForValue)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 80, height: 80)
            
            // Title
            Text(title)
                .font(.system(.caption, design: .default))
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var colorForValue: Color {
        ForgeColors.colorForValue(value)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        MetricCircle(title: "CPU", value: 45, maxValue: 100, subtitle: "8 cores")
        MetricCircle(title: "GPU", value: 85, maxValue: 100, subtitle: "58°C")
    }
    .padding()
    .frame(width: 300)
}
