import SwiftUI

/// Network activity indicator showing upload/download speeds.
struct NetworkIndicator: View {
    let uploadMbps: Double
    let downloadMbps: Double
    
    var body: some View {
        HStack(spacing: 16) {
            // Upload
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.forgeAccent)
                        .font(.system(.caption))
                    Text("Upload")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.secondary)
                }
                Text(formattedSpeed(uploadMbps))
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.medium)
            }
            
            Divider()
                .frame(height: 30)
            
            // Download
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.forgeAccent)
                        .font(.system(.caption))
                    Text("Download")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.secondary)
                }
                Text(formattedSpeed(downloadMbps))
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func formattedSpeed(_ mbps: Double) -> String {
        if mbps < 1 {
            return String(format: "%.0f Kbps", mbps * 1000)
        } else {
            return String(format: "%.1f Mbps", mbps)
        }
    }
}

// MARK: - Preview

#Preview {
    NetworkIndicator(uploadMbps: 2.5, downloadMbps: 45.3)
        .frame(width: 280)
        .padding()
}
