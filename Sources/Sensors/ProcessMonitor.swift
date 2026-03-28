import Foundation

/// Monitor process-level CPU and memory usage.
///
/// Reads from:
/// - ProcessInfo (overall system stats)
/// - getrusage (per-process CPU time)
/// - kern.proc.pid (process info via sysctl)
///
/// Provides:
/// - Top 5 processes by CPU %
/// - Top 5 processes by memory
/// - Individual process details
enum ProcessMonitor {
    
    /// Process information snapshot.
    struct ProcessInfo: Identifiable, Sendable {
        let id = UUID()
        let pid: pid_t
        let name: String
        let cpuPercent: Double
        let memoryMB: UInt64
        let state: ProcessState
    }
    
    /// Process state enum.
    enum ProcessState: String, Sendable {
        case running
        case stopped
        case zombie
        case sleeping
        case unknown
    }
    
    /// Get top N processes by CPU percentage.
    ///
    /// - Parameter count: Number of top processes to return (default: 5)
    /// - Returns: Array of ProcessInfo sorted by CPU % (descending)
    static func topProcessesByCPU(count: Int = 5) -> [ProcessInfo] {
        // Placeholder: actual implementation would:
        // 1. Iterate all running processes
        // 2. Call getrusage to get CPU time
        // 3. Calculate CPU % from user_time + system_time
        // 4. Sort by CPU % and return top N
        
        return [
            ProcessInfo(pid: 1, name: "Finder", cpuPercent: 15.3, memoryMB: 256, state: .running),
            ProcessInfo(pid: 2, name: "Xcode", cpuPercent: 45.2, memoryMB: 2048, state: .running),
        ]
    }
    
    /// Get top N processes by memory usage.
    ///
    /// - Parameter count: Number of top processes to return (default: 5)
    /// - Returns: Array of ProcessInfo sorted by memory (descending)
    static func topProcessesByMemory(count: Int = 5) -> [ProcessInfo] {
        // Placeholder
        return [
            ProcessInfo(pid: 2, name: "Xcode", cpuPercent: 45.2, memoryMB: 2048, state: .running),
            ProcessInfo(pid: 1, name: "Finder", cpuPercent: 15.3, memoryMB: 256, state: .running),
        ]
    }
    
    /// Get all running processes.
    ///
    /// - Returns: Array of all ProcessInfo (unordered)
    static func allProcesses() -> [ProcessInfo] {
        // Placeholder
        return []
    }
    
    /// Get detailed info for a specific process.
    ///
    /// - Parameter pid: Process ID
    /// - Returns: ProcessInfo if found, nil otherwise
    static func processInfo(for pid: pid_t) -> ProcessInfo? {
        // Placeholder
        return nil
    }
    
    /// Force-quit a process.
    ///
    /// - Parameter pid: Process ID
    /// - Returns: true if successful, false otherwise
    /// - Note: Requires user approval or elevated privilege
    static func forceQuit(_ pid: pid_t) -> Bool {
        // Would use kill(2) system call
        return false
    }
}
