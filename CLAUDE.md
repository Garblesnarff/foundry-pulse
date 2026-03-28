# Foundry Pulse — Native macOS Hardware Monitor

## What This Is

Foundry Pulse is a native macOS menu bar app that provides real-time hardware monitoring for M-series Apple Silicon Macs. It combines the simplicity of exelban's **Stats** with advanced graphing, alerting, and widgets to serve power users, developers, and gamers who need granular visibility into system performance.

**Key differentiator**: Stats exists and is solid, but lacks charting and alerts. Foundry Pulse adds professional-grade historical graphs, configurable thresholds, and desktop widgets—all while maintaining the lightweight menu bar aesthetic.

## Target Users

- **Developers**: Monitor CPU/RAM while compiling, debugging, profiling
- **Gamers**: Track GPU temps, fan speed, thermal throttling during sessions
- **Content Creators**: CPU/GPU load during rendering, export monitoring
- **Data Scientists**: RAM pressure, swap usage during model training
- **System Administrators**: Multi-user fleet monitoring via CSV export

## Core Features

### Tier 1: Free
- Menu bar popover with live data (CPU, GPU, RAM, disk, network, battery)
- System info (chip, RAM, OS version)
- Process list (top 5 CPU/RAM consumers)
- Historical graphs (1 min, 1 hr, 24 hr) for each metric
- Simple CSV export

### Tier 2: Pro ($4.99/year)
- Configurable alerts (CPU > 80%, GPU > 85°C, RAM pressure > 90%, disk > 95%)
- Desktop widgets (2x2 and 3x3 sizes)
- Advanced exports (JSON, with custom time ranges)
- Dark/light theme toggle persistence

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Platform** | macOS 13+ (M1–M4) | Apple Silicon native |
| **Language** | Swift 5.9 | Modern, performant |
| **UI Framework** | SwiftUI | Native, responsive menu bar |
| **Hardware Access** | IOKit | Sensor reading (temp, fan speed) |
| **SMC Access** | SMCKit (or custom bridging) | System Management Controller |
| **Graphing** | SwiftCharts | Native historical visualization |
| **Persistence** | UserDefaults + Core Data | Settings, alert rules, history |
| **Widgets** | WidgetKit | macOS 14+ desktop widgets |
| **Build Tool** | Xcode 15+ | Native Swift build system |

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│              FoundryPulseApp.swift                       │
│                (App Delegate)                            │
│  ┌─────────────────────────────────────────────────────┐ │
│  │     Menu Bar Controller (NSStatusBar)              │ │
│  │  • Popover management                              │ │
│  │  • Mini live graph (8x20 px)                       │ │
│  │  • Click to toggle popover                         │ │
│  └─────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
                        │
         ┌──────────────┴──────────────┐
         │                             │
         ▼                             ▼
    ┌─────────────────┐        ┌─────────────────┐
    │  SensorMonitor  │        │ MenuBar Popover │
    │  (Model Layer)  │        │  (SwiftUI View) │
    │                 │        │                 │
    │ • IOKit reader  │        │ • CPU/GPU/RAM   │
    │ • SMC bridge    │        │ • Graphs        │
    │ • Data polling  │        │ • Processes     │
    │ • Alerts        │        │ • Settings      │
    └────────┬────────┘        └─────────────────┘
             │
    ┌────────▼────────────────────────────┐
    │    Sensor Layers (IOKit/SMC)        │
    │                                     │
    │  ┌──────────────────────────────┐  │
    │  │ IOKit (Hardware Sensors)     │  │
    │  │ • CPU temps (P-cores/E-cores)│  │
    │  │ • GPU temp                   │  │
    │  │ • Fan speeds                 │  │
    │  │ • Power metrics              │  │
    │  └──────────────────────────────┘  │
    │  ┌──────────────────────────────┐  │
    │  │ SMC (System Mgmt Controller) │  │
    │  │ • Thermal throttling         │  │
    │  │ • Power state                │  │
    │  │ • Battery health             │  │
    │  └──────────────────────────────┘  │
    │  ┌──────────────────────────────┐  │
    │  │ Native APIs                  │  │
    │  │ • ProcessInfo (CPU %)        │  │
    │  │ • os_proc_available_memory   │  │
    │  │ • BSD vm_stat                │  │
    │  │ • IOKit disk I/O, network    │  │
    │  └──────────────────────────────┘  │
    └─────────────────────────────────────┘
             │
    ┌────────▼────────────────────────────┐
    │      Data Persistence               │
    │                                     │
    │  • UserDefaults (settings)          │
    │  • Core Data (history + alerts)     │
    │  • FileManager (CSV/JSON export)    │
    └─────────────────────────────────────┘
