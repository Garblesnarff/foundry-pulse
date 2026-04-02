# Foundry Pulse Development Roadmap

## Phase 1: Foundation (Weeks 1-2)

### Xcode Project Setup
- [ ] Create FoundryPulse.xcodeproj (macOS 13+ target)
- [ ] Add app icon and asset catalog
- [ ] Configure Info.plist (entitlements, version)
- [ ] Set up build schemes (Debug, Release)
- [ ] Enable code signing (Developer ID)

### Core Data Schema
- [ ] Define SensorReading entity (timestamp, cpu, gpu, ram, disk, network, battery)
- [ ] Define AlertRule entity (metric, threshold, operator, duration, enabled)
- [ ] Define Settings entity (pollingInterval, theme, menuBarStyle)
- [ ] Create migration plan for future schema changes
- [ ] Write DatabaseManager (CRUD operations)

### UI Scaffolds
- [ ] Create FoundryPulseApp.swift (app delegate)
- [ ] Create MenuBarView scaffold (SwiftUI)
- [ ] Create OverviewTab, GraphsTab, ProcessesTab, SettingsTab placeholders
- [ ] Create Colors.swift (Forge color palette)
- [ ] Create Fonts.swift (DM Sans, JetBrains Mono)

### Documentation
- [ ] Write ARCHITECTURE.md (technical deep dive)
- [ ] Write DESIGN_SYSTEM.md (UI guidelines, color specs)
- [ ] Create CONTRIBUTING.md
- [ ] Write CHANGELOG.md template

**Owner**: Lead + UI/UX Agent  
**Deliverable**: Runnable Xcode project with empty popover (no data yet)

---

## Phase 2: Hardware Sensors (Weeks 2-3)

### Sensor Infrastructure
- [ ] Implement SensorMonitor.swift (@Observable, polling orchestrator)
- [ ] Implement IOKitBridge.swift (C wrapper for IOKit)
  - [ ] Temperature sensor reading (CPU, GPU, storage)
  - [ ] Fan speed reading (RPM)
  - [ ] Error handling + retry logic
- [ ] Implement SMCBridge.swift (SMC reader)
  - [ ] Read thermal state
  - [ ] Read power metrics
  - [ ] Handle privilege errors gracefully
- [ ] Implement ProcessMonitor.swift (ProcessInfo wrapper)
  - [ ] CPU % per-process
  - [ ] Memory per-process
  - [ ] Top 5 by CPU, Top 5 by RAM

### System Metrics (ProcessInfo + BSD APIs)
- [ ] CPU % overall
- [ ] GPU % (if available via IOKit)
- [ ] Memory (used/total, pressure %)
- [ ] Disk (used/total per volume, I/O)
- [ ] Network (upload/download, Mbps)
- [ ] Battery (%, health, time to empty)

### Polling Loop
- [ ] Implement 2-second polling interval (configurable 1-5s)
- [ ] Ring buffer storage (30 samples in memory)
- [ ] Error handling + sensor validation
- [ ] Background thread management (DispatchQueue)

### Data Models
- [ ] SensorReading struct (all metrics + timestamp)
- [ ] MetricError enum (sensor failures)
- [ ] ThermalState enum (nominal/critical/power-limited)
- [ ] ProcessInfo struct (name, PID, CPU%, memory)

**Owner**: Sensor & Hardware Agent  
**Deliverable**: SensorMonitor polling real metrics, visible in logs

---

## Phase 3: UI Implementation (Weeks 3-4)

### Overview Tab
- [ ] MetricCircle.swift (circular gauge for CPU %, GPU %)
- [ ] MetricBar.swift (horizontal bars for RAM, Disk)
- [ ] NetworkIndicator.swift (up/down arrows + Mbps)
- [ ] BatteryIndicator.swift (%, health status)
- [ ] ThermalStrip.swift (color-coded temps)
- [ ] SystemInfo.swift (chip, RAM, OS version)

### Graphs Tab
- [ ] HistoricalChart.swift (SwiftCharts integration)
- [ ] TimeRangeSelector.swift (1 min / 1 hr / 24 hr toggle)
- [ ] MetricSelector.swift (CPU % / GPU % / RAM GB / Disk %)
- [ ] Chart data aggregation (hourly mean/max/min)
- [ ] Tap-to-inspect tooltip

### Processes Tab
- [ ] ProcessListView.swift (sortable table)
- [ ] ProcessRow.swift (name, PID, CPU %, memory)
- [ ] Sorting UI (click header to sort)
- [ ] Force-quit modal (with warning)

### Settings Tab
- [ ] PollingIntervalControl.swift (slider 1-5s)
- [ ] MenuBarStylePicker.swift (CPU/GPU selector)
- [ ] AboutSection.swift (version, credits)
- [ ] ExportButton.swift (CSV, 1-hour limit)
- [ ] OpenLogsButton.swift (~/Library/Logs/FoundryPulse/)

