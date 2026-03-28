# Product Requirements Document (PRD)
## Foundry Pulse — Native macOS Hardware Monitor

**Document Version**: 1.0  
**Last Updated**: 2026-03-15  
**Status**: Approved for Scaffolding Phase  
**Owned By**: Claude Agent (Product Lead)

---

## 1. Executive Summary

**Foundry Pulse** is a native macOS menu bar application that provides real-time hardware monitoring for Apple Silicon Macs. It targets power users, developers, gamers, and content creators who need granular visibility into CPU, GPU, memory, disk, thermal, and network metrics.

**Core Insight**: The market leader (exelban/stats) is solid but lacks charting and alerts. Foundry Pulse differentiates on ease-of-use + professional features at a low price point ($4.99/year Pro).

**Business Model**: Freemium
- **Free Tier**: Core monitoring + 24-hour graphs + CSV export (limited)
- **Pro Tier**: Alerts + Widgets + Advanced export + Theme customization

**Target Release**: Q2 2026 (6 weeks from kickoff)

---

## 2. Problem Statement

### User Pain Points

1. **Activity Monitor is clunky** for real-time monitoring
   - Requires click to open, modal, no persistent view
   - No historical data or trends
   - Kills focus during development

2. **Existing menu bar apps are feature-poor**
   - Limited to current metrics (no graphing)
   - No alerts for thermal/memory thresholds
   - No widgets for quick glance on desktop

3. **Developers can't easily correlate performance**
   - CPU spike at 3 PM — was it my build or background task?
   - Can't quickly export data for analysis
   - No automatic alerts for anomalies

4. **Gamers lack thermal visibility**
   - Fan speed and temps are hidden
   - Thermal throttling isn't obvious
   - No warnings before crash

5. **Content creators need export for time-series analysis**
   - Rendering monitoring requires external tools
   - No easy way to log stats for post-mortems

---

## 3. Goals & Success Criteria

### Primary Goals

1. **Ship MVP in 6 weeks** with core monitoring + graphs + Pro alerts
2. **Achieve 4.5+ stars** on App Store within first 100 reviews
3. **Convert 5%+ free users to Pro** within 3 months
4. **Keep footprint < 200 MB RAM** and < 5% CPU overhead
5. **Support macOS 13–14+** (backward compatible)

### KPIs

| Metric | Target | Definition |
|--------|--------|-----------|
| App Store Rating | 4.5+ | Average star rating (100+ reviews) |
| Pro Conversion | 5%+ | % of free users upgrading to Pro |
| Daily Active Users | 5K+ | Users opening app at least once/day |
| Session Duration | 2+ min | Average time in popover per session |
| Feature Adoption | >50% | % of users who enable alerts/widgets |
| Memory Footprint | <200 MB | Peak RSS during 24-hour monitoring |
| CPU Overhead | <5% | Sustained CPU % while monitoring |
| Battery Impact | <5% | % of battery drained per hour |
| App Store Review Time | <5 days | Time to approval after submission |

---

## 4. Target Users

### Primary Personas

**1. Developer (Dave, 28, San Francisco)**
- Compiles large projects daily; needs CPU monitoring
- Wants to correlate build times with system state
- Checks Activity Monitor every 2–3 hours
- Pain: Modal pop-up, can't see trends, no data export

**2. Gamer (Gina, 24, London)**
- Plays demanding games (AAA titles) on MacBook Pro
- Cares about FPS stability and thermal throttling
- Wants real-time GPU temp and fan speed
- Pain: Game dev tools are complex; no Mac-native monitoring

**3. Content Creator (Chris, 35, LA)**
- Exports video, renders 3D, handles large files
- Needs CPU/GPU utilization during render jobs
- Wants to export logs for performance analysis
- Pain: Stats app doesn't export; Activity Monitor is slow

**4. Data Scientist (Dana, 32, NYC)**
- Trains ML models on Mac; monitors GPU usage
- Memory pressure is critical (16/32 GB RAM systems)
- Wants alerts for swap usage threshold
- Pain: Needs terminal commands or Python scripts to monitor

**5. Sysadmin (Sam, 45, Enterprise)**
- Manages multiple Macs; wants audit logs
- Cares about thermal health and reliability
- Wants CSV export for fleet analysis (Phase 2)
- Pain: No centralized monitoring; manual checks required

---