```

## Monitoring Metrics

### System-Level
- **CPU**: Overall %, per-core breakdown, thermal state (nominal/critical)
- **GPU**: %, temperature, power consumption
- **Memory**: Used/Total (GB), pressure %, swap usage, page faults
- **Disk**: Used/Total per volume (%), read/write throughput (MB/s)
- **Network**: Upload/Download speed (Mbps), packet loss
- **Battery**: % charge, time to empty/full, health, cycle count, condition

### Temperature & Thermal
- **Sensors**: CPU package temp, P-core temps, E-core temps, GPU temp, storage temp
- **Fan Speed**: RPM, duty cycle (%)
- **Throttling**: Thermal/power-limited state (yes/no)

### Process List
- Top 5 by CPU %
- Top 5 by resident memory (MB)
- Process name, PID, state

## Menu Bar Behavior

### Status Bar Item
- **Icon**: Forge-themed icon (anvil or spark)
- **Title**: Mini live graph (sparkline) of CPU or GPU % (user-selectable)
  - 8-sample rolling buffer, updated every 2 seconds
  - Colored based on utilization: green (0-50%), yellow (50-80%), red (80-100%)

### Popover (300×600 pt, resizable)
- **Header**: System name (e.g., "MacBook Pro 14" M3 Max") + elapsed time
- **Main Grid**:
  - Row 1: CPU (circular %), GPU (circular %)
  - Row 2: RAM (bar), Disk (bar)
  - Row 3: Network (up/down arrows + Mbps)
  - Row 4: Battery % + health indicator
  - Row 5: Temperature strip (CPU/GPU/storage)
  - Row 6: Tabs for Graphs, Processes, Settings

### Tabs in Popover
1. **Overview** (default): At-a-glance metrics
2. **Graphs**: Historical line charts (user-selectable 1 min / 1 hr / 24 hr)
3. **Processes**: Sortable table (CPU %, memory)
4. **Settings**: Preferences, alerts (Pro only), export

## Data Persistence & History

### Metric Recording
- Poll every 2 seconds (configurable)
- Retain 1-minute ring buffer (30 samples = 1 min)
- Hourly aggregation (mean/max) stored in Core Data
- 24-hour retention by default (configurable)

### Alerts (Pro Feature)
- Rule format: `if <metric> <operator> <threshold> for <duration>, then <action>`
- Supported metrics: CPU %, GPU temp, RAM pressure, disk used %
- Actions: Notification, sound, log, email (future)
- Rules persisted in Core Data
- Check every 5 seconds (after each poll)

## Widgets (Pro Feature)

### Widget Availability
- **macOS 14.0+** (Sonoma and later)
- **Size**: 2x2 (small) and 3x3 (medium)
- **Refresh**: Every 10 seconds (WidgetKit budget)

### Small Widget (2x2)
- Large CPU % with mini graph
- Optional: GPU temp

### Medium Widget (3x3)
- 4-quadrant layout: CPU, GPU, RAM, disk
- Each with live value + trend mini-graph
- Tap to open app

## Export Features

### Free Tier
- CSV export (timestamp, cpu %, ram mb, gpu %)
- Last 1 hour only

### Pro Tier
- CSV + JSON export
- Custom time range (1 hr – 30 days)
- All metrics included
- Auto-save to ~/Downloads/FoundryPulse-exports/

## Forge Language & Theming

### UI Language
| Action | Forge Language |
|--------|-----------------|
| App opening | "Reading vitals..." |
| Normal operation | "Pulse steady." |
| Alert triggered | "The forge overheats!" / "The forge drowns in memory!" |
| Popover shown | "Forge pulse online." |
| Settings saved | "Preferences forged." |
| Export complete | "Vitals exported." |

### Visual Theme
- Dark forge aesthetic: charcoal blacks (#141210), amber accents (#E8A849)
- Charts: amber lines on dark, smooth curves
- Thermal-aware color: green → yellow → red gradient for danger levels
- Smooth animations (0.3s easing) on metric changes

## Monetization

### Free Tier
- Core monitoring (all metrics)
- Historical graphs (24 hours)
- CSV export (basic)
- Process list

### Pro Tier ($4.99/year or $0.99 one-time)
- Configurable alerts (10 rules)
- WidgetKit integration
- Advanced export (JSON, custom range)
- Theme customization
- Email/webhook alerts (future)

### Implementation
- `StoreKit 2` for in-app purchase
- Entitlements: `com.foundry.pulse.pro`
- Check on app launch via `AppDelegate`

## File Structure

```
FoundryPulse/
├── FoundryPulseApp.swift          # App entry, NSApplication delegate
├── Sources/
│   ├── Sensors/
│   │   ├── SensorMonitor.swift    # Main polling orchestrator (ObservableObject)
│   │   ├── IOKitBridge.swift      # IOKit C wrapper
│   │   ├── SMCBridge.swift        # SMC reader (temp, fan)
│   │   ├── ProcessMonitor.swift   # Process list, CPU/RAM per-process
│   │   └── Models.swift           # SensorReading, AlertRule structs
│   ├── Views/
│   │   ├── MenuBarView.swift      # Status bar popover root
│   │   ├── OverviewTab.swift      # Main metrics grid
│   │   ├── GraphsTab.swift        # Historical line charts (SwiftCharts)
│   │   ├── ProcessesTab.swift     # Top CPU/RAM consumers table
│   │   ├── SettingsTab.swift      # Preferences, alerts, export
│   │   ├── Components/
│   │   │   ├── MetricCircle.swift # % gauges (CPU, GPU)
│   │   │   ├── MetricBar.swift    # Usage bars (RAM, disk)
│   │   │   ├── SparklineGraph.swift # Mini live graph (menu bar)
│   │   │   ├── HistoricalChart.swift # 1 min/1 hr/24 hr charts
│   │   │   └── ThermalStrip.swift   # Color-coded temp display
│   │   └── Modals/
│   │       ├── AlertRuleEditor.swift # Pro: create/edit rules
│   │       ├── ExportDialog.swift    # Date range + format picker
│   │       └── SettingsWindow.swift  # Persistent settings panel
│   ├── Widgets/
│   │   ├── FoundryPulseWidget.swift  # Widget entry & variants
│   │   ├── SmallWidget.swift         # 2x2 CPU gauge
│   │   └── MediumWidget.swift        # 3x3 quad layout
│   ├── Models/
│   │   ├── SensorData.swift          # @Observable data model
│   │   ├── AlertRule.swift           # Alert rule definition
│   │   ├── UserPreferences.swift      # Settings (theme, refresh rate)
│   │   └── ExportFormat.swift        # CSV/JSON structures
│   └── Utilities/
│       ├── ChartData.swift           # Data aggregation for charts
│       ├── Formatter.swift           # Number, temp, speed formatting
│       ├── DatabaseManager.swift     # Core Data CRUD
│       ├── AlertManager.swift        # Alert rule checking & notifications
│       └── Logger.swift              # Forge language logging
├── docs/
│   ├── ARCHITECTURE.md               # Deep technical dive
│   ├── DESIGN_SYSTEM.md              # Forge UI guidelines
│   ├── IOKit_NOTES.md                # IOKit sensor reading guide
│   ├── SMC_GUIDE.md                  # SMC access patterns
│   └── MONETIZATION.md               # StoreKit 2 integration
├── .gitignore
├── Package.swift                     # SPM manifest (if using)
├── Info.plist                        # App metadata, entitlements
└── README.md
```

## IOKit & SMC Integration

### IOKit (Hardware Sensors)

**Key APIs**:
- `IOServiceMatching` — Find temperature sensor nodes
- `IORegistryEntryGetProperty` — Read sensor values (kIOHWSensors family)
- `io_registry_entry_t` — Typed sensor handles

**Typical Sensor Paths**:
- CPU temps: `IOHWSensors/CPU_PN_CORE_TEMP`, `IOHWSensors/CPU_E_CORE_TEMP`
- GPU temp: `IOHWSensors/GPU_CORE_TEMP`
- Fan speed: `IOHWSensors/FAN_*_RPM`

### SMC (System Management Controller)

**Access Method**:
- Open `/dev/io` via `open()` (requires elevated privilege or entitlement `com.apple.security.device.usb`)
- Read via `IOConnectCallStructMethod` with key codes
- Avoid writing to SMC (risk of bricking SMC state)

**Common Keys**:
- `TC0F` — CPU die temp (°C)
- `TG0F` — GPU temp (°C)
- `Tm0P` — Memory temp (°C)
- `FS!#` — Fan speed (RPM)

