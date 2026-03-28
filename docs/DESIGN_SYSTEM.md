# Foundry Pulse Design System

## Overview

Foundry Pulse uses the **Foundry shared design language** — a forge/metallurgy aesthetic emphasizing control, precision, and transformation.

Visual theme: Dark forge aesthetic with amber accents. Typography: modern, technical, readable.

---

## Color Palette

### Core Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **Anvil Black** | #141210 | (20, 18, 16) | Background, dark theme base |
| **Forge Gold** | #E8A849 | (232, 168, 73) | Accents, CTAs, highlights |
| **Steel Gray** | #3A3A3A | (58, 58, 58) | Secondary backgrounds, dividers |
| **Silver** | #E0E0E0 | (224, 224, 224) | Text, secondary |
| **White** | #FFFFFF | (255, 255, 255) | Primary text, emphasis |

### Semantic Colors

#### Status/Utilization (Thermal-Aware)

| Level | Hex | Usage | Meaning |
|-------|-----|-------|---------|
| **Green** | #10B981 | 0-50% utilization | Healthy, idle |
| **Yellow** | #F59E0B | 50-80% utilization | Elevated, caution |
| **Red** | #EF4444 | 80-100% utilization | Critical, urgent |
| **Critical** | #DC2626 | > 100% or error | Severe, attention |

#### Component Colors

| Element | Color | Hex |
|---------|-------|-----|
| CPU gauge | Forge Gold | #E8A849 |
| GPU gauge | Cyan-blue | #06B6D4 |
| RAM bar | Violet | #A78BFA |
| Disk bar | Orange | #F97316 |
| Network (up) | Green | #10B981 |
| Network (down) | Blue | #3B82F6 |
| Battery | Yellow | #FBBF24 |

#### Temperature Colors (°C)

| Range | Color | Hex |
|-------|-------|-----|
| < 40°C | Green | #10B981 |
| 40–60°C | Cyan | #06B6D4 |
| 60–80°C | Yellow | #F59E0B |
| 80–95°C | Orange | #F97316 |
| > 95°C | Red | #EF4444 |

---

## Typography

### Font Stack

```
DM Sans (UI, body text)
  → Fallback: -apple-system, BlinkMacSystemFont, "Segoe UI"

JetBrains Mono (data, numbers, code)
  → Fallback: "SF Mono", Menlo, monospace

Playfair Display (titles only, sparingly)
  → Fallback: Georgia, serif
```

### Type Scales

| Role | Size | Weight | Line Height | Usage |
|------|------|--------|-------------|-------|
| **Title** | 24px | 700 (Bold) | 1.2 | App name, major headings |
| **Headline** | 18px | 600 (Semibold) | 1.3 | Tab titles, section headers |
| **Body** | 13px | 400 (Regular) | 1.5 | Description, default text |
| **Caption** | 11px | 400 (Regular) | 1.4 | Metadata, secondary info |
| **Monospace** | 12px | 400 (Regular) | 1.4 | Numbers, temps, data |

### Examples

```swift
// Title
.font(.system(size: 24, weight: .bold, design: .default))

// Headline
.font(.system(size: 18, weight: .semibold, design: .default))

// Body
.font(.system(size: 13, weight: .regular, design: .default))

// Monospace data
.font(.system(size: 12, weight: .regular, design: .monospaced))
```

---

## Component Library

### Metric Circle (Gauge)

Circular progress indicator for CPU % and GPU %.

```swift
MetricCircle(
    label: "CPU",
    percent: 45,
    accentColor: .orange
)
```

**Design**:
- Outer ring: 150pt diameter
- Inner fill: Linear gradient (green → yellow → red based on %)
- Label: Centered, bold
- Percentage: Below label, monospace

### Metric Bar

Horizontal progress bar for RAM and disk usage.

```swift
MetricBar(
    label: "RAM",
    current: 10.4,
    total: 16,
    unit: "GB",
    accentColor: .purple
)
```

