import Foundation
import Combine
import Darwin
import IOKit
import IOKit.ps

/// Main sensor polling orchestrator.
///
/// Observable class that maintains current sensor readings and manages background polling loop.
/// Reads from ProcessInfo (CPU, memory, disk), IOKit (temperatures, fans), and SMC.
///
/// Usage:
/// ```swift
/// @ObservedObject var sensorMonitor = SensorMonitor(pollingInterval: 2.0)
/// let cpuPercent = sensorMonitor.currentReading.cpuPercent
/// ```
///
/// Thread Safety:
/// - Polling happens on background queue (DispatchQueue.global(qos: .userInitiated))
/// - Updates published to main thread for UI binding
/// - Ring buffer is thread-safe (atomic access)
final class SensorMonitor: NSObject, ObservableObject {
    // MARK: - Published Properties

    /// Current sensor reading (updated every pollingInterval seconds)
    @Published var currentReading: SensorReading = .default

    /// Historical readings (ring buffer: 30 samples = 1 minute at 2s interval)
    @Published var history: [SensorReading] = []

    /// Last error encountered
    @Published var lastError: SensorError? = nil

    /// Is polling currently active?
    @Published var isPolling: Bool = false
    
    // MARK: - Configuration
    
    var pollingInterval: TimeInterval = 2.0 {
        didSet {
            if isPolling {
                stopPolling()
                startPolling()
            }
        }
    }
    
    private let ringBufferCapacity = 30  // 1 minute at 2s interval
    private var ringBuffer: [SensorReading] = []
    private var ringBufferLock = NSLock()
    
    // MARK: - Polling Control
    
    private var pollingQueue = DispatchQueue(label: "com.foundry.pulse.sensors", qos: .userInitiated)
    private var pollingTimer: Timer?
    private let cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(pollingInterval: TimeInterval = 2.0) {
        super.init()
        self.pollingInterval = pollingInterval
        forgeLog("Sensor monitor initialized (interval: \(pollingInterval)s)")
    }
    
    deinit {
        stopPolling()
    }
    
    // MARK: - Polling Lifecycle
    
    /// Start background polling loop.
    func startPolling() {
        guard !isPolling else { return }
        
        isPolling = true
        forgeLog("Reading vitals...")
        
        // Poll immediately on first run
        pollOnce()
        
        // Schedule recurring polls
        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            self?.pollOnce()
        }
    }
    
    /// Stop background polling loop.
    func stopPolling() {
        guard isPolling else { return }
        
        isPolling = false
        pollingTimer?.invalidate()
        pollingTimer = nil
        
        forgeLog("Sensors offline.")
    }
    
    // MARK: - Polling Implementation
    
    private func pollOnce() {
        pollingQueue.async { [weak self] in
            self?.performPoll()
        }
    }
    
    private func performPoll() {
        do {
            let reading = try SensorReading(timestamp: Date())
            
            // Update current reading on main thread
            DispatchQueue.main.async {
                self.currentReading = reading
                self.addToHistory(reading)
                self.lastError = nil
            }
        } catch let error as SensorError {
            DispatchQueue.main.async {
                self.lastError = error
                forgeLog("Sensor error: \(error.localizedDescription)")
            }
        } catch {
            let sensorError = SensorError.unknownError(error.localizedDescription)
            DispatchQueue.main.async {
                self.lastError = sensorError
                forgeLog("Sensor error: \(error.localizedDescription)")
            }
        }
    }
    
    private func addToHistory(_ reading: SensorReading) {
        ringBufferLock.withLock {
            ringBuffer.append(reading)
            if ringBuffer.count > ringBufferCapacity {
                ringBuffer.removeFirst()
            }
            self.history = ringBuffer
        }
    }
    
    // MARK: - Data Access
    
    /// Get historical data for a specific metric.
    /// - Parameter duration: Time window (1 minute, 1 hour, or 24 hours)
    /// - Returns: Array of data points suitable for charting
    func getHistoricalData(for metric: Metric, duration: ChartDuration) -> [ChartPoint] {
        ringBufferLock.withLock {
            let filtered = ringBuffer.map { reading -> ChartPoint in
                let value: Double
                switch metric {
                case .cpu:
                    value = reading.cpuPercent
                case .gpu:
                    value = reading.gpuPercent
                case .memory:
                    value = Double(reading.memoryUsedMB) / 1024.0  // Convert to GB
                case .disk:
                    value = reading.diskUsedPercent
                }
                
                return ChartPoint(timestamp: reading.timestamp, value: value)
            }
            
            return filtered
        }
    }
    
    /// Get average of metric over a time window.
    func getAverageValue(for metric: Metric, minutes: Int) -> Double? {
        ringBufferLock.withLock {
            let now = Date()
            let cutoff = now.addingTimeInterval(-TimeInterval(minutes * 60))
            
            let filtered = ringBuffer.filter { $0.timestamp >= cutoff }
            guard !filtered.isEmpty else { return nil }
            
            let sum = filtered.reduce(0.0) { sum, reading -> Double in
                let value: Double
                switch metric {
                case .cpu:
                    value = reading.cpuPercent
                case .gpu:
                    value = reading.gpuPercent
                case .memory:
                    value = Double(reading.memoryUsedMB)
                case .disk:
                    value = reading.diskUsedPercent
                }
                return sum + value
            }
            
            return sum / Double(filtered.count)
        }
    }
}

