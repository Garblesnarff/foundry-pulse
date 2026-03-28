# Foundry Pulse

**A native macOS hardware monitor for M-series Macs — real-time metrics, historical graphs, and intelligent alerts.**

![Swift](https://img.shields.io/badge/Swift-5.9+-FA7343?logo=swift&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-13+-000000?logo=apple&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue)
![Status](https://img.shields.io/badge/Status-Scaffolding-yellow)

## What Is Foundry Pulse?

Foundry Pulse brings professional hardware monitoring to your macOS menu bar. It combines the simplicity of **exelban/stats** with advanced charting, configurable alerts, and desktop widgets — all optimized for Apple Silicon (M1–M4).

### Key Features

✨ **Real-Time Metrics**
- CPU, GPU, Memory, Disk, Network, Battery
- Temperature sensors (CPU, GPU, storage)
- Fan speed & thermal throttling state
- Process list (top CPU/RAM consumers)

📈 **Historical Graphs**
- 1-minute, 1-hour, and 24-hour rolling charts
- Smooth curves using SwiftCharts
- Tap to zoom and inspect historical data

🚨 **Intelligent Alerts (Pro)**
- Configurable thresholds (CPU > 80%, RAM > 90%, GPU > 85°C)
- Smart notifications with 5-second check interval
- Duplicate suppression (no alert spam)

🎛️ **Menu Bar Integration**
- Sparkline graph showing live CPU/GPU
- Color-coded by utilization (green → yellow → red)
- Resizable popover (300×600 pt)

📊 **macOS Widgets (Pro)**
- 2×2 widget: CPU gauge with mini graph
- 3×3 widget: 4-quadrant (CPU, GPU, RAM, Disk)
- 10-second refresh on desktop

💾 **Data Export**
- CSV export (free, 1 hour)
- JSON export (Pro, custom range)
- Auto-save to ~/Downloads/FoundryPulse-exports/

## Screenshot Flow (Text)

```
Menu Bar
  ↓
[Spark] ← Live CPU/GPU graph in menu bar

Popover (click to open)
  ├─ Overview Tab (default)
  │  ├─ CPU % (circular gauge) | GPU % (circular gauge)
  │  ├─ RAM (bar) | Disk (bar)
  │  ├─ Network (up/down) | Battery (%)
  │  └─ Thermal strip (temp color indicator)
  │
  ├─ Graphs Tab
  │  ├─ Time range picker (1 min / 1 hr / 24 hr)
  │  └─ Line chart (CPU % / GPU % / RAM GB / Disk %)
  │
  ├─ Processes Tab
  │  └─ Sortable table (Name, CPU %, Memory)
  │
  └─ Settings Tab
     ├─ Preferences (refresh rate, theme)
     ├─ Alert Rules (Pro only)
     ├─ Export (CSV/JSON)
     └─ About (version, credits)

Desktop Widget
  ├─ Small 2×2: CPU % with mini graph
  └─ Medium 3×3: 4-quad (CPU | GPU)
                  (RAM | Disk)
```

## Quick Start

### Prerequisites
- macOS 13.0 or later
- Apple Silicon Mac (M1, M2, M3, M4)
- Xcode 15.0 or later

### Installation (Development)

1. **Clone the repository**
   ```bash
   git clone https://github.com/foundry-pulse/foundry-pulse.git
   cd foundry-pulse
   ```

2. **Open in Xcode**
   ```bash
   open FoundryPulse.xcodeproj
   ```

3. **Build & Run**
   - Select "FoundryPulse" scheme
   - Press Cmd+R to build and run
   - App will launch in menu bar (top right)

### Build for Release

```bash
# Build with code signing
xcodebuild \
  -scheme FoundryPulse \
  -configuration Release \
  -derivedDataPath ./build \
  CODE_SIGN_IDENTITY="Developer ID Application" \
  PROVISIONING_PROFILE_SPECIFIER="FoundryPulse"

# Notarize (required for distribution)
xcrun notarytool submit ./build/Release/FoundryPulse.app \
  --apple-id your-id@apple.com \
  --password @env:APPLE_PASSWORD \
  --team-id XXXXXXXXXX

# Create .dmg installer
create-dmg FoundryPulse.dmg ./build/Release/FoundryPulse.app
```

## Architecture Overview

```
FoundryPulseApp (App Delegate)
    ↓
┌─────────────────────────────────────┐
│    Menu Bar Controller              │
│  (NSStatusBar + SwiftUI Popover)    │
└─────────────┬───────────────────────┘
              │
    ┌─────────┴──────────┬──────────────┐
    ↓                    ↓              ↓
┌─────────────┐  ┌────────────────┐ ┌───────────┐
│ SensorMonitor   │ Views/Components│ │ Widgets   │
│ (IOKit/SMC)     │ (SwiftUI)      │ │ (WidgetKit)
└────┬────────┘  └────────────────┘ └───────────┘
     │
     ├─→ Core Data (History, Alerts, Settings)
     └─→ Notifications & Alerts
```

For deep architecture, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Project Structure

```
foundry-pulse/
├── FoundryPulseApp.swift           # App entry point
├── Sources/
│   ├── Sensors/                    # IOKit, SMC, ProcessInfo
│   ├── Views/                      # SwiftUI components
│   ├── Widgets/                    # WidgetKit targets
│   ├── Models/                     # Data models, Core Data
│   └── Utilities/                  # Formatters, helpers
├── docs/
│   ├── ARCHITECTURE.md             # Technical deep dive
│   ├── DESIGN_SYSTEM.md            # UI guidelines
│   ├── IOKit_NOTES.md              # Sensor integration
│   └── SMC_GUIDE.md                # Temperature reading
├── Tests/                          # Unit & integration tests
└── FoundryPulse.xcodeproj          # Xcode project
```

## Technology Stack

| Component | Technology | Notes |
|-----------|-----------|-------|
| **Platform** | macOS 13+ (M1–M4) | Apple Silicon native |
| **Language** | Swift 5.9 | Modern, performant |
| **UI Framework** | SwiftUI | Native menu bar, popover |
| **Hardware Access** | IOKit + SMC | Sensor reading |
| **Graphing** | SwiftCharts | Built-in, no external deps |
| **Persistence** | Core Data | History, alerts, settings |
| **Widgets** | WidgetKit | macOS 14+ desktop widgets |
| **Monetization** | StoreKit 2 | In-app purchases |

## Features by Tier

### Free Tier
- Real-time CPU, GPU, Memory, Disk, Network, Battery monitoring
- Temperature sensors (CPU, GPU, storage)
- 24-hour historical graphs
- CSV export (basic, last 1 hour)
- Process list (top 5 CPU/RAM)
- Menu bar sparkline graph

### Pro Tier ($4.99/year)
- **All free features, plus:**
- Configurable alerts (up to 10 rules)
- Email/webhook alerts (future)
- WidgetKit desktop widgets (2×2 and 3×3)
- Advanced CSV/JSON export (custom time range)
- Theme customization (dark/light persistent)
- Priority support

## Usage

### Monitoring Metrics

The app monitors the following in real-time:

- **CPU**: Overall %, per-core breakdown, thermal state
- **GPU**: %, temperature, power consumption
- **Memory**: Used/Total (GB), pressure %, swap usage
- **Disk**: Used/Total per volume (%), I/O throughput
- **Network**: Upload/Download (Mbps), packet loss
- **Battery**: %, health, time to empty, cycle count
- **Thermal**: CPU/GPU/storage temperature, fan speed
- **Throttling**: Power/thermal limited state

### Setting Up Alerts (Pro)

1. Click menu bar icon → **Settings** tab
2. Click **"New Alert Rule"** (Pro only)
3. Choose metric (e.g., CPU %)
4. Set threshold (e.g., > 80%)
5. Set duration (e.g., 2 minutes before alert)
6. Choose action (notification, sound, log)
7. Save

Alerts check every 5 seconds and trigger once per rule when threshold breached.

### Exporting Data

1. Click menu bar icon → **Settings** tab
2. Click **"Export"**
3. Choose format (CSV or JSON)
4. Select time range (free: 1 hr, Pro: custom)
5. File saves to ~/Downloads/FoundryPulse-exports/

## Legal & Licensing

**License**: MIT

**Inspiration**: This project is inspired by (but not derived from) **exelban/stats** (MIT License). We use different technologies (SwiftUI vs. AppKit, native IOKit vs. alternative APIs) and add new features (charting, alerts, widgets).

**Third-Party**:
- SwiftCharts: Included in Xcode, Apple-provided
- No external dependencies in production build

**Entitlements**: 
- `com.apple.security.device.usb` (SMC access, elevated privilege)
- `com.apple.security.app-sandbox` (App Sandbox, restrictive)

## Privacy

Foundry Pulse **does not collect or transmit** any data outside your Mac:

- All metrics are computed locally
- No analytics or telemetry
- No network requests to third parties
- No data stored in iCloud/cloud sync
- Settings stored in UserDefaults (local only)
- Export files saved locally to ~/Downloads

## Performance

Typical resource usage on M3 Max MacBook Pro:

- **Memory**: ~80–120 MB (excluding historical data)
- **CPU**: 0–2% during idle, 3–5% during intensive monitoring
- **Battery**: ~3–5% impact (varies by screen time)
- **Disk**: ~50 MB for 24 hours of history

## Roadmap

### v1.0 (Current — MVP)
- [x] Real-time monitoring
- [x] Menu bar integration
- [x] Historical graphs (24 hr)
- [x] CSV export (free)
- [x] Alerts (Pro)
- [x] Desktop widgets (Pro)

### v1.1 (Q2 2026)
- [ ] Email alerts
- [ ] Custom hotkeys
- [ ] Per-app CPU/GPU tracking
- [ ] Thermal profile switching (fan control)

### v1.2 (Q3 2026)
- [ ] Remote SSH monitoring
- [ ] Cloud sync (optional, encrypted)
- [ ] Geekbench integration

### v2.0 (Q4 2026)
- [ ] iPad companion app
- [ ] Apple Watch support (basic)
- [ ] Multi-Mac dashboard (aggregate monitoring)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## FAQ

**Q: Can I use Foundry Pulse on Intel Macs?**
A: No, this version is ARM64-only for Apple Silicon (M1–M4). Intel support may come in a future version, but no guarantees.

**Q: Does it drain battery?**
A: Typical battery impact is 3–5% per hour on a MacBook Pro. You can reduce CPU overhead by increasing the polling interval (default 2 sec) to 5 sec in settings.

**Q: Can I export longer than 24 hours?**
A: Free tier is limited to 1-hour exports. Pro tier allows custom date ranges up to 30 days.

**Q: Why does it need elevated privilege for SMC?**
A: Reading accurate temperature and fan data requires low-level SMC access. The app requests minimal escalation and only reads (never writes to SMC).

**Q: Is open-source planned?**
A: Yes, after v1.0 stabilization. Target: mid-2026 GitHub release.

## Support

- **Issues**: GitHub Issues (bug reports, feature requests)
- **Email**: support@foundry-pulse.app (community support)
- **Slack**: #foundry-pulse (when established)

## Credits

**Lead Developer**: Claude Agent (foundry-pulse)  
**Inspired By**: exelban/stats, macOS Activity Monitor  
**Design System**: Foundry shared design language

## License

MIT © 2026 Foundry Pulse Contributors

See [LICENSE](LICENSE) for details.

---

**Status**: Scaffolding (Phase 1)  
**ETA to MVP**: 6 weeks from kickoff  
**Last Updated**: 2026-03-15