## 5. Feature Set

### MVP (Tier 1: Free)

#### 5.1 Core Monitoring
- [ ] Real-time CPU (%, per-core)
- [ ] GPU (%, temp)
- [ ] Memory (used/total, pressure %)
- [ ] Disk (used/total per volume, I/O throughput)
- [ ] Network (upload/download, Mbps)
- [ ] Battery (%, health, time to empty)
- [ ] Temperatures (CPU, GPU, storage)
- [ ] Fan speed (RPM)
- [ ] Thermal state (nominal/critical)
- [ ] System info (chip, RAM, OS version)

#### 5.2 Menu Bar Integration
- [ ] Status bar item with Forge icon
- [ ] Sparkline mini-graph (8 samples, live CPU/GPU)
- [ ] Color-coded by utilization (green/yellow/red)
- [ ] Resizable popover (300×600 pt, user-adjustable)
- [ ] Click to toggle popover open/close

#### 5.3 Popover UI (4 Tabs)
- [ ] **Overview Tab** (default)
  - Circular gauges: CPU %, GPU %
  - Horizontal bars: RAM usage, disk usage
  - Network indicators: up/down arrows + Mbps
  - Battery % + health
  - Thermal strip (color temp indicator)

- [ ] **Graphs Tab**
  - Time range selector (1 min / 1 hr / 24 hr)
  - Line charts for: CPU %, GPU %, RAM GB, disk used %
  - Smooth curves using SwiftCharts
  - Tap-to-inspect (show exact value on hover)
  - Zoom/pan (pinch to zoom)

- [ ] **Processes Tab**
  - Top 5 CPU consumers
  - Top 5 memory consumers
  - Sortable by CPU %, memory, name
  - PID, process state
  - Click process name → force quit dialog (with warning)

- [ ] **Settings Tab**
  - Polling interval (1–5 sec, default 2)
  - Menu bar graph style (CPU/GPU selector)
  - About section (version, credits)
  - Export button (limited: 1-hour CSV)
  - Open logs folder

#### 5.4 Data Persistence
- [ ] UserDefaults for settings (polling interval, theme, menu bar style)
- [ ] In-memory ring buffer (30 samples = 1 min of data)
- [ ] Core Data for hourly aggregates (mean, max, min per metric)
- [ ] 24-hour data retention (auto-purge older data)
- [ ] Persistent across app restarts

#### 5.5 CSV Export (Free)
- [ ] 1-hour rolling window only
- [ ] Columns: timestamp, cpu_%, gpu_%, ram_mb, disk_used_%, network_up_mbps, network_down_mbps
- [ ] Saved to ~/Downloads/FoundryPulse-exports/

#### 5.6 Error Handling
- [ ] Graceful degradation if IOKit unavailable
- [ ] Show "—" for missing sensor data (temp, fan)
- [ ] Fallback to ProcessInfo-only metrics if SMC fails
- [ ] Retry sensor reads with exponential backoff
- [ ] Log errors to ~/Library/Logs/FoundryPulse/

### Phase 2: Pro Features (Tier 2)

