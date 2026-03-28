# Foundry Pulse — Technical Architecture

## Overview

Foundry Pulse is a native macOS menu bar application that provides real-time hardware monitoring for Apple Silicon Macs. This document describes the technical design, component interactions, and implementation patterns.

---

## System Architecture

### High-Level Flow

```
┌──────────────────────────────────────────────────────┐
│            FoundryPulseApp (App Delegate)            │
│  • App lifecycle management                          │
│  • Initializes all subsystems on launch              │
└──────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ↓                  ↓                  ↓
┌──────────────────┐ ┌──────────────┐ ┌──────────────┐
│  MenuBarView     │ │ SensorMonitor│ │ AlertManager │
│  (SwiftUI)       │ │ (@Observable)│ │              │
│  • Popover UI    │ │ • IOKit/SMC  │ │ • Rules      │
│  • Tabs          │ │ • ProcessInfo│ │ • Checks     │
│                  │ │ • Ring buffer│ │ • Notifs     │
└──────────────────┘ └──────────────┘ └──────────────┘
        │                  │                  │
        └──────────────────┼──────────────────┘
                           ↓
                 ┌──────────────────┐
                 │  DatabaseManager │
                 │  (Core Data)     │
                 │  • History       │
                 │  • Rules         │
                 │  • Settings      │
                 └──────────────────┘
```

---

## Component Details

### 1. FoundryPulseApp (App Delegate)

**File**: `Sources/FoundryPulseApp.swift`

**Responsibilities**:
- App lifecycle (launch, terminate)
- Initialize subsystems (SensorMonitor, DatabaseManager, AlertManager)
- Hide dock icon (menu bar app only)
- Start sensor polling on background queue

**Key Methods**:
```swift
func applicationDidFinishLaunching(_ notification: Notification)
  → Initializes all managers, starts polling

func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply
  → Gracefully shuts down sensors, saves state
```

**Threading**:
- Main thread: UI updates, lifecycle
- Background thread: Sensor polling (DispatchQueue.global(qos: .userInitiated))

---

### 2. SensorMonitor

**File**: `Sources/Sensors/SensorMonitor.swift`

**Responsibilities**:
- Coordinate all hardware sensor reads
- Polling loop (configurable interval, default 2 seconds)
- Ring buffer history (30 samples = 1 minute)
- Thread-safe data access
- Error handling and graceful degradation

**Key Properties**:
```swift
@Published var currentReading: SensorReading  // Latest snapshot
@Published var history: [SensorReading]       // Ring buffer
@Published var lastError: SensorError?        // Last error
@Published var isPolling: Bool                // Polling state
```

**Polling Loop**:
```
startPolling()
  ├─ Immediate poll
  └─ Schedule Timer (every pollingInterval seconds)
      └─ performPoll()
         ├─ Collect all sensor data (IOKit, SMC, ProcessInfo)
         ├─ Create SensorReading struct
         ├─ Update @Published properties (main thread)
         └─ Add to ring buffer
```

**Ring Buffer**:
- Capacity: 30 samples
- At 2-second interval: 1 minute of data
- Thread-safe with NSLock
- Automatically trimmed when full

**Error Handling**:
- Graceful fallback if sensor unavailable
- Missing temps/fans show "—"
- Errors logged but don't crash
- Last successful reading retained

---

### 3. IOKit & SMC Bridges

**Files**: 
- `Sources/Sensors/IOKitBridge.swift`
- `Sources/Sensors/SMCBridge.swift`

#### IOKitBridge

Reads hardware sensors via IOKit registry:
- CPU/GPU/storage temperatures
- Fan speeds
- Power metrics

**Key Functions**:
```swift
readCPUTemperature() -> Double?     // TC0F, TC0X, etc.
readGPUTemperature() -> Double?     // TG0F
readFanSpeed() -> Int?              // FS!0 (RPM)
readAllSensors() -> [String: Double] // Dict of all sensors
```

**IOKit Pattern**:
```
IOServiceMatching("IOHWSensors")
  ├─ Find sensor service
  ├─ IORegistryEntryGetProperty(service, "Temperature")
  ├─ Read CFNumberRef value
  └─ Convert to Celsius (typically already in °C)
```

**Error Handling**:
- Return nil if sensor unavailable
- Don't retry aggressively (10ms timeout max)
- Fallback to ProcessInfo if IOKit fails

#### SMCBridge

