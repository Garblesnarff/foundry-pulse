import Foundation
import CoreData

/// Manages Core Data persistence for historical metrics and settings.
///
/// Handles:
/// - Reading/writing historical sensor data
/// - Alert rule persistence
/// - User preferences
/// - Migration and schema updates
///
/// Thread Safety:
/// - All Core Data operations on background context
/// - Main context for UI binding (rare)
final class DatabaseManager {
    static let shared = DatabaseManager()
    
    let persistentContainer: NSPersistentContainer
    
    init() {
        // TODO: Create Core Data model file (.xcdatamodeld)
        //
        // Entities:
        // 1. SensorReadingEntity
        //    - timestamp (Date)
        //    - cpuPercent (Double)
        //    - gpuPercent (Double)
        //    - memoryUsedMB (Integer 64)
        //    - diskUsedPercent (Double)
        //    - etc.
        //
        // 2. AlertRuleEntity
        //    - id (String)
        //    - name (String)
        //    - metric (String)
        //    - operator (String)
        //    - threshold (Double)
        //    - enabled (Boolean)
        //
        // 3. SettingsEntity
        //    - key (String)
        //    - value (String)
        
        persistentContainer = NSPersistentContainer(name: "FoundryPulse")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                forgeLog("Core Data error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Sensor Reading CRUD
    
    /// Save a sensor reading to Core Data.
    func saveSensorReading(_ reading: SensorReading) {
        let context = persistentContainer.newBackgroundContext()
        context.perform {
            // TODO: Create NSManagedObject from reading
            // TODO: Save context
        }
    }
    
    /// Fetch sensor readings for a time window.
    func fetchSensorReadings(from startDate: Date, to endDate: Date) -> [SensorReading] {
        let context = persistentContainer.newBackgroundContext()
        var readings: [SensorReading] = []
        
        context.performAndWait {
            // TODO: Fetch predicate: timestamp >= startDate AND timestamp <= endDate
            // TODO: Decode NSManagedObject to SensorReading
        }
        
        return readings
    }
    
    /// Delete old sensor readings (data retention policy).
    func purgeOldReadings(olderThan days: Int) {
        let context = persistentContainer.newBackgroundContext()
        context.perform {
            let cutoff = Date().addingTimeInterval(-TimeInterval(days * 86400))
            
            // TODO: Fetch predicate: timestamp < cutoff
            // TODO: Delete and save
            forgeLog("Purged sensor data older than \(days) days.")
        }
    }
    
    // MARK: - Alert Rule CRUD
    
    func saveAlertRule(_ rule: AlertRule) {
        // TODO: Persist to Core Data
    }
    
    func fetchAlertRules() -> [AlertRule] {
        // TODO: Fetch from Core Data
        return []
    }
    
    // MARK: - Settings CRUD
    
    func saveSetting(key: String, value: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    func getSetting(key: String) -> String? {
        return UserDefaults.standard.string(forKey: key)
    }
}
