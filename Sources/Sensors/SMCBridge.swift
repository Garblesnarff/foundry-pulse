import Foundation

/// Bridge to System Management Controller (SMC) for temperature and power data.
///
/// The SMC is a low-level controller on Apple Silicon Macs that manages:
/// - Temperature sensors (CPU, GPU, storage, memory)
/// - Fan speeds
/// - Power state and throttling
/// - Battery health
///
/// Access requires either:
/// 1. App entitlement: com.apple.security.device.usb
/// 2. Helper tool with elevated privilege (SMJobBless)
/// 3. Direct /dev/io access (deprecated, may require SIP bypass)
///
/// Reference:
/// - https://github.com/Apple-Fabric/smckit (third-party SMC wrapper)
/// - Apple Developer: System Management Controller
///
/// Note: Gracefully handle failures; SMC access may be restricted on some systems.
enum SMCBridge {
    
    /// Read a single SMC key (e.g., "TC0F" for CPU temp).
    ///
    /// SMC keys are 4-character codes. Common keys:
    /// - TC0F / TC0X: CPU die temperature (°C)
    /// - TG0F: GPU core temperature (°C)
    /// - Tm0F: Memory temperature (°C)
    /// - FS!#: Fan speed (RPM, # = 0-3)
    /// - TC0E / TC0W: Thermal state flags
    ///
    /// - Parameter key: 4-character SMC key code
    /// - Returns: Decoded value, or nil if unavailable
    static func read(key: String) -> SMCValue? {
        guard key.count == 4 else { return nil }
        
        // Placeholder: actual implementation would:
        // 1. Open /dev/io socket
        // 2. Call IOConnectCallStructMethod with key
        // 3. Decode result based on key's data type
        //
        // Example (pseudo-code):
        // ```
        // io_connect_t conn = IOConnectOpen(service);
        // kern_return_t kr = IOConnectCallStructMethod(
        //     conn,
        //     kSMCReadKey,
        //     &key,
        //     sizeof(key),
        //     &result,
        //     &result_size
        // );
        // IOConnectClose(conn);
        // ```
        
        return nil
    }
    
    /// Read CPU temperature (package or die).
    ///
    /// Tries multiple key variations (TC0F, TC0X, TC0E).
    static func readCPUTemperature() -> Double? {
        // Try multiple key variants
        for key in ["TC0F", "TC0X", "TC0E"] {
            if let value = read(key: key), case .fpe2(let temp) = value {
                return temp
            }
        }
        return nil
    }
    
    /// Read GPU temperature.
    ///
    /// Key: TG0F (GPU core)
    static func readGPUTemperature() -> Double? {
        guard let value = read(key: "TG0F") else { return nil }
        if case .fpe2(let temp) = value {
            return temp
        }
        return nil
    }
    
    /// Read main fan speed (RPM).
    ///
    /// Key: FS!0 (first fan; FS!1, FS!2, FS!3 for additional fans)
    static func readFanSpeed() -> Int? {
        guard let value = read(key: "FS!0") else { return nil }
        if case .fpe2(let rpm) = value {
            return Int(rpm)
        }
        return nil
    }
    
    /// Check thermal state (power-limited, thermal-limited, etc.).
    ///
    /// Returns a ThermalState enum based on SMC flags.
    static func readThermalState() -> ThermalState {
        // Placeholder: would read thermal state flags from SMC
        // and return appropriate ThermalState
        return .nominal
    }
    
    /// Read battery health (cycle count, condition, etc.).
    ///
    /// Note: Actual battery data is in /var/log/system.log or via IOKit.
    /// SMC has limited battery info; prefer IOKit for detailed battery data.
    static func readBatteryHealth() -> BatteryHealth {
        // Placeholder
        return .good
    }
}

// MARK: - SMC Data Types

/// SMC value types (decoded from 4-byte SMC response).
///
/// SMC keys return data in various formats:
/// - "fpe2": Fixed-point 8.8 (temperature, voltage)
/// - "{fpe": Apple-specific fixed-point variant
/// - "ui8": Unsigned 8-bit integer
/// - "ui16": Unsigned 16-bit integer
/// - "ui32": Unsigned 32-bit integer
/// - "ch8": ASCII character
/// - "flag": Boolean flag
enum SMCValue {
    /// Fixed-point 8.8 (typical for temps: 65.125°C)
    case fpe2(Double)
    
    /// Unsigned integer
    case uint(UInt32)
    
    /// ASCII character
    case char(UInt8)
    
    /// Boolean flag
    case flag(Bool)
    
    /// Raw bytes (4 bytes)
    case raw([UInt8])
    
    /// Decode a 4-byte SMC response into appropriate type.
    ///
    /// - Parameter bytes: 4-byte SMC response
    /// - Parameter typeCode: SMC key's data type (e.g., "fpe2")
    /// - Returns: Decoded SMCValue, or nil if decoding fails
    static func decode(bytes: [UInt8], typeCode: String) -> SMCValue? {
        guard bytes.count == 4 else { return nil }
        
        switch typeCode {
        case "fpe2":
            // Fixed-point 8.8: MSB is integer, LSB is fraction
            let int8 = Int8(bitPattern: bytes[0])
            let frac8 = bytes[1]
            let value = Double(int8) + Double(frac8) / 256.0
            return .fpe2(value)
            
        case "{fpe":
            // Apple fixed-point variant
            let int16 = Int16(bigEndian: Int16(bytes: bytes[0..<2]))
            let frac16 = UInt16(bigEndian: UInt16(bytes: bytes[2..<4]))
            let value = Double(int16) + Double(frac16) / 65536.0
            return .fpe2(value)
            
        case "ui8":
            return .uint(UInt32(bytes[0]))
            
        case "ui16":
            let val = UInt16(bigEndian: UInt16(bytes: bytes[0..<2]))
            return .uint(UInt32(val))
            
        case "ui32":
            let val = UInt32(bigEndian: UInt32(bytes: bytes[0..<4]))
            return .uint(val)
            
        case "ch8":
            return .char(bytes[0])
            
        case "flag":
            return .flag(bytes[0] != 0)
            
        default:
            return .raw(bytes)
        }
    }
}

// MARK: - Helper Extensions

extension Int16 {
    init(bytes: ArraySlice<UInt8>) {
        guard bytes.count == 2 else {
            self = 0
            return
        }
        let unsigned = (UInt16(bytes[bytes.startIndex]) << 8) | UInt16(bytes[bytes.startIndex + 1])
        self = Int16(bitPattern: unsigned)
    }
}

extension UInt16 {
    init(bytes: ArraySlice<UInt8>) {
        guard bytes.count == 2 else {
            self = 0
            return
        }
        self = (UInt16(bytes[bytes.startIndex]) << 8) | UInt16(bytes[bytes.startIndex + 1])
    }
}

extension UInt32 {
    init(bytes: ArraySlice<UInt8>) {
        guard bytes.count == 4 else {
            self = 0
            return
        }
        self = (UInt32(bytes[bytes.startIndex]) << 24)
            | (UInt32(bytes[bytes.startIndex + 1]) << 16)
            | (UInt32(bytes[bytes.startIndex + 2]) << 8)
            | UInt32(bytes[bytes.startIndex + 3])
    }
}
