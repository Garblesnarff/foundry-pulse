import SwiftUI

/// Forge color palette for Foundry Pulse.
///
/// Uses charcoal blacks (#141210) and amber accents (#E8A849).
/// Dark appearance ONLY - no light mode support.
enum ForgeColors {
    // MARK: - Background Colors
    
    /// Primary background: charcoal black (#141210)
    static let background = Color(red: 0x14/255, green: 0x12/255, blue: 0x10/255)
    
    /// Secondary background: slightly lighter charcoal
    static let backgroundSecondary = Color(red: 0x1A/255, green: 0x18/255, blue: 0x16/255)
    
    /// Control background (for cards, sections)
    static let controlBackground = Color(nsColor: .controlBackgroundColor)
    
    // MARK: - Accent Colors
    
    /// Primary accent: amber gold (#E8A849)
    static let accent = Color(red: 0xE8/255, green: 0xA8/255, blue: 0x49/255)
    
    /// Secondary amber (lighter)
    static let accentSecondary = Color(red: 0xF0/255, green: 0xB8/255, blue: 0x69/255)
    
    /// Accent with opacity
    static let accentMuted = Color(red: 0xE8/255, green: 0xA8/255, blue: 0x49/255).opacity(0.2)
    
    // MARK: - Status Colors
    
    /// Good/nominal state: green
    static let statusGood = Color.green
    
    /// Warning state: yellow/orange
    static let statusWarning = Color.orange
    
    /// Critical state: red
    static let statusCritical = Color.red
    
    // MARK: - Text Colors
    
    /// Primary text: white
    static let textPrimary = Color.primary
    
    /// Secondary text: gray
    static let textSecondary = Color.secondary
    
    /// Muted text: lighter gray
    static let textMuted = Color.gray
    
    // MARK: - Utility
    
    /// Get color for metric value (good/warning/critical based on percentage)
    static func colorForValue(_ value: Double, thresholds: (warning: Double, critical: Double) = (50, 80)) -> Color {
        if value >= thresholds.critical {
            return statusCritical
        } else if value >= thresholds.warning {
            return statusWarning
        }
        return statusGood
    }
    
    /// Get color for temperature (good/warning/critical based on °C)
    static func colorForTemperature(_ temp: Double) -> Color {
        if temp >= 90 {
            return statusCritical
        } else if temp >= 70 {
            return statusWarning
        }
        return statusGood
    }
}

// MARK: - Custom Color Extension

extension Color {
    /// Amber accent color
    static let forgeAccent = ForgeColors.accent
    
    /// Background color
    static let forgeBackground = ForgeColors.background
    
    /// Secondary background
    static let forgeBackgroundSecondary = ForgeColors.backgroundSecondary
    
    /// Good status
    static let forgeGood = ForgeColors.statusGood
    
    /// Warning status
    static let forgeWarning = ForgeColors.statusWarning
    
    /// Critical status
    static let forgeCritical = ForgeColors.statusCritical
}