// MARK: - Data Models

/// Single sensor reading snapshot.
struct SensorReading: Codable, Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    
    // CPU
    let cpuPercent: Double
    let cpuCoreCount: Int
    let cpuTempCelsius: Double?
    
    // GPU
    let gpuPercent: Double
    let gpuTempCelsius: Double?
    
    // Memory
    let memoryUsedMB: UInt64
    let memoryTotalMB: UInt64
    let memoryPressurePercent: Double
    let swapUsedMB: UInt64
    
    // Disk
    let diskUsedPercent: Double
    let diskReadMBs: Double
    let diskWriteMBs: Double
    
    // Network
    let networkUpMbps: Double
    let networkDownMbps: Double
    
    // Battery
    let batteryPercent: Int
    let batteryHealth: BatteryHealth
    let batteryTimeToEmpty: TimeInterval?
    
    // Thermal
    let fanRPM: Int?
    let thermalState: ThermalState
    
    // System info
    let systemChipName: String
    let systemRAMGB: Int
    let systemOSVersion: String
    
    init(timestamp: Date = Date()) throws {
        self.id = UUID()
        self.timestamp = timestamp
        
        // Initialize with actual system data
        let processInfo = ProcessInfo.processInfo
        
        // CPU - get from host CPU load
        self.cpuPercent = SensorReading.getCPULoad()
        self.cpuCoreCount = processInfo.activeProcessorCount
        self.cpuTempCelsius = IOKitBridge.readCPUTemperature()  // Real IOKit call

        // GPU - use CPU load as proxy (real GPU % needs Metal GPU profiler)
        self.gpuPercent = SensorReading.getGPULoad()  // Placeholder - real GPU metrics need Metal
        self.gpuTempCelsius = IOKitBridge.readGPUTemperature()  // Real IOKit call

        // Memory - use ProcessInfo and mach_task_info
        let memoryInfo = SensorReading.getMemoryInfo()
        self.memoryUsedMB = memoryInfo.usedMB
        self.memoryTotalMB = memoryInfo.totalMB
        self.memoryPressurePercent = memoryInfo.pressure
        self.swapUsedMB = memoryInfo.swapMB

        // Disk - use FileManager for used space
        let diskInfo = SensorReading.getDiskInfo()
        self.diskUsedPercent = diskInfo.usedPercent
        self.diskReadMBs = diskInfo.readMBps  // Placeholder - real I/O needs IOKit
        self.diskWriteMBs = diskInfo.writeMBps

        // Network - use getifaddrs for network statistics
        let networkInfo = SensorReading.getNetworkInfo()
        self.networkUpMbps = networkInfo.upMbps
        self.networkDownMbps = networkInfo.downMbps

        // Battery - use IOKit power source info
        let batteryInfo = SensorReading.getBatteryInfo()
        self.batteryPercent = batteryInfo.percent
        self.batteryHealth = batteryInfo.health
        self.batteryTimeToEmpty = batteryInfo.timeToEmpty

        // Thermal - use SMC/IOKit
        self.fanRPM = IOKitBridge.readFanSpeed()  // Real IOKit call
        self.thermalState = SensorReading.getThermalState()

        // System info
        self.systemChipName = SensorReading.getChipName()
        self.systemRAMGB = Int(Double(processInfo.physicalMemory) / (1024.0 * 1024.0 * 1024.0))
        self.systemOSVersion = processInfo.operatingSystemVersionString
    }
    
    // MARK: - Real System Data Collection
    
    private static var previousCPUInfo: host_cpu_load_info?
    private static var previousNetworkBytes: (up: UInt64, down: UInt64)?
    private static var previousDiskBytes: (read: UInt64, write: UInt64)?
    private static var lastCollectionTime: Date = Date()
    
    private static func getCPULoad() -> Double {
        var cpuLoadInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        
        let kr = withUnsafeMutablePointer(to: &cpuLoadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        
        guard kr == KERN_SUCCESS else {
            return 0
        }
        
        let user = Double(cpuLoadInfo.cpu_ticks.0)
        let system = Double(cpuLoadInfo.cpu_ticks.1)
        let idle = Double(cpuLoadInfo.cpu_ticks.2)
        let nice = Double(cpuLoadInfo.cpu_ticks.3)
        
        // Calculate delta if we have previous data
        if let previous = SensorReading.previousCPUInfo {
            let prevUser = Double(previous.cpu_ticks.0)
            let prevSystem = Double(previous.cpu_ticks.1)
            let prevIdle = Double(previous.cpu_ticks.2)
            let prevNice = Double(previous.cpu_ticks.3)
            
            let userDelta = user - prevUser
            let systemDelta = system - prevSystem
            let idleDelta = idle - prevIdle
            let niceDelta = nice - prevNice
            
            let totalDelta = userDelta + systemDelta + idleDelta + niceDelta
            if totalDelta > 0 {
                let used = userDelta + systemDelta + niceDelta
                SensorReading.previousCPUInfo = cpuLoadInfo
                return (used / totalDelta) * 100
            }
        }
        
        SensorReading.previousCPUInfo = cpuLoadInfo
        return 0
    }
    
    private static func getGPULoad() -> Double {
        // GPU load is complex to read on Apple Silicon without Metal
        // Use a simple estimation based on CPU load for now
        // Real implementation would use MTLDevice.gpuUsage()
        return getCPULoad() * 0.5  // Estimate GPU at ~50% of CPU load
    }
    
    private struct MemoryInfo {
        var usedMB: UInt64 = 0
        var totalMB: UInt64 = 0
        var pressure: Double = 0
        var swapMB: UInt64 = 0
    }
    
    private static func getMemoryInfo() -> MemoryInfo {
        var info = MemoryInfo()
        
        let processInfo = ProcessInfo.processInfo
        let totalMemory = processInfo.physicalMemory
        info.totalMB = UInt64(totalMemory / (1024 * 1024))
        
        // Get memory usage via host_statistics64
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let kr = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        if kr == KERN_SUCCESS {
            let pageSize = UInt64(vm_page_size)
            let active = UInt64(vmStats.active_count) * pageSize
            let wired = UInt64(vmStats.wire_count) * pageSize
            let compressed = UInt64(vmStats.compressor_page_count) * pageSize
            
            // Used memory = active + wired + compressed
            let usedBytes = active + wired + compressed
            info.usedMB = usedBytes / (1024 * 1024)
            info.pressure = (Double(usedBytes) / Double(totalMemory)) * 100
            
            // Swap usage via sysctl
            var swapUsage = xsw_usage()
            var swapSize = MemoryLayout<xsw_usage>.size
            if sysctlbyname("vm.swapusage", &swapUsage, &swapSize, nil, 0) == 0 {
                info.swapMB = swapUsage.xsu_used / (1024 * 1024)
            }
        }
        
        return info
    }
    
    private struct DiskInfo {
        var usedPercent: Double = 0
        var readMBps: Double = 0
        var writeMBps: Double = 0
    }
    
    private static func getDiskInfo() -> DiskInfo {
        var info = DiskInfo()
        
        // Get disk usage for root filesystem
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: "/")
            if let totalSize = attrs[.systemSize] as? UInt64,
               let freeSize = attrs[.systemFreeSize] as? UInt64 {
                let total = Double(totalSize)
                let free = Double(freeSize)
                let used = total - free
                info.usedPercent = (used / total) * 100
            }
        } catch {
            info.usedPercent = 0
        }
        
        return info
    }
    
    private struct NetworkInfo {
        var upMbps: Double = 0
        var downMbps: Double = 0
    }
    
    private static func getNetworkInfo() -> NetworkInfo {
        var info = NetworkInfo()
        
        // Get network interface statistics
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return info
        }
        
        defer { freeifaddrs(ifaddr) }
        
        var totalUp: UInt64 = 0
        var totalDown: UInt64 = 0
        
        var ptr = firstAddr
        while true {
            let name = String(cString: ptr.pointee.ifa_name)
            
            // Skip loopback and non-internet interfaces
            if name.hasPrefix("en") || name.hasPrefix("pdp_ip") {
                if let data = ptr.pointee.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                    totalUp += UInt64(networkData.ifi_obytes)
                    totalDown += UInt64(networkData.ifi_ibytes)
                }
            }
            
            guard let next = ptr.pointee.ifa_next else { break }
            ptr = next
        }
        
        // Calculate rate
        let now = Date()
        let elapsed = now.timeIntervalSince(SensorReading.lastCollectionTime)
        
        if let previous = SensorReading.previousNetworkBytes, elapsed > 0 {
            let upDelta = totalUp > previous.up ? totalUp - previous.up : 0
            let downDelta = totalDown > previous.down ? totalDown - previous.down : 0
            
            // Convert to Mbps
            info.upMbps = Double(upDelta) * 8 / elapsed / 1_000_000
            info.downMbps = Double(downDelta) * 8 / elapsed / 1_000_000
            
            SensorReading.previousNetworkBytes = (totalUp, totalDown)
        } else {
            SensorReading.previousNetworkBytes = (totalUp, totalDown)
        }
        
        SensorReading.lastCollectionTime = now
        return info
    }
    
    private struct BatteryInfo {
        var percent: Int = 0
        var health: BatteryHealth = .unknown
        var timeToEmpty: TimeInterval? = nil
    }
    
    private static func getBatteryInfo() -> BatteryInfo {
        var info = BatteryInfo()
        
        // Use IOKit to get battery info
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]
        
        for source in sources {
            if let desc = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                if let type = desc[kIOPSTypeKey as String] as? String, type == kIOPSInternalBatteryType {
                    // Current capacity
                    if let capacity = desc[kIOPSCurrentCapacityKey as String] as? Int {
                        info.percent = capacity
                    }
                    
                    // Time to empty (in minutes)
                    if let time = desc[kIOPSTimeToEmptyKey as String] as? Int, time > 0 {
                        info.timeToEmpty = TimeInterval(time * 60)
                    }
                    
                    // Battery health - use max capacity vs design capacity
                    if let maxCap = desc[kIOPSMaxCapacityKey as String] as? Int,
                       let designCap = desc["DesignCapacity"] as? Int, designCap > 0 {
                        let healthPercent = Double(maxCap) / Double(designCap) * 100
                        if healthPercent >= 80 {
                            info.health = .excellent
                        } else if healthPercent >= 60 {
                            info.health = .good
                        } else if healthPercent >= 40 {
                            info.health = .fair
                        } else {
                            info.health = .poor
                        }
                    } else {
                        info.health = .unknown
                    }
                }
            }
        }
        
        return info
    }
    
    private static func getThermalState() -> ThermalState {
        // Use ProcessInfo thermal state
        switch ProcessInfo.processInfo.thermalState {
        case .nominal:
            return .nominal
        case .fair:
            return .powerLimited
        case .serious:
            return .thermalLimited
        case .critical:
            return .critical
        @unknown default:
            return .nominal
        }
    }
    
    private static func getChipName() -> String {
        // Get chip name from sysctl
        var size: Int = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        
        var brand = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &brand, &size, nil, 0)
        
        let chipString = String(cString: brand)
        
        // Parse to get simple name (M1, M2, M3, M4)
        if chipString.contains("M4") {
            return "Apple M4"
        } else if chipString.contains("M3") {
            return "Apple M3"
        } else if chipString.contains("M2") {
            return "Apple M2"
        } else if chipString.contains("M1") {
            return "Apple M1"
        }
        
        return chipString.isEmpty ? "Apple Silicon" : chipString
    }
    
    static let `default` = try! SensorReading()
}

