import SwiftUI
import Charts

/// Graphs tab showing historical data for metrics.
///
/// Provides:
/// - Time range selector (1 min / 1 hr / 24 hr)
/// - Metric selector (CPU / GPU / RAM / Disk)
/// - Historical line chart using SwiftCharts
struct GraphsTab: View {
    @ObservedObject var sensorMonitor: SensorMonitor
    @State private var selectedDuration: ChartDuration = .oneMinute
    @State private var selectedMetric: Metric = .cpu
    
    var body: some View {
        VStack(spacing: 16) {
            // Time range selector
            Picker("Time Range", selection: $selectedDuration) {
                ForEach(ChartDuration.allCases, id: \.self) { duration in
                    Text(duration.rawValue).tag(duration)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            
            // Metric selector
            Picker("Metric", selection: $selectedMetric) {
                ForEach(Metric.allCases, id: \.self) { metric in
                    Text(metric.rawValue).tag(metric)
                }
            }
            .pickerStyle(.menu)
            
            // Chart
            chartView
                .frame(minHeight: 200)
            
            // Stats summary
            statsSummary
            
            Spacer()
        }
    }
    
    // MARK: - Chart View
    
    private var chartView: some View {
        let chartData = sensorMonitor.getHistoricalData(for: selectedMetric, duration: selectedDuration)
        
        return Chart(chartData) { point in
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value(selectedMetric.rawValue, point.value)
            )
            .foregroundStyle(ForgeColors.accent)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Time", point.timestamp),
                y: .value(selectedMetric.rawValue, point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [ForgeColors.accent.opacity(0.3), ForgeColors.accent.opacity(0.05)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.3))
                AxisValueLabel()
                    .foregroundStyle(Color.secondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.3))
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(formatYValue(doubleValue))
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        }
        .chartYScale(domain: yAxisDomain)
    }
    
    private var yAxisDomain: ClosedRange<Double> {
        let chartData = sensorMonitor.getHistoricalData(for: selectedMetric, duration: selectedDuration)
        let maxValue: Double = chartData.map { $0.value }.max() ?? 100
        let minValue: Double = chartData.map { $0.value }.min() ?? 0

        // Add padding
        let padding: Double = (maxValue - minValue) * 0.1
        let lowerBound: Double = Swift.max(0, minValue - padding)
        let upperBound: Double = maxValue + padding
        return lowerBound...upperBound
    }
    
    private func formatYValue(_ value: Double) -> String {
        switch selectedMetric {
        case .cpu, .gpu:
            return "\(Int(value))%"
        case .memory:
            return String(format: "%.1f GB", value)
        case .disk:
            return "\(Int(value))%"
        }
    }
    
    // MARK: - Stats Summary
    
    private var statsSummary: some View {
        let chartData = sensorMonitor.getHistoricalData(for: selectedMetric, duration: selectedDuration)
        
        return HStack(spacing: 16) {
            StatBox(title: "Current", value: currentValue)
            StatBox(title: "Average", value: averageValue(chartData))
            StatBox(title: "Max", value: maxValue(chartData))
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var currentValue: String {
        let reading = sensorMonitor.currentReading
        switch selectedMetric {
        case .cpu: return "\(Int(reading.cpuPercent))%"
        case .gpu: return "\(Int(reading.gpuPercent))%"
        case .memory: return String(format: "%.1f GB", Double(reading.memoryUsedMB) / 1024)
        case .disk: return "\(Int(reading.diskUsedPercent))%"
        }
    }
    
    private func averageValue(_ data: [ChartPoint]) -> String {
        guard !data.isEmpty else { return "—" }
        let avg = data.map { $0.value }.reduce(0, +) / Double(data.count)
        
        switch selectedMetric {
        case .cpu, .gpu: return "\(Int(avg))%"
        case .memory: return String(format: "%.1f GB", avg)
        case .disk: return "\(Int(avg))%"
        }
    }
    
    private func maxValue(_ data: [ChartPoint]) -> String {
        guard let maxVal = data.map({ $0.value }).max() else { return "—" }
        
        switch selectedMetric {
        case .cpu, .gpu: return "\(Int(maxVal))%"
        case .memory: return String(format: "%.1f GB", maxVal)
        case .disk: return "\(Int(maxVal))%"
        }
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(.caption2, design: .default))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    GraphsTab(sensorMonitor: SensorMonitor(pollingInterval: 2.0))
        .frame(width: 300, height: 500)
}