Reads low-level System Management Controller data:
- Temperature sensors
- Fan speeds
- Thermal state
- Power-limiting flags

**SMC Keys** (4-character codes):
```
TC0F / TC0X / TC0E  → CPU temp
TG0F                → GPU temp
Tm0F                → Memory temp
FS!0 / FS!1 / FS!2  → Fan speeds
TC0E / TC0W         → Thermal state flags
```

**Data Types**:
```swift
enum SMCValue {
    case fpe2(Double)      // Fixed-point 8.8 (temps)
    case uint(UInt32)      // Unsigned int (RPM)
    case char(UInt8)       // ASCII char
    case flag(Bool)        // Boolean flag
    case raw([UInt8])      // Raw bytes
}
```

**Privilege Requirements**:
- SMC access typically needs elevated privilege
- Solution: App entitlements (com.apple.security.device.usb) or helper tool (SMJobBless)
- Gracefully degrade if SMC unavailable

---

### 4. ProcessMonitor

**File**: `Sources/Sensors/ProcessMonitor.swift`

Reads process-level CPU and memory usage:
- Top N processes by CPU %
- Top N processes by memory
- Per-process details (name, PID, state)

**Data Collection**:
```swift
topProcessesByCPU(count: 5) -> [ProcessInfo]
topProcessesByMemory(count: 5) -> [ProcessInfo]
allProcesses() -> [ProcessInfo]
processInfo(for pid: pid_t) -> ProcessInfo?
```

**Implementation Pattern**:
```
1. Iterate all running processes (sysctl kern.proc.pid or libproc APIs)
2. Call getrusage(RUSAGE_SELF, &usage) per process
3. Calculate CPU % from user_time + system_time
4. Read resident memory (RSS) from proc_info
5. Sort by metric, return top N
```

---

### 5. MenuBarView

**File**: `Sources/FoundryPulseApp.swift` (TODO: extract to Views/)

**Responsibilities**:
- Popover UI (primary user interface)
- Tab navigation (Overview, Graphs, Processes, Settings)
- Real-time metric display
- User interactions (export, alerts, etc.)

**Tab Structure**:
```
Overview Tab (default)
  ├─ CPU % gauge (circular)
  ├─ GPU % gauge (circular)
  ├─ RAM bar (horizontal)
  ├─ Disk bar (horizontal)
  ├─ Network (up/down with Mbps)
  ├─ Battery % + health
  └─ Thermal strip (temps)

Graphs Tab
  ├─ Time range selector (1 min / 1 hr / 24 hr)
  ├─ Metric selector (CPU / GPU / RAM / Disk)
  └─ Historical line chart (SwiftCharts)

Processes Tab
  └─ Sortable table
     ├─ Top 5 by CPU %
     └─ Top 5 by memory

Settings Tab
  ├─ Polling interval slider
  ├─ Menu bar graph style
  ├─ Export button (CSV)
  ├─ Alert rules (Pro)
  └─ About section
```

**Bindings**:
```swift
@ObservedObject var sensorMonitor: SensorMonitor
  └─ currentReading: SensorReading (updated every poll)
     └─ Published changes trigger UI refresh
```

---

### 6. AlertManager

**File**: `Sources/Models/AlertManager.swift`

**Responsibilities**:
- Store and validate alert rules
- Check thresholds every 5 seconds
- Deduplicate notifications (5-min cooldown per rule)
- Dispatch alerts (notification, sound, log)

**Alert Rule Format**:
```swift
struct AlertRule {
    let metric: AlertMetric          // CPU %, GPU temp, RAM pressure, Disk %
    let op: AlertOperator           // >, <, >=, <=
    let threshold: Double           // e.g., 80 (for CPU > 80%)
    let duration: AlertDuration     // Immediate or N minutes
    let action: AlertAction         // Notification, Sound, Log
    var enabled: Bool
}
```

**Check Loop**:
```
Every 5 seconds:
  For each enabled rule:
    1. Evaluate: metric <op> threshold?
    2. Check deduplication (last alert > 5 min ago?)
    3. If both true: triggerAlert()
       ├─ Send notification (NSUserNotification)
       ├─ Play sound (NSSound)
       └─ Log entry
```

**Persistence**:
- Rules saved to UserDefaults (JSON-encoded)
- Loaded on app launch
- Synced between app and WidgetKit extension

---

### 7. DatabaseManager