/// Thermal state enum.
enum ThermalState: String, Codable, Sendable {
    case nominal
    case powerLimited  // SMC power limiting
    case thermalLimited  // SMC thermal limiting
    case critical
}

/// Battery health status.
enum BatteryHealth: String, Codable, Sendable {
    case excellent
    case good
    case fair
    case poor
    case unknown
}

/// Sensor error types.
enum SensorError: LocalizedError, Sendable {
    case ioKitFailed(String)
    case smcFailed(String)
    case memoryReadFailed
    case diskReadFailed
    case networkReadFailed
    case batteryReadFailed
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .ioKitFailed(let reason):
            return "IOKit error: \(reason)"
        case .smcFailed(let reason):
            return "SMC error: \(reason)"
        case .memoryReadFailed:
            return "Could not read memory metrics"
        case .diskReadFailed:
            return "Could not read disk metrics"
        case .networkReadFailed:
            return "Could not read network metrics"
        case .batteryReadFailed:
            return "Could not read battery status"
        case .unknownError(let reason):
            return "Unknown sensor error: \(reason)"
        }
    }
}

// MARK: - Charting Models

/// Metric types for historical charting.
enum Metric: String, CaseIterable, Sendable {
    case cpu = "CPU %"
    case gpu = "GPU %"
    case memory = "Memory GB"
    case disk = "Disk %"
}

