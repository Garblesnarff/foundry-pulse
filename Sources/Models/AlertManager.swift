import Foundation
import AppKit
import UserNotifications

/// Manages alert rules and notification dispatch.
///
/// Responsibilities:
/// - Store and validate alert rules
/// - Check thresholds every 5 seconds
/// - Deduplicate notifications (no spam)
/// - Respect macOS Do Not Disturb
///
/// Alert Rule Format:
/// ```
/// if <metric> <operator> <threshold> for <duration>, then <action>
/// e.g. if CPU % > 80 for 2 minutes, then notify
/// ```
final class AlertManager: NSObject {
    private let sensorMonitor: SensorMonitor
    private var checkTimer: Timer?
    private var lastAlertTime: [UUID: Date] = [:]  // Deduplication (5-min cooldown per rule)
    private let alertCooldown: TimeInterval = 300  // 5 minutes
    
    private var rules: [AlertRule] = [] {
        didSet {
            saveRulesToUserDefaults()
        }
    }
    
    init(sensorMonitor: SensorMonitor) {
        self.sensorMonitor = sensorMonitor
        super.init()
        
        loadRulesFromUserDefaults()
        startCheckingAlerts()
    }
    
    deinit {
        stopCheckingAlerts()
    }
    
    // MARK: - Alert Management
    
    /// Add a new alert rule.
    func addRule(_ rule: AlertRule) {
        rules.append(rule)
        forgeLog("Alert rule added: \(rule.name)")
    }
    
    /// Remove an alert rule.
    func removeRule(_ id: UUID) {
        rules.removeAll { $0.id == id }
        forgeLog("Alert rule removed.")
    }
    
    /// Toggle alert rule on/off.
    func toggleRule(_ id: UUID) {
        if let index = rules.firstIndex(where: { $0.id == id }) {
            rules[index].enabled.toggle()
        }
    }
    
    /// Get all rules.
    func getAllRules() -> [AlertRule] {
        return rules
    }
    
    // MARK: - Alert Checking
    
    private func startCheckingAlerts() {
        stopCheckingAlerts()
        
        // Check every 5 seconds
        checkTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkAllRules()
        }
    }
    
    private func stopCheckingAlerts() {
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    private func checkAllRules() {
        for rule in rules where rule.enabled {
            if shouldTriggerAlert(for: rule) {
                triggerAlert(for: rule)
            }
        }
    }
    
    private func shouldTriggerAlert(for rule: AlertRule) -> Bool {
        // Check deduplication (don't alert again within cooldown)
        if let lastTime = lastAlertTime[rule.id] {
            if Date().timeIntervalSince(lastTime) < alertCooldown {
                return false
            }
        }
        
        // Evaluate rule against current metric
        let metric = sensorMonitor.currentReading
        let threshold = rule.threshold
        
        switch rule.metric {
        case .cpu:
            switch rule.op {
            case .greaterThan:
                return metric.cpuPercent > threshold
            case .lessThan:
                return metric.cpuPercent < threshold
            case .greaterThanOrEqual:
                return metric.cpuPercent >= threshold
            case .lessThanOrEqual:
                return metric.cpuPercent <= threshold
            }
            
        case .gpuTemp:
            guard let gpuTemp = metric.gpuTempCelsius else { return false }
            switch rule.op {
            case .greaterThan:
                return gpuTemp > threshold
            case .lessThan:
                return gpuTemp < threshold
            case .greaterThanOrEqual:
                return gpuTemp >= threshold
            case .lessThanOrEqual:
                return gpuTemp <= threshold
            }
            
        case .ramPressure:
            switch rule.op {
            case .greaterThan:
                return metric.memoryPressurePercent > threshold
            case .lessThan:
                return metric.memoryPressurePercent < threshold
            case .greaterThanOrEqual:
                return metric.memoryPressurePercent >= threshold
            case .lessThanOrEqual:
                return metric.memoryPressurePercent <= threshold
            }
            
        case .diskUsed:
            switch rule.op {
            case .greaterThan:
                return metric.diskUsedPercent > threshold
            case .lessThan:
                return metric.diskUsedPercent < threshold
            case .greaterThanOrEqual:
                return metric.diskUsedPercent >= threshold
            case .lessThanOrEqual:
                return metric.diskUsedPercent <= threshold
            }
        }
    }
    
    private func triggerAlert(for rule: AlertRule) {
        lastAlertTime[rule.id] = Date()
        
        // Dispatch alert action
        switch rule.action {
        case .notification:
            sendNotification(for: rule)
        case .sound:
            playAlertSound()
        case .log:
            logAlert(for: rule)
        }
        
        forgeLog("Alert triggered: \(rule.name)")
    }
    
    // MARK: - Alert Actions
    
    private func sendNotification(for rule: AlertRule) {
        let content = UNMutableNotificationContent()
        content.title = "Foundry Pulse Alert"
        content.subtitle = "The forge overheats!"
        content.body = rule.name
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: rule.id.uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
    
    private func playAlertSound() {
        // Play alert sound (beep)
        NSSound(named: "Glass")?.play()
    }
    
    private func logAlert(for rule: AlertRule) {
        let timestamp = DateFormatter.forgeFormatter.string(from: Date())
        let logEntry = "[\(timestamp)] ALERT: \(rule.name)"
        forgeLog(logEntry)
        
        // Also write to ~/Library/Logs/FoundryPulse/alerts.log
        // (implementation deferred)
    }
    
    // MARK: - Persistence
    
    private func saveRulesToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(encoded, forKey: "AlertRules")
        }
    }
    
    private func loadRulesFromUserDefaults() {
        guard let data = UserDefaults.standard.data(forKey: "AlertRules") else { return }
        if let decoded = try? JSONDecoder().decode([AlertRule].self, from: data) {
            self.rules = decoded
        }
    }
}

// MARK: - Alert Rule Model

/// Single alert rule.
struct AlertRule: Identifiable, Codable, Sendable {
    let id: UUID
    let name: String
    let metric: AlertMetric
    let op: AlertOperator
    let threshold: Double
    let duration: AlertDuration  // For future use (check for N consecutive readings)
    var action: AlertAction
    var enabled: Bool
    
    init(
        name: String,
        metric: AlertMetric,
        op: AlertOperator,
        threshold: Double,
        duration: AlertDuration = .immediate,
        action: AlertAction = .notification,
        enabled: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.metric = metric
        self.op = op
        self.threshold = threshold
        self.duration = duration
        self.action = action
        self.enabled = enabled
    }
}

enum AlertMetric: String, Codable, CaseIterable, Sendable {
    case cpu = "CPU %"
    case gpuTemp = "GPU Temp (°C)"
    case ramPressure = "RAM Pressure %"
    case diskUsed = "Disk Used %"
}

enum AlertOperator: String, Codable, CaseIterable, Sendable {
    case greaterThan = ">"
    case lessThan = "<"
    case greaterThanOrEqual = ">="
    case lessThanOrEqual = "<="
}

enum AlertDuration: String, Codable, CaseIterable, Sendable {
    case immediate = "Immediately"
    case thirtySeconds = "30 seconds"
    case oneMinute = "1 minute"
    case twoMinutes = "2 minutes"
    case fiveMinutes = "5 minutes"
}

enum AlertAction: String, Codable, CaseIterable, Sendable {
    case notification = "Notification"
    case sound = "Sound"
    case log = "Log Entry"
}