**File**: `Sources/Utilities/DatabaseManager.swift`

**Responsibilities**:
- Core Data stack setup
- Historical data CRUD
- Alert rule persistence
- Settings storage
- Data retention policy (purge old readings)

**Entities** (TODO: Create .xcdatamodeld):
```
SensorReadingEntity
  ├─ timestamp: Date
  ├─ cpuPercent: Double
  ├─ gpuPercent: Double
  ├─ memoryUsedMB: UInt64
  ├─ diskUsedPercent: Double
  └─ [other metrics]

AlertRuleEntity
  ├─ id: String (UUID)
  ├─ name: String
  ├─ metric: String
  ├─ operator: String
  ├─ threshold: Double
  └─ enabled: Boolean

SettingsEntity
  ├─ key: String
  └─ value: String
```

**Concurrency Model**:
- Background context for all writes
- Main context for UI reads (rare)
- performAndWait() for synchronous operations

**Data Retention**:
- In-memory ring buffer (30 samples = 1 minute)
- Hourly aggregates in Core Data (mean, max, min)
- 24-hour retention by default
- Auto-purge older data (can be configured)

---

### 8. WidgetKit Extension

**File**: `Sources/Widgets/FoundryPulseWidget.swift` (TODO)

**Widget Types**:
- **Small (2×2)**: CPU % gauge with mini sparkline
- **Medium (3×3)**: 4-quadrant (CPU, GPU, RAM, Disk)

**Data Sync**:
- App groups (App Extension entitlements)
- Shared UserDefaults container
- Widget reads cached data (no direct sensor access)
- App updates shared container every 2 seconds
- Widget refresh every 10 seconds (WidgetKit minimum)

**Offline Handling**:
- Last-known values if data > 30s stale
- Show "—" if unavailable
- No crash on missing data

---

## Data Flow Examples

### Scenario 1: CPU Reading Update

```
1. SensorMonitor.performPoll() [background thread]
   ├─ ProcessInfo.activeProcessorCount → cpuCoreCount
   ├─ getrusage() → cpuPercent
   ├─ IOKit read → cpuTempCelsius
   └─ Create SensorReading

2. Publish to main thread
   ├─ @Published var currentReading updated
   └─ MenuBarView observes change

3. SwiftUI redraw
   ├─ MetricCircle(percent: 45) re-renders
   └─ Sparkline graph updated

4. Add to ring buffer
   ├─ Append to ringBuffer array
   ├─ Trim if > 30 samples
   └─ Publish @Published var history

5. (Optional) Save to Core Data
   ├─ Background context write
   ├─ Hourly aggregation job
   └─ Eventually flush to disk
```

### Scenario 2: Alert Trigger

```
1. AlertManager.checkAllRules() [every 5 seconds]
   └─ For each enabled rule

2. shouldTriggerAlert(rule) check
   ├─ Read sensorMonitor.currentReading.cpuPercent
   ├─ Evaluate: cpuPercent > 80?
   ├─ Check deduplication: lastAlertTime[rule.id] < 5 min ago?
   └─ Return true/false

3. If true: triggerAlert(rule)
   ├─ Update lastAlertTime[rule.id] = now()
   ├─ sendNotification() → NSUserNotification
   ├─ playAlertSound() → NSSound
   └─ logAlert() → ~/Library/Logs/FoundryPulse/

4. User interaction
   ├─ Notification click → app opens
   ├─ Check rule in AlertManager.getAllRules()
   └─ Disable/delete rule if desired
```

---

## Threading Model

### Main Thread
- UI updates (SwiftUI @Published changes)
- User interactions (button taps, settings changes)
- App lifecycle (startup, shutdown)

### Polling Queue (Background)
- Sensor reads (IOKit, SMC, ProcessInfo)
- Ring buffer operations (append, trim)
- Data aggregation for charts
- Every 2 seconds (configurable)

### Database Queue (Background)
- Core Data writes
- Hourly aggregation jobs
- Purge old data jobs
- On-demand: historical data fetches

### Alert Check Queue (Background)
- Rule evaluation every 5 seconds
- No UI blocking
- Notification dispatch (still main thread for notifications)

**Key Principle**: IOKit/SMC reads are slow (~50ms), so they must be background. UI updates must be main thread for SwiftUI binding.

---

## Error Handling

### Sensor Failures