/// Chart duration presets.
enum ChartDuration: String, CaseIterable, Sendable {
    case oneMinute = "1 min"
    case oneHour = "1 hr"
    case twentyFourHours = "24 hr"
    
    var timeInterval: TimeInterval {
        switch self {
        case .oneMinute:
            return 60
        case .oneHour:
            return 3600
        case .twentyFourHours:
            return 86400
        }
    }
}

/// Single data point for charting.
struct ChartPoint: Identifiable, Sendable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}

// MARK: - Network Interface Structures

// if_data structure from ifaddrs.h
struct if_data {
    var ifi_type: UInt8
    var ifi_typelen: UInt8
    var ifi_physical: UInt8
    var ifi_addrlen: UInt8
    var ifi_hdrlen: UInt8
    var ifi_recvquota: UInt8
    var ifi_xmitquota: UInt8
    var ifi_unused1: UInt8
    var ifi_mtu: UInt32
    var ifi_metric: UInt32
    var ifi_baudrate: UInt32
    var ifi_ipackets: UInt32
    var ifi_ierrors: UInt32
    var ifi_opackets: UInt32
    var ifi_oerrors: UInt32
    var ifi_collisions: UInt32
    var ifi_ibytes: UInt64
    var ifi_obytes: UInt64
    var ifi_imcasts: UInt32
    var ifi_omcasts: UInt32
    var ifi_iqdrops: UInt32
    var ifi_noproto: UInt32
    var ifi_recvtap: UInt32
    var ifi_xmittap: UInt32
    var ifi_unused2: UInt32
    var ifi_hwassist: UInt32
    var ifi_reserved1: UInt32
    var ifi_reserved2: UInt32
}

// MARK: - Thread-Safe Lock Extension

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