### Important Notes

1. **Privilege**: Reading SMC typically requires elevated privilege. Consider:
   - App Sandbox with entitlements
   - Helper tool (SMJobBless) for elevated access
   - Fallback to IOKit-only data if SMC unavailable

2. **Error Handling**: IOKit calls frequently fail silently. Always check return codes and provide graceful degradation.

3. **Reliability**: Sensor readings can be stale or unavailable. Cache results with timestamps; don't retry aggressively.

## Progress & Phases

### Phase 1: Foundation (Week 1-2)
- SwiftUI menu bar app scaffold
- Basic ProcessInfo-based metrics (CPU %, RAM, disk)
- Popover UI (Overview tab)
- UserDefaults persistence for settings

### Phase 2: Advanced Sensors (Week 2-3)
- IOKit integration for temperatures, fan speeds
- SMC bridge (or SMCKit dependency)
- Thermal strip display
- Process list tab

### Phase 3: Graphing & History (Week 3-4)
- Core Data schema for historical metrics
- SwiftCharts integration (1 min / 1 hr / 24 hr views)
- Graphs tab with time range selector
- CSV export (free tier)

### Phase 4: Alerts & Pro Features (Week 4-5)
- Alert rule editor (Pro only)
- AlertManager with notification dispatch
- StoreKit 2 in-app purchase integration
- Settings tab with Pro upsell