#### 5.7 Alerts (Pro Only)
- [ ] Create alert rules: `if <metric> <operator> <threshold> for <duration>`
- [ ] Supported metrics: CPU %, GPU temp, RAM pressure %, disk used %
- [ ] Operators: >, <, >=, <=
- [ ] Duration: 30 sec, 1 min, 2 min, 5 min
- [ ] Actions: notification, sound (ding/alert), log entry
- [ ] Max 10 active rules (Pro limit)
- [ ] Alert history (last 100 triggered alerts)
- [ ] Duplicate suppression (don't re-alert for 5 min same rule)
- [ ] Respect macOS Do Not Disturb setting
- [ ] Rule persistence in Core Data
- [ ] Check interval: every 5 seconds (after each poll)

#### 5.8 Desktop Widgets (Pro Only)
- [ ] Small widget (2×2 pt)
  - Large CPU % gauge
  - Mini sparkline graph below
  - Tap to open app

- [ ] Medium widget (3×3 pt)
  - 4-quadrant layout
  - Top-left: CPU % with mini graph
  - Top-right: GPU % with mini graph
  - Bottom-left: RAM used/total (bar)
  - Bottom-right: Disk used/total (bar)
  - Tap any quadrant to open app

- [ ] Widget refresh: 10-second minimum (WidgetKit budget)
- [ ] Data synced via app groups (not direct sensor polling)
- [ ] Graceful fallback if data stale

#### 5.9 Advanced Export (Pro Only)
- [ ] CSV + JSON formats
- [ ] Custom date range (1 hr – 30 days)
- [ ] All metrics included (vs. limited free export)
- [ ] Auto-save to ~/Downloads/FoundryPulse-exports/
- [ ] Bulk export (multiple ranges in single ZIP)

#### 5.10 Theme Customization (Pro Only)
- [ ] Dark mode (default) / Light mode toggle
- [ ] Accent color picker (amber, blue, green, red)
- [ ] Persistent across restarts
- [ ] Apply to menu bar icon and popover

### Future (Phase 3+)

- Email alerts / Webhook integration
- SSH remote monitoring (sync to cloud)
- Per-app CPU/GPU tracking
- Fan curve customization (thermal profile switching)
- iPad companion app
- Apple Watch support (complications)
- Multi-Mac dashboard

---

## 6. Monetization Model

### Free Tier
- All core features (monitoring, graphs, process list)
- 24-hour historical data
- CSV export (1-hour max)
- Menu bar sparkline
- No alerts, no widgets, no advanced export

### Pro Tier
**Price**: $4.99/year (or $0.99 one-time trial)
- All free features, plus:
- Configurable alerts (10 rules max)
- Desktop widgets (2×2 and 3×3)
- Advanced CSV/JSON export (custom date range)
- Theme customization (dark/light, accent colors)
- Priority support email

### Monetization Strategy
1. **Trial Period**: First 14 days Pro features free (no credit card)
2. **Freemium Psychology**: Free tier is fully functional; Pro adds convenience/power features
3. **Annual Subscription**: Encourage yearly renewal with slight discount vs. one-time
4. **App Store Pricing**: Test $4.99/year vs. $9.99/year (A/B test after launch)
5. **No Data Loss**: Switching tiers doesn't delete settings or history

### Revenue Projections

| Year | Users | Free:Pro Ratio | Revenue | Notes |
|------|-------|---------------|---------|-------|
| 1 | 5K | 95:5 | $1.2K | Conservative; organic growth |
| 2 | 25K | 90:10 | $12.5K | Word-of-mouth + Product Hunt |
| 3 | 100K | 85:15 | $75K | Viral /r/macsetup, YouTube |

(Rough estimates; actual performance depends on marketing + product-market fit)

---

## 7. Technical Requirements

### Platform & Compatibility
- **OS**: macOS 13.0+ (Ventura, Sonoma, Sequoia)
- **Architecture**: ARM64 (M1, M2, M3, M4 only)
- **Deployment Target**: macOS 13.0
- **Swift Version**: 5.9+
- **Xcode**: 15.0+

### Performance Requirements
- **Memory Footprint**: < 200 MB RAM (excluding historical data)
- **CPU Overhead**: < 5% sustained (during active monitoring)
- **Startup Time**: < 2 seconds from menu bar click
- **Popover Responsiveness**: 60 FPS (no jank)
- **Graph Render**: < 500 ms for 24-hour chart
- **Battery Impact**: < 5% per hour on MacBook Pro M3 Max

### Reliability Requirements
- **Uptime**: 99%+ (app doesn't crash)
- **Data Integrity**: No loss of history or settings on crash
- **Graceful Degradation**: Missing sensors → show "—", don't crash
- **Sensor Accuracy**: ±2% CPU %, ±5°C temp (vs. Activity Monitor / macOS System Report)

### Security & Privacy Requirements
- **Code Signing**: Developer ID Application (not self-signed)
- **Notarization**: Passes Apple notarization (no malware)
- **Entitlements**: Minimal (SMC access only, no network access)
- **Data**: All local, no cloud sync by default
- **Privacy Policy**: Transparent, clearly state "no telemetry"

---

## 8. User Experience (UX)

### Interaction Model

1. **Menu Bar (Always Visible)**
   - Click → Popover appears (sticky)
   - Click again → Popover closes
   - Keyboard shortcut (Cmd+Shift+P) to toggle
   - Mini-graph updates live every 2 seconds

2. **Popover (Floating Window)**
   - 300×600 pt, resizable (min 250×400, max 600×800)
   - Remember size across restarts
   - Scroll content if needed
   - Tab navigation (click tab to switch)

3. **Graphs**
   - Swipe left/right to change metric
   - Pinch to zoom (1 min view → zoom in → 10 sec granularity)
   - Tap point → tooltip (show exact value + timestamp)

4. **Alerts**
   - Click "New Alert" → modal form
   - Select metric, set threshold, duration, action
   - Save → alert added to list
   - Toggle rule on/off
   - Delete rule (no undo warning — data stays)

5. **Settings**
   - Dropdowns, sliders, toggles (no text input where possible)
   - Save immediately on change (no "Apply" button)

### Design Language

**Forge Aesthetic**:
- **Colors**: Charcoal blacks (#141210), amber gold (#E8A849), steel grays
- **Fonts**: DM Sans (UI), JetBrains Mono (data/numbers)
- **Icons**: Minimalist anvil, spark, pulse (custom SVG)
- **Animations**: Smooth (0.3s easing), no distracting bounces
- **Tone**: Professional, data-driven, under control ("Pulse steady." not "System burning!")

**Accessibility**:
- WCAG 2.1 AA compliant
- VoiceOver support (all components labeled)
- Keyboard-only navigation (Tab, Arrow keys, Enter)
- High-contrast mode support
- Text scaling (System Preferences font size)

---

## 9. Content & Copy

### Key Messages

| Context | Forge Language | Example |
|---------|-------------|---------|
| App opening | "Reading vitals..." | Status: "Reading vitals..." for 1 sec |
| Normal | "Pulse steady." | Default status in settings |
| Alert triggered | "The forge overheats!" | Notification title |
| Settings saved | "Preferences forged." | Toast after settings change |
| Export done | "Vitals exported." | Toast after CSV saved |
| Menu bar toggle | "Forge pulse online." | Tooltip on hover |

### Tooltips

- **CPU gauge**: "CPU load: 45% (8 cores active)"
- **Thermal strip**: "CPU: 65°C, GPU: 58°C, Storage: 42°C"
- **RAM bar**: "Memory: 12.4 GB of 16 GB (77% used), 10% pressure"
- **Fan badge**: "Fans: 4000 RPM at 100% duty"

### Settings Labels

- "Polling Interval": "How often to check metrics (1–5 seconds). Lower = more responsive, higher = less battery drain."
- "Menu Bar Graph": "Which metric to show as sparkline in menu bar."
- "Theme": "Dark or light mode for app (Pro)."

---

## 10. Rollout Plan

### Phase 1: Scaffolding (Week 1)
- [ ] Create Xcode project, targets, build schemes
- [ ] Set up Core Data schema
- [ ] Create placeholder UI components
- [ ] Document architecture

### Phase 2: MVP Core (Weeks 2–3)
- [ ] Implement SensorMonitor (IOKit, ProcessInfo)
- [ ] Implement popover UI (Overview, Graphs, Processes, Settings tabs)
- [ ] Implement CSV export
- [ ] Unit tests for sensors and data

### Phase 3: Polish & Testing (Weeks 4–5)
- [ ] Performance profiling (CPU, memory, battery)
- [ ] Bug fixes and UX refinements
- [ ] Accessibility testing (VoiceOver)
- [ ] Integration testing on macOS 13 and 14

### Phase 4: Pro Features (Week 6)
- [ ] Alerts implementation
- [ ] StoreKit 2 integration
- [ ] Widgets (WidgetKit)
- [ ] Feature gate testing

### Phase 5: Release Prep (Weeks 6–7)
- [ ] Code signing and notarization
- [ ] Create installer (.dmg)
- [ ] Write privacy policy and terms
- [ ] Submit to App Store
- [ ] Create launch materials (screenshots, description)

### Phase 6: Post-Launch (Weeks 8+)
- [ ] Monitor crash reports and reviews
- [ ] Respond to support emails
- [ ] Plan v1.1 (email alerts, hotkeys)
- [ ] Iterate based on user feedback

---

## 11. Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|-----------|
| IOKit API changes in future macOS | High (app breaks) | Low | Test on macOS 13–14; follow Apple docs; feature-flag fallbacks |
| SMC access requires elevated privilege | Med (UX friction) | High | Use entitlements + helper tool; document privilege requirement |
| Competing free app undercuts price | Med (sales impact) | Med | Differentiate on charts + alerts; free tier is strong |
| User confusion (free vs. Pro) | Med (support load) | Med | Clear in-app messaging; free trial for Pro (14 days) |
| Performance regression on older Macs | Med (1-star reviews) | Low | Profile on M1; test on minimal RAM (8GB); graceful degradation |
| Apple rejects app (entitlement issue) | High (launch delay) | Low | Pre-submit review with Apple (DTS); test notarization early |
| Low Pro conversion (<2%) | High (revenue) | Med | A/B test pricing; in-app prompts; feature gating; user research |

---

## 12. Success Criteria (Go/No-Go)

### Hard Gates (Must Have)
- [ ] App launches without crash on macOS 13–14
- [ ] CPU %, GPU %, RAM, disk metrics accurate (±5%)
- [ ] Popover updates in < 100 ms
- [ ] 24-hour historical data persists across restarts
- [ ] CSV export works (readable in Excel)
- [ ] Passes notarization (no malware alerts)
- [ ] Pro alert triggers within 10 seconds of threshold
- [ ] Widgets refresh every 10 seconds (WidgetKit requirement)

### Soft Goals (Should Have)
- [ ] < 150 MB memory footprint
- [ ] < 3% CPU overhead
- [ ] 4.5+ star rating on App Store
- [ ] 5%+ Pro conversion within 3 months
- [ ] < 10 critical bugs in first month

### Won't Do (v1.0)
- Multi-Mac monitoring (Phase 2)
- iPad app (Phase 2)
- Cloud sync (Phase 2)
- Fan speed control (Phase 3)
- Email alerts (Phase 2)

---

## 13. Open Questions & Decisions

| Question | Owner | Status | Decision |
|----------|-------|--------|----------|
| Exact Pro price: $4.99 or $9.99/year? | Product | TBD | Test both via App Store variants |
| Include fan speed graph in free tier? | UX | TBD | No — reserve for Pro |
| Alert max rules: 10 or unlimited? | Product | TBD | 10 (manageable, freemium-appropriate) |
| SMC privilege: entitlements or helper tool? | DevOps | TBD | Entitlements + graceful fallback |
| Which temperature sensors to monitor? | Sensors | TBD | CPU package, P-core, E-core, GPU (M-series specific) |
| Widget refresh: 10 sec or 15 sec? | Product | TBD | 10 sec (WidgetKit minimum) |

---

## 14. Appendices

### A. Competitive Analysis

| App | Pros | Cons | Foundry Pulse Advantage |
|-----|------|------|------------------------|
| **Stats** (exelban) | Free, minimal, reliable | No graphs, no alerts, dated UI | Graphs + alerts + widgets |
| **Activity Monitor** | Built-in, detailed processes | Modal, no history, confusing | Always-on menu bar, smooth trends |
| **iStat Menus** | Comprehensive, polished | $40+ one-time, overkill for most | Lightweight, freemium, Forge aesthetic |
| **Logi Control Center** | Logitech integration | Limited to Logitech devices | Hardware-agnostic, general-purpose |

**Positioning**: "Stats + Activity Monitor UI + Professional charting at free-to-$5 price point."

### B. App Store Metadata

**Name**: Foundry Pulse
**Subtitle**: "Real-time hardware monitoring for Mac"
**Description** (short): "Monitor CPU, GPU, memory, disk, and thermal metrics in your menu bar. View historical graphs, set alerts, and export data — all offline and private."
**Keywords**: hardware, monitor, stats, cpu, gpu, memory, temperature, metrics, mac, system
**Category**: System Utilities

### C. Privacy Policy (Draft)

**Foundry Pulse does not collect, store, or transmit any personal data.**

- All metrics are computed locally on your Mac
- No network requests to external services
- No analytics or crash reporting (optional, user-controlled)
- No cloud sync or iCloud integration
- Export files saved locally; not uploaded
- Full source code reviewable on GitHub

See Privacy Policy in app for details.

---

**Approval Sign-Off**

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Product Lead | Claude Agent | ✓ | 2026-03-15 |
| Engineering Lead | (TBD) | ○ | — |
| Design Lead | (TBD) | ○ | — |

---

**Document History**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | 2026-03-10 | Claude Agent | Initial draft |
| 0.9 | 2026-03-14 | Claude Agent | Feedback incorporated |
| 1.0 | 2026-03-15 | Claude Agent | Approved for scaffolding |