### Menu Bar Integration
- [ ] StatusBarController.swift (NSStatusBar setup)
- [ ] SparklineGraph.swift (8-sample live graph)
- [ ] StatusBarUpdateLoop (every 2 seconds)
- [ ] Popover sizing + persistence (remember user resize)

**Owner**: UI/UX Agent  
**Deliverable**: Fully functional free-tier app (Overview, Graphs, Processes, Settings)

---

## Phase 4: Data Persistence & History (Weeks 4-5)

### Core Data Integration
- [ ] DatabaseManager.swift (init, CRUD, fetch predicates)
- [ ] Hourly aggregation (mean, max, min per metric)
- [ ] 24-hour retention policy (auto-purge older)
- [ ] Concurrent access handling (background thread + main thread)

### CSV Export (Free Tier)
- [ ] ExportManager.swift (CSV generation)
- [ ] Time range selector (free: last 1 hour, Pro: custom)
- [ ] CSV schema (timestamp, cpu_%, gpu_%, ram_mb, disk_%, network_up, network_down)
- [ ] Save to ~/Downloads/FoundryPulse-exports/
- [ ] Toast notification on export complete

### UserDefaults (Settings Persistence)
- [ ] UserPreferences.swift (settings wrapper)
- [ ] Polling interval persistence
- [ ] Menu bar graph style persistence
- [ ] Popover size/position persistence

### Data Validation & Error Recovery
- [ ] Sensor data bounds checking
- [ ] Graceful degradation (show "—" for missing data)
- [ ] Retry failed reads (exponential backoff)
- [ ] Log all errors to ~/Library/Logs/FoundryPulse/

**Owner**: Data & Persistence Agent  
**Deliverable**: CSV export working, 24-hour history retained

---

## Phase 5: Alerts & Pro Features (Week 6)

### Alerts (Pro Only)
- [ ] AlertRuleEditor.swift (modal form)
  - [ ] Metric selector (CPU %, GPU temp, RAM pressure, disk %)
  - [ ] Operator picker (>, <, >=, <=)
  - [ ] Threshold input (number + unit)
  - [ ] Duration picker (30s, 1m, 2m, 5m)
  - [ ] Action picker (notification, sound, log)
- [ ] AlertManager.swift (rule checking + dispatch)
  - [ ] Check all rules every 5 seconds
  - [ ] Deduplicate notifications (5-min cooldown per rule)
  - [ ] Respect macOS Do Not Disturb
  - [ ] Notification sound + alert sound
- [ ] AlertHistoryView.swift (last 100 triggered alerts)
- [ ] Persist rules in Core Data

### StoreKit 2 Integration
- [ ] Configure App Store Connect (product IDs, pricing)
- [ ] Implement isPro check (read from StoreKit)
- [ ] Feature gating UI (disable Pro-only sections in free tier)
- [ ] Trial period (14 days free Pro access)
- [ ] Purchase flow UI modal
- [ ] Restore purchases (for users on multiple Macs)

### Pro Feature Gating
- [ ] AlertRuleEditor visibility (Pro only)
- [ ] WidgetKit integration (Pro only)
- [ ] Advanced export (Pro only)
- [ ] Theme customization (Pro only)
- [ ] In-app prompts ("Upgrade to Pro for alerts")

**Owner**: Alerts Agent + Monetization Agent  
**Deliverable**: Alerts work; StoreKit integration live

---

## Phase 6: Widgets (Week 6)

### Widget Target Setup
- [ ] Create separate WidgetKit target
- [ ] Configure widget extensions entitlements
- [ ] Set up app groups for data sharing

### Small Widget (2x2)
- [ ] SmallWidget.swift (CPU % gauge with mini sparkline)
- [ ] Dynamic Island support (optional)
- [ ] Tap → open main app

### Medium Widget (3x3)
- [ ] MediumWidget.swift (4-quadrant grid)
- [ ] CPU % (top-left), GPU % (top-right)
- [ ] RAM used/total (bottom-left), Disk used/total (bottom-right)
- [ ] Each with mini sparkline
- [ ] Tap → open main app

### Widget Data Sync
- [ ] Use app groups + UserDefaults for data sharing
- [ ] Update widget data every 10 seconds (via WidgetCenter)
- [ ] Handle stale data gracefully (show "—" if > 30s old)
- [ ] Offline support (last-known values)

**Owner**: Widget Agent  
**Deliverable**: Widgets appear on desktop, update every 10 seconds

---

## Phase 7: Testing & Quality (Weeks 6-7)

### Unit Tests
- [ ] Test SensorMonitor (mock sensor data)
- [ ] Test AlertManager (rule evaluation logic)
- [ ] Test ChartData (aggregation algorithms)
- [ ] Test DatabaseManager (CRUD operations)
- [ ] Test CSV export (format validation)