### Phase 5: Widgets (Week 5-6)
- WidgetKit target (separate bundle)
- Small 2x2 widget (CPU gauge)
- Medium 3x3 widget (quad layout)
- Widget update via WidgetCenter

### Phase 6: Polish (Week 6+)
- Performance optimization (reduce IOKit polling overhead)
- Accessibility (VoiceOver support)
- Localization (EN first)
- App Store submission (signing + notarization)
- Documentation (user guide, technical specs)

## Key Implementation Decisions

1. **Polling Interval**: 2 seconds default (configurable 1–5s) balances responsiveness vs. battery/CPU overhead.

2. **Data Retention**: Ring buffer in memory (30 samples × 12 hours = ~360 hourly aggregates). Older data discarded to save space.

3. **IOKit Fallback**: If IOKit unavailable, show "—" for temps/fans; continue with ProcessInfo metrics.

4. **SMC Access**: Wrap in try/catch. If fails, use IOKit alternative (e.g., read `/dev/io` error gracefully).

5. **Widget Refresh**: WidgetKit 10-second minimum refresh. Accept stale data; prioritize low battery impact.

6. **Alert Checks**: Run every 5 seconds (not every poll) to reduce CPU. Check all rules sequentially; deduplicate notifications (no alert spam).

7. **Monetization**: Lightweight StoreKit 2 integration. Pro features are UI-gated (disabled in free tier). No data loss switching tiers.

## Legal & Licensing

- **Base Concept**: Inspired by exelban/stats (MIT License)
- **New Code**: MIT License (this project)
- **Third-Party**: SwiftCharts (included in Xcode), no extra attribution
- **System APIs**: Standard Apple frameworks (IOKit, SMC, WidgetKit) — free to use

## Success Criteria

1. Launch in menu bar with accurate real-time metrics
2. Historical graphs for 24+ hours of data
3. Sub-200 MB RAM footprint
4. < 5% sustained CPU overhead during monitoring
5. 3+ hour battery impact assessment on MacBook Pro
6. Alerts trigger correctly within 5-second window
7. Export CSV file with 100+ data points
8. Widgets update reliably every 10 seconds
9. App passes macOS notarization
10. Pro features convert at 5%+ free-to-paid ratio

## Development Workflow

1. **Setup**: Xcode 15+, iOS 16+ SDK, macOS 13+ deployment target
2. **Dependencies**: SwiftCharts (built-in), optionally SMCKit (CocoaPods or SPM)
3. **Testing**: Unit tests for SensorMonitor, MockIOKit adapters
4. **Profiling**: Instruments (CPU time, memory allocation, energy impact)
5. **Distribution**: 
   - Code sign with Developer ID
   - Create `.dmg` installer (or direct app bundle)
   - Notarize for Gatekeeper
   - Host on GitHub Releases

## Future Roadmap

- **v1.1**: Email alerts, custom hotkeys
- **v1.2**: SSH remote monitoring (sync to cloud)
- **v1.3**: Performance benchmarking (Geekbench integration)
- **v2.0**: Thermal profile switching, fan curve customization
- **v3.0**: Multi-Mac dashboard (iPad widget)

---

**Last Updated**: 2026-03-15  
**Author**: Claude Agent (foundry-pulse)  
**License**: MIT