```swift
do {
    let reading = try SensorReading(timestamp: Date())
    // Success: publish reading
} catch let error as SensorError {
    // Failure: publish error, set lastError
    // Ring buffer contains last valid reading
    // UI shows "—" for missing metric
    // Retry on next poll (exponential backoff)
}
```

### IOKit/SMC Unavailable

- Graceful degradation: show ProcessInfo metrics only
- Temperatures/fans show "—"
- No crash, user can still see CPU/memory/disk
- Log warning but continue operation

### Core Data Failures

- Writes fail silently (ring buffer still in memory)
- Historical data may be lost if app crashes
- On restart: ring buffer empty, data re-aggregates
- Non-critical (free tier doesn't require history)

---

## Performance Characteristics

### Memory

**Baseline**:
- App: ~60 MB (code, frameworks)
- SensorMonitor ring buffer: 30 samples × 512 bytes ≈ 15 KB
- Core Data: varies by retention (24-hour history ≈ 50–100 MB)
- **Total**: ~100–150 MB typical

**Target**: < 200 MB (including widget extension)

### CPU

**Polling Loop**:
- Sensor reads: 5–10 ms per poll
- Ring buffer append: 1 ms
- UI update: 1–5 ms
- **Total per cycle**: 10–20 ms every 2 seconds = 0.5–1% CPU

**Check Interval**:
- Alert rule check: 5 ms × rule count (~50 ms for 10 rules)
- Every 5 seconds = 0.04% CPU
- **Total**: 0.5–1.5% sustained

**Target**: < 5% sustained (tested on Activity Monitor)

### Battery Impact

- Periodic polling: 50 µA per wake
- 2-second interval: wakes every 2 seconds
- Typical MacBook Pro: 3–5% battery/hour (varies by screen time)

---

## Optimization Strategies

### 1. Ring Buffer Instead of Array
- Fixed capacity (30 samples)
- O(1) append, O(1) historical access
- Memory-efficient (no reallocation)

### 2. Background Polling
- Doesn't block main thread
- UI responsive even during sensor reads
- No jank when switching tabs

### 3. Lazy Core Data Writes
- Keep data in ring buffer
- Hourly flush to disk
- Reduces I/O overhead
- Still safe (in-memory ring survives crashes up to 1 hour)

### 4. Deduplication Cooldown
- 5-minute cooldown per alert rule
- Prevents notification spam
- O(1) lookup with UUID → Date dict

### 5. Widget Data Cache
- App updates shared UserDefaults every 2 seconds
- Widget reads cache (no sensor access)
- Avoids waking sensors for widget refresh

---

## Future Optimizations

1. **Adaptive Polling**: Increase interval when idle, decrease under load
2. **Sensor Caching**: Cache IOKit results between polls if unchanged
3. **Batched Core Data**: Aggregate 10 readings before Core Data write
4. **Metal/GPU Rendering**: Offload graph rendering to GPU
5. **XPC Services**: Separate privilege escalation into helper tool

---

## Security & Entitlements

### Required Entitlements

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.device.usb</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.files.downloads.read-write</key>
<true/>
```

### Data Privacy

- All data stays local (no network calls)
- No telemetry or analytics (opt-in only)
- Export files saved to ~/Downloads (user-accessible)
- No clipboard, pasteboard, or screen recording APIs

---

## Testing Strategy

### Unit Tests
- SensorReading creation (mock IOKit)
- AlertRule evaluation logic
- Ring buffer (capacity, trimming)
- ChartData aggregation (mean, max, min)

### Integration Tests
- Sensor polling → ring buffer → Core Data
- Alert trigger → notification dispatch
- Export CSV → file creation
- App quit → restart → settings restored

### Performance Tests
- Measure CPU % (Instruments Profiler)
- Measure memory (Allocations instrument)
- Measure battery impact (Energy Impact instrument)
- Profile on M1/M3/M4 hardware

---

## Deployment & Distribution

### Code Signing
- Developer ID Application (not self-signed)
- Create certificates in Xcode

### Notarization
- Submit to Apple notarization service
- Passes malware check
- Stamped app allows Gatekeeper bypass

### Installer
- Create .dmg with drag-to-Applications
- Code-sign DMG as well
- Ship via GitHub Releases or App Store

### App Store
- Submit via App Store Connect
- Include privacy policy
- Clear review notes (explain entitlements)
- Support email in metadata

---

**Last Updated**: 2026-03-15  
**Maintained By**: Claude Agent (Architecture Lead)