**Design**:
- Height: 8pt
- Background: Steel gray (#3A3A3A)
- Fill: Solid color, left-aligned
- Label + values: Flanking left/right

### Thermal Strip

Color-coded temperature display (CPU, GPU, storage).

```swift
ThermalStrip(
    cpuTemp: 65,
    gpuTemp: 58,
    storageTemp: 42
)
```

**Design**:
- Three colored blocks (CPU, GPU, storage)
- Color based on temperature range (green → red)
- Tooltip on hover: exact temperature
- Height: 24pt

### Sparkline Graph

8-sample live graph in menu bar.

```swift
SparklineGraph(
    data: sensorMonitor.history.suffix(8),
    metric: .cpu,
    color: .orange
)
```

**Design**:
- Width: 60pt, Height: 20pt
- Smooth curve (no hard points)
- Color: Forge gold or metric-specific
- No axis labels (too small)

### Buttons

**Primary Button** (CTAs: Export, Save)
```swift
Button("Export CSV") { }
    .buttonStyle(.bordered)
    .tint(.orange)
    .controlSize(.small)
```

**Secondary Button** (Settings, Cancel)
```swift
Button("Cancel") { }
    .buttonStyle(.plain)
    .foregroundColor(.secondary)
```

---

## Layout & Spacing

### Grid System

Base unit: **4pt**

| Scale | Size | Usage |
|-------|------|-------|
| xs | 4pt | Micro spacing |
| sm | 8pt | Padding within components |
| md | 12pt | Space between rows |
| lg | 16pt | Section padding |
| xl | 24pt | Popover margins |

### Popover Layout

```
┌─────────────────────────────────┐ (300pt wide)
│  Title          Last Time        │ (Header: lg padding)
├─────────────────────────────────┤
│                                 │
│  [Metric Gauges] [Charts] [etc] │ (Content: variable height)
│                                 │ (Padding: lg)
│                                 │
├─────────────────────────────────┤
│ [Tab 1] [Tab 2] [Tab 3] [Tab 4] │ (Footer: md padding, md spacing)
└─────────────────────────────────┘

Height: 600pt (user-resizable)
```

### Component Spacing

```swift
VStack(spacing: 12) {  // md spacing
    MetricCircle(...)
    MetricBar(...)
    Divider()
}
.padding(16)  // lg padding
```

---

## Forge Language & UI Copy

### Key Messages

| Context | Message | Tone |
|---------|---------|------|
| App starts | "Reading vitals..." | Neutral, professional |
| Normal | "Pulse steady." | Calm, under control |
| CPU high | "The forge heats up!" | Calm urgency |
| Alert triggered | "The forge overheats!" | Urgent, attention-getting |
| Export done | "Vitals exported." | Confirmation |
| Settings saved | "Preferences forged." | Positive, done |

### UI Labels

| Component | Label | Tooltip |
|-----------|-------|---------|
| CPU gauge | "CPU" | "Central Processing Unit" |
| GPU gauge | "GPU" | "Graphics Processing Unit" |
| RAM bar | "RAM" | "Random Access Memory" |
| Disk bar | "Disk" | "Storage Drive" |
| Fan | "Fans" | "Cooling fans (RPM)" |
| Thermal strip | Temps | "Click to see full details" |
| Menu bar item | (icon only) | "Foundry Pulse — click to toggle" |

---

## Animation

### Timing

```swift
// Standard easing
.animation(.easeInOut(duration: 0.3), value: value)

// Springy (for alerts)
.animation(.spring(response: 0.4, dampingFraction: 0.7), value: value)

// Smooth (for numbers)
.animation(.easeOut(duration: 0.5), value: value)
```

### Effects

- **Metric updates**: Smooth color transition (0.3s)
- **Chart rendering**: Fade-in (0.5s) when switching time range
- **Alert notification**: Scale-in + fade (spring animation)
- **Menu bar sparkline**: Continuous smooth curve, no jumps

---

## Accessibility

### VoiceOver

- All components have meaningful labels
- Gauges: "CPU, 45 percent"
- Buttons: "Export CSV, button"
- Tabs: "Overview tab, 1 of 4"

### Keyboard Navigation

- Tab: Move to next element
- Shift+Tab: Move to previous element
- Enter: Activate button
- Space: Toggle checkbox/switch
- Arrow keys: Navigate within lists

### High Contrast

- Minimum text contrast: 4.5:1 (WCAG AA)
- Focus rings: 2pt Forge gold outline
- Disabled state: 50% opacity

### Text Scaling

- Responsive to System Preferences (10pt – 16pt)
- No hardcoded fixed-width layouts
- VStack/HStack expand/contract naturally

---

## Dark & Light Modes

### Dark Mode (Default)

```swift
.preferredColorScheme(.dark)
```

- Background: Anvil Black (#141210)
- Text: White
- Accents: Forge Gold (#E8A849)
- Dividers: Steel Gray (#3A3A3A)

### Light Mode (Pro Feature)

```swift
.preferredColorScheme(.light)
```

- Background: Off-white (#F8F8F8)
- Text: Dark gray (#1F1F1F)
- Accents: Burnt orange (#D97706)
- Dividers: Light gray (#D1D5DB)

---

## Icons & Imagery

### Icon Style

- **Simple**: Single-line, minimal detail
- **Size**: 16pt (UI), 32pt (menu bar), 64pt (app icon)
- **Weight**: 2pt stroke

### App Icon

```
Anvil outline + spark
- Anvil: Steel gray outline
- Spark: Forge gold fill
- Background: Gradient (Anvil Black → steel)
- Format: PNG 1024×1024, rounded corners (20%)
```

### Menu Bar Icon

```
⚡ (bolt) or custom spark glyph
- Color: Forge Gold (dark mode), burnt orange (light mode)
- Size: 13pt (SF Symbols)
```

---

## Code Examples

### Complete Component

```swift
struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let accentColor: Color
    let utilization: Double  // 0...1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .regular, design: .default))
                .foregroundColor(.secondary)
            
            HStack(alignment: .baseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(accentColor)
                
                Text(unit)
                    .font(.system(size: 11, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: utilization)
                .tint(utilizationColor(for: utilization))
        }
        .padding(12)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func utilizationColor(for percent: Double) -> Color {
        if percent < 0.5 {
            return Color(hex: "#10B981")  // Green
        } else if percent < 0.8 {
            return Color(hex: "#F59E0B")  // Yellow
        } else {
            return Color(hex: "#EF4444")  // Red
        }
    }
}
```

---

## Forge Language Style Guide

### Rules

1. **Use metallurgy verbs**: forge, hone, heat, cool, temper, shape
2. **Avoid tech jargon**: "Vitals" not "metrics", "The forge" not "The system"
3. **Action-oriented**: "Reading vitals..." not "Loading..."
4. **Professional tone**: Urgent but not panicked
5. **Consistency**: Use same terms across UI and logging

### Approved Terms

- ✅ "Reading vitals"
- ✅ "Pulse steady"
- ✅ "The forge"
- ✅ "Hone"
- ✅ "Forge output"
- ✅ "Preferences forged"

### Avoid

- ❌ "Loading metrics"
- ❌ "System hot" (use "The forge heats up")
- ❌ "Alert fired" (use "The forge overheats!")
- ❌ Generic tech speak

---

**Last Updated**: 2026-03-15  
**Maintained By**: Claude Agent (Design Lead)
