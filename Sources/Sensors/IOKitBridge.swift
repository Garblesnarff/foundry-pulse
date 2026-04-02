import Foundation
import IOKit

/// Thin wrapper around IOKit C APIs for hardware sensor access.
///
/// Reads:
/// - CPU/GPU/storage temperatures
/// - Fan speeds
/// - Power metrics
///
/// Note: IOKit usage is error-prone; always check return codes.
/// Missing sensors should not cause crashes (graceful degradation).
///
/// Reference: https://developer.apple.com/documentation/iokit
enum IOKitBridge {
    
    /// Read CPU temperature (P-cores + E-cores for M-series).
    ///
    /// Keys (SMC):
    /// - TC0F (or TC0X for package temp)
    /// - TP0F / TP1F (P-core)
    /// - TE0F / TE1F (E-core)
    static func readCPUTemperature() -> Double? {
        // Placeholder: actual implementation would use IOKit registry
        // to find temperature sensor nodes and read their values.
        //
        // Example pattern:
        // 1. IOServiceMatching("IOHWSensors") → find sensor service
        // 2. IORegistryEntryGetProperty(service, "Temperature") → read value
        // 3. Convert raw value to Celsius
        //
        // For now, return nil (fallback in SensorMonitor)
        return nil
    }
    
    /// Read GPU temperature.
    ///
    /// Key (SMC): TG0F
    static func readGPUTemperature() -> Double? {
        // Placeholder
        return nil
    }
    
    /// Read storage/SSD temperature.
    ///
    /// Key (SMC): Ts0F (typically)
    static func readStorageTemperature() -> Double? {
        // Placeholder
        return nil
    }
    
    /// Read fan speed (RPM).
    ///
    /// Keys (SMC): FS!# (e.g., FS!0, FS!1)
    static func readFanSpeed() -> Int? {
        // Placeholder
        return nil
    }
    
    /// Read all available sensor values.
    ///
    /// Returns a dictionary of sensor key → value pairs.
    static func readAllSensors() -> [String: Double] {
        var sensors: [String: Double] = [:]
        
        if let cpuTemp = readCPUTemperature() {
            sensors["cpu_temp"] = cpuTemp
        }
        if let gpuTemp = readGPUTemperature() {
            sensors["gpu_temp"] = gpuTemp
        }
        if let storageTemp = readStorageTemperature() {
            sensors["storage_temp"] = storageTemp
        }
        
        return sensors
    }
}

// MARK: - IOKit C Bridge (Placeholder)

/// C bridge functions for IOKit (would be implemented in bridging header or separate .m file).
///
/// Example structure (not functional in this placeholder):
/// ```c
/// kern_return_t io_read_temperature(io_registry_entry_t entry, double *temp_out) {
///     CFNumberRef temp_ref = IORegistryEntrySearchCFProperty(
///         entry,
///         kIOServicePlane,
///         CFSTR("Temperature"),
///         kCFAllocatorDefault,
///         kIORegistryIterateRecursively
///     );
///     if (temp_ref) {
///         CFNumberGetValue(temp_ref, kCFNumberDoubleType, temp_out);
///         CFRelease(temp_ref);
///         return KERN_SUCCESS;
///     }
///     return KERN_FAILURE;
/// }
/// ```
///
/// For production, implement in FoundryPulse-Bridging-Header.h or in a separate .m file.
