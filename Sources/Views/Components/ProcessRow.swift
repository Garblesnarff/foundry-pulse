import SwiftUI

/// Single process row in the processes list.
struct ProcessRow: View {
    let process: ProcessMonitor.ProcessInfo
    var onForceQuit: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            // Process name with state indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(stateColor)
                    .frame(width: 6, height: 6)
                
                Text(process.name)
                    .font(.system(.caption, design: .default))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // PID
            Text("\(process.pid)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .center)
            
            // CPU %
            Text(String(format: "%.1f%%", process.cpuPercent))
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(ForgeColors.colorForValue(process.cpuPercent))
                .frame(width: 50, alignment: .trailing)
            
            // Memory MB
            Text("\(process.memoryMB) MB")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    
    private var stateColor: Color {
        switch process.state {
        case .running:
            return .forgeGood
        case .stopped:
            return .forgeWarning
        case .zombie:
            return .forgeCritical
        case .sleeping:
            return .secondary
        case .unknown:
            return .secondary
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        ProcessRow(
            process: ProcessMonitor.ProcessInfo(
                pid: 1234,
                name: "Xcode",
                cpuPercent: 45.2,
                memoryMB: 2048,
                state: .running
            )
        )
        
        Divider()
        
        ProcessRow(
            process: ProcessMonitor.ProcessInfo(
                pid: 5678,
                name: "Safari",
                cpuPercent: 12.5,
                memoryMB: 512,
                state: .sleeping
            )
        )
    }
    .frame(width: 280)
    .padding()
}