### Integration Tests
- [ ] Sensor polling → Core Data → UI update flow
- [ ] Alert triggered → notification dispatch flow
- [ ] Export CSV → file creation flow
- [ ] App quit → restart → settings restored

### Performance Profiling
- [ ] Instruments: measure CPU %, memory, battery drain
- [ ] Target: < 200 MB RAM, < 5% CPU, < 5% battery/hour
- [ ] Profile on M1/M3/M4 hardware
- [ ] Profile with Activity Monitor open (ensure overhead acceptable)

### Accessibility Testing
- [ ] VoiceOver: all components labeled and navigable
- [ ] Keyboard-only navigation (Tab, arrow keys, Enter)
- [ ] High-contrast mode support
- [ ] Text scaling (System Preferences font size)

### UAT Checklist
- [ ] App launches without crash (macOS 13, 14)
- [ ] Menu bar icon visible and clickable
- [ ] Popover appears/closes on click
- [ ] Metrics update in real-time
- [ ] Graphs display 1min/1hr/24hr views
- [ ] CSV export creates file in ~/Downloads
- [ ] Alerts trigger on threshold (Pro)
- [ ] Widgets appear on desktop (Pro)
- [ ] Switching free ↔ Pro tiers preserves data
- [ ] App quit/restart restores settings

**Owner**: QA Agent  
**Deliverable**: Test report; all tests passing

---

## Phase 8: Release Preparation (Week 7)

### Code Signing & Notarization
- [ ] Code sign app with Developer ID
- [ ] Create .dmg installer
- [ ] Submit to Apple notarization
- [ ] Verify notarization passes (no malware alerts)
- [ ] Test DMG installation on clean Mac

### Documentation
- [ ] Finalize ARCHITECTURE.md
- [ ] Finalize DESIGN_SYSTEM.md
- [ ] Write user manual (help.md)
- [ ] Create installation guide
- [ ] Document keyboard shortcuts

### App Store Submission
- [ ] Write app description (3 paragraphs)
- [ ] Create 5 app preview screenshots (1920×1440)
- [ ] Write privacy policy
- [ ] Write terms of service
- [ ] Configure App Store pricing (free tier + Pro IAP)
- [ ] Set review notes (entitlements, SMC access explanation)

### GitHub Release
- [ ] Create GitHub release page
- [ ] Upload .dmg and .zip artifacts
- [ ] Write release notes
- [ ] Create CHANGELOG entry

**Owner**: DevOps Agent  
**Deliverable**: App submitted to App Store; available on GitHub

---

## Phase 9: Launch & Post-Launch (Weeks 8+)

### Pre-Launch Checklist
- [ ] All bugs fixed
- [ ] Performance verified on M1–M4
- [ ] App Store review passed
- [ ] Privacy policy live
- [ ] Documentation complete

### Launch Day
- [ ] Announce on Product Hunt
- [ ] Share on /r/macapps, /r/macsetup
- [ ] Share on Hacker News (if appropriate)
- [ ] Email to beta testers
- [ ] Share on Twitter/X

### First Month (Post-Launch)
- [ ] Monitor crash reports (TestFlight/App Store)
- [ ] Respond to user feedback
- [ ] Fix critical bugs (< 24 hour turnaround)
- [ ] Track Pro conversion rate
- [ ] A/B test pricing ($4.99 vs $9.99)
- [ ] Plan v1.1 features

### v1.1 Planning (Q2 2026)
- [ ] Email alerts
- [ ] Custom hotkeys
- [ ] Per-app CPU/GPU tracking
- [ ] Fan speed graphs
- [ ] Thermal profile switching

**Owner**: All Agents (ongoing)  
**Deliverable**: Stable, well-received app in production

---

## Blockers & Risks

| Item | Risk | Mitigation | Owner |
|------|------|-----------|-------|
| IOKit API stability | High | Test on macOS 13–14; feature-flag fallbacks | Sensor Agent |
| SMC privilege elevation | High | Use entitlements + helper tool if needed | DevOps Agent |
| Widget data sync | Med | Use app groups + UserDefaults (not direct sensor polling) | Widget Agent |
| Performance regression | Med | Profile early and often; optimize hot paths | QA Agent |
| App Store review delay | Low | Submit early; clear documentation of entitlements | DevOps Agent |
| Low Pro conversion | Med | A/B test pricing; in-app prompts; user research | Product Lead |

---

## Notes

- **Time Estimates**: Phased weeks assume 1 FTE per phase (parallelizable after Phase 2)
- **Flexibility**: Actual velocity may differ; prioritize MVP (free tier) over Pro features
- **Testing**: Start testing in Phase 3, not Phase 7 (continuous integration)
- **Documentation**: Update docs as code evolves; don't leave for the end
- **Communication**: Async standups in STANDUP.md; escalate blockers to Lead within 24 hours

---

**Last Updated**: 2026-03-15  
**Maintained By**: Claude Agent (Lead)
