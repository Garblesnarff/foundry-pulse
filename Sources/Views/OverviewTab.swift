import SwiftUI

/// Overview tab showing real-time metrics.
///
/// Displays:
/// - CPU % (circular gauge)
/// - GPU % (circular gauge)
/// - RAM usage (bar)
/// - Disk usage (bar)
/// - Network (up/down indicators)
/// - Battery status
/// - Thermal strip
struct OverviewTab: View {
    @ObservedObject var sensorMonitor: SensorMonitor
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // CPU and GPU gauges
                HStack(spacing: 16) {
                    MetricCircle(
                        title: "CPU",
                        value: sensorMonitor.currentReading.cpuPercent,
                        maxValue: 100,
                        subtitle: "\(sensorMonitor.currentReading.cpuCoreCount) cores"
                    )
                    
                    MetricCircle(
                        title: "GPU",
                        value: sensorMonitor.currentReading.gpuPercent,
                        maxValue: 100,
                        subtitle: sensorMonitor.currentReading.gpuTempCelsius != nil 
                            ? "\(Int(sensorMonitor.currentReading.gpuTempCelsius!))°C"
                            : "—"
                    )
                }
                
                // Memory and Disk bars
                VStack(spacing: 12) {
                    MetricBar(
                        title: "RAM",
                        used: Double(sensorMonitor.currentReading.memoryUsedMB) / 1024.0,
                        total: Double(sensorMonitor.currentReading.memoryTotalMB) / 1024.0,
                        unit: "GB",
                        showPressure: true,
                        pressurePercent: sensorMonitor.currentReading.memoryPressurePercent
                    )
                    
                    MetricBar(
                        title: "Disk",
                        used: sensorMonitor.currentReading.diskUsedPercent,
                        total: 100,
                        unit: "%",
                        showPressure: false
                    )
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                
                // Network
                NetworkIndicator(
                    uploadMbps: sensorMonitor.currentReading.networkUpMbps,
                    downloadMbps: sensorMonitor.currentReading.networkDownMbps
                )
                
                // Battery
                if sensorMonitor.currentReading.batteryPercent > 0 {
                    BatteryIndicator(
                        percent: sensorMonitor.currentReading.batteryPercent,
                        health: sensorMonitor.currentReading.batteryHealth,
                        timeToEmpty: sensorMonitor.currentReading.batteryTimeToEmpty
                    )
                }
                
                // Thermal strip
                ThermalStrip(
                    cpuTemp: sensorMonitor.currentReading.cpuTempCelsius,
                    gpuTemp: sensorMonitor.currentReading.gpuTempCelsius,
                    fanRPM: sensorMonitor.currentReading.fanRPM,
                    thermalState: sensorMonitor.currentReading.thermalState
                )
                
                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OverviewTab(sensorMonitor: SensorMonitor(pollingInterval: 2.0))
        .frame(width: 300, height: 500)
}
