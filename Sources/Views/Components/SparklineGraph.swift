import SwiftUI

/// Mini sparkline graph for menu bar display.
///
/// Shows:
/// - Rolling buffer of values (8 samples)
/// - Color-coded by utilization
/// - Smooth line with gradient fill
struct SparklineGraph: View {
    let data: [Double]
    var color: Color = .forgeAccent
    var showFill: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            if data.count >= 2 {
                sparklinePath(in: geometry.size)
                    .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            } else {
                // No data - show placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
        }
    }
    
    private func sparklinePath(in size: CGSize) -> Path {
        Path { path in
            guard data.count >= 2 else { return }
            
            let maxValue = data.max() ?? 100
            let minValue = data.min() ?? 0
            let range = max(maxValue - minValue, 1)
            
            let stepX = size.width / CGFloat(data.count - 1)
            
            for (index, value) in data.enumerated() {
                let x = CGFloat(index) * stepX
                let normalizedValue = (value - minValue) / range
                let y = size.height - (CGFloat(normalizedValue) * size.height)
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
    }
}

// MARK: - Full Sparkline with Fill

struct FullSparklineGraph: View {
    let data: [Double]
    var color: Color = .forgeAccent
    var lineWidth: CGFloat = 1.5
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if data.count >= 2 {
                    // Fill area
                    sparklineFillPath(in: geometry.size)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color.opacity(0.3), color.opacity(0.05)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Line
                    sparklinePath(in: geometry.size)
                        .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }
    
    private func sparklinePath(in size: CGSize) -> Path {
        Path { path in
            guard data.count >= 2 else { return }
            
            let maxValue = data.max() ?? 100
            let minValue = data.min() ?? 0
            let range = max(maxValue - minValue, 1)
            
            let stepX = size.width / CGFloat(data.count - 1)
            
            for (index, value) in data.enumerated() {
                let x = CGFloat(index) * stepX
                let normalizedValue = (value - minValue) / range
                let y = size.height - (CGFloat(normalizedValue) * size.height)
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
    }
    
    private func sparklineFillPath(in size: CGSize) -> Path {
        Path { path in
            guard data.count >= 2 else { return }
            
            let maxValue = data.max() ?? 100
            let minValue = data.min() ?? 0
            let range = max(maxValue - minValue, 1)
            
            let stepX = size.width / CGFloat(data.count - 1)
            
            // Start at bottom-left
            path.move(to: CGPoint(x: 0, y: size.height))
            
            for (index, value) in data.enumerated() {
                let x = CGFloat(index) * stepX
                let normalizedValue = (value - minValue) / range
                let y = size.height - (CGFloat(normalizedValue) * size.height)
                
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            // Close at bottom-right
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.closeSubpath()
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        SparklineGraph(
            data: [10, 20, 15, 30, 45, 35, 50, 40],
            color: .forgeAccent
        )
        .frame(width: 50, height: 20)
        
        FullSparklineGraph(
            data: [10, 20, 15, 30, 45, 35, 50, 40, 60, 55],
            color: .forgeAccent
        )
        .frame(width: 200, height: 50)
    }
    .padding()
}
