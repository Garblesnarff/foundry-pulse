# IOKit Hardware Sensor Integration Guide

## Overview

This guide covers reading hardware sensors from macOS using IOKit and SMC (System Management Controller) for the Foundry Pulse application.

---

## What Is IOKit?

IOKit is Apple's object-oriented device driver and hardware interface framework. It's used to:
- Enumerate hardware devices
- Read sensor values (temperature, voltage, current)
- Access device properties and metadata
- Manage power states and notifications

**Key Files**:
- `<IOKit/IOKitLib.h>` — Main IOKit API
- `<IOKit/hidsystem/IOHIDLib.h>` — HID (Human Interface Device) API
- `<IOKit/ps/IOPowerSources.h>` — Power management

---

## Temperature Sensors

### Finding Sensors

macOS exposes temperature sensors via the IOKit registry under the `IOHWSensors` family.

```c
#include <IOKit/IOKitLib.h>

// Find all temperature sensors
io_iterator_t iterator = 0;
io_service_t service = 0;

CFMutableDictionaryRef matchingDict = IOServiceMatching("IOHWSensors");
kern_return_t kr = IOServiceGetMatchingServices(
    kIOMainPortDefault,
    matchingDict,
    &iterator
);

if (kr != KERN_SUCCESS) {
    printf("IOServiceGetMatchingServices failed\n");
    return;
}

while ((service = IOIteratorNext(iterator)) != 0) {
    // Read temperature from this service
    // ...
    IOObjectRelease(service);
}

IOObjectRelease(iterator);
```

### Reading Temperature Values

Once you have a service, read its temperature property:

```c
io_registry_entry_t entry = service;  // From above

// Read "Temperature" property
CFNumberRef tempRef = (CFNumberRef)IORegistryEntryCreateCFProperty(
    entry,
    CFSTR("Temperature"),
    kCFAllocatorDefault,
    0
);

if (tempRef) {
    double tempCelsius = 0.0;
    CFNumberGetValue(tempRef, kCFNumberDoubleType, &tempCelsius);
    
    printf("Temperature: %.2f°C\n", tempCelsius);
    CFRelease(tempRef);
}
```

### Common Sensor Keys (SMC)

The SMC exposes sensor data via 4-character key codes:

```
CPU/Thermal Sensors:
  TC0F / TC0X  → CPU die temperature (main)
  TC0E         → CPU thermal state / energy
  TP0F / TP1F  → P-core (performance core) temps
  TE0F / TE1F  → E-core (efficiency core) temps

GPU Sensors:
  TG0F         → GPU core temperature

Memory/Storage:
  Tm0F         → Main memory temperature
  Ts0F / Ts1F  → Storage/SSD temperatures

Fan:
  FS!0 / FS!1  → Fan speed (RPM)
  FD!0 / FD!1  → Fan duty cycle (%)

Power/Thermal:
  TC0E         → Thermal state (flags)
  TC0W         → Power-limited state
```

---

## System Management Controller (SMC)

### What Is SMC?

The SMC is a low-level controller on Apple Silicon Macs (M1+) that manages:
- Temperature monitoring
- Fan speed control
- Power distribution
- Thermal throttling
- Battery management

### Accessing SMC

SMC access is restricted and requires:
1. **Elevated privilege** (helper tool or entitlements)
2. **Proper error handling** (SMC read/write can fail)
3. **Graceful degradation** (fallback if unavailable)

### SMC Read Pattern

```c
#include <IOKit/IOKitLib.h>

// 1. Find SMC service
io_service_t smcService = IOServiceGetMatchingService(
    kIOMainPortDefault,
    IOServiceMatching("AppleSMC")
);

if (smcService == 0) {
    printf("SMC service not found\n");
    return;
}

// 2. Create connection
io_connect_t connection = 0;
kern_return_t kr = IOServiceOpen(smcService, mach_task_self(), 0, &connection);
IOObjectRelease(smcService);

if (kr != KERN_SUCCESS) {
    printf("IOServiceOpen failed: 0x%08x\n", kr);
    return;
}

// 3. Prepare SMC read call
struct {
    uint32_t key;
    uint8_t status;
    uint8_t data[32];
} result = {};

// 4. Call SMC (example: read TC0F - CPU temp)
// This is pseudocode; actual implementation depends on SMC protocol version
kr = IOConnectCallStructMethod(
    connection,
    kSMCReadKey,      // SMC selector
    &request,         // Input struct
    sizeof(request),
    &result,          // Output struct
    &result_size
);

// 5. Decode result
if (kr == KERN_SUCCESS) {
    // result.data contains temperature (format: fpe2 = fixed-point 8.8)
    int intPart = (int8_t)result.data[0];
    int fracPart = result.data[1];
    double temp = intPart + (fracPart / 256.0);
    printf("CPU Temp: %.2f°C\n", temp);
}

// 6. Close connection
IOServiceClose(connection);
```

### SMC Return Value Formats

SMC keys return data in different formats:

| Format | Type | Example |
|--------|------|---------|
| **fpe2** | Fixed-point 8.8 | Temperatures (65.125°C) |
| **{fpe** | Fixed-point variant | Alternative temp format |
| **ui8** | Unsigned 8-bit int | Small numbers |
| **ui16** | Unsigned 16-bit int | Fan duty %, medium numbers |
| **ui32** | Unsigned 32-bit int | RPM, large numbers |
| **ch8** | ASCII char | Single character |
| **flag** | Boolean | Single bit |

**Decoding fpe2** (most common):
```c
// SMC returns 4 bytes
uint8_t byte0 = result.data[0];  // Integer part (signed)
uint8_t byte1 = result.data[1];  // Fractional part
uint8_t byte2 = result.data[2];  // Usually 0
uint8_t byte3 = result.data[3];  // Usually 0

int8_t integer = (int8_t)byte0;           // Convert to signed
uint8_t fraction = byte1;
double value = integer + (fraction / 256.0);
```

---

## Fan Speed Sensors

### Reading Fan Speed

Fan speeds are typically in RPM (revolutions per minute).

```c
// Read FS!0 (first fan)
// Format: ui16 or ui32 (big-endian)

// After SMC call, decode as:
uint16_t rpm = (result.data[0] << 8) | result.data[1];
printf("Fan 0 speed: %d RPM\n", rpm);
```

### Multiple Fans

M-series Macs may have multiple fans:
- `FS!0` — Fan 0 speed
- `FS!1` — Fan 1 speed
- `FS!2` — Fan 2 speed (rare)

### Fan Duty Cycle

Some systems expose fan duty cycle (percentage):
- `FD!0` — Fan 0 duty cycle (0–100%)

---

## Practical Implementation in Swift

### IOKit Bridging

Create a bridging header to expose C APIs to Swift:

```swift
// FoundryPulse-Bridging-Header.h
#ifndef FoundryPulse_Bridging_Header_h
#define FoundryPulse_Bridging_Header_h

#import <IOKit/IOKitLib.h>
#import <IOKit/ps/IOPowerSources.h>

// Custom C functions for SMC access
double readCPUTemperature(void);
double readGPUTemperature(void);
int readFanSpeed(void);

#endif
```

### Swift Wrapper

```swift
import Foundation

enum IOKitSensor {
    static func readCPUTemperature() -> Double? {
        // Call C function via bridging header
        let temp = readCPUTemperature()
        return temp > 0 ? temp : nil
    }
    
    static func readFanSpeed() -> Int? {
        let rpm = readFanSpeed()
        return rpm > 0 ? rpm : nil
    }
}
```

### Error Handling

```swift
// Wrap IOKit calls in try/catch
do {
    guard let cpuTemp = IOKitSensor.readCPUTemperature() else {
        throw SensorError.ioKitFailed("CPU temperature unavailable")
    }
    
    // Use temperature
} catch let error as SensorError {
    print("Sensor error: \(error.localizedDescription)")
    // Fallback or degrade gracefully
}
```

---

## Privilege & Entitlements

### Entitlements Required

```xml
<!-- Info.plist or entitlements file -->
<key>com.apple.security.device.usb</key>
<true/>

<key>com.apple.security.device.camera</key>
<true/>

<!-- For SMC access via entitlements -->
<key>com.apple.security.device.microphone</key>
<true/>
```

### Helper Tool Alternative

If entitlements insufficient, use SMJobBless (helper tool with elevated privilege):

1. Create small helper executable (runs as root)
2. Use SMJobBless to authorize and install helper
3. Helper performs SMC reads, returns results to app
4. App (unprivileged) calls helper via XPC

---

## Common Issues & Solutions

### Issue: "IOKitLib.h not found"

**Solution**: Add to Xcode build settings
```
Build Settings → Search Paths → Header Search Paths
/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks/IOKit.framework/Headers
```

Or use Xcode automatically:
```swift
import IOKit  // Should work if properly configured
```

### Issue: SMC Service Not Found

**Solution**: Check SMC availability
```swift
if IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC")) == 0 {
    print("SMC not available on this Mac")
    // Use IOKit-only sensors as fallback
}
```

### Issue: Stale or Duplicate Readings

**Solution**: 
- Cache sensor values with timestamps
- Skip reads if < 1 second since last read
- Validate ranges (e.g., temp should be 20–120°C)

### Issue: No Sensor Data (All Zeros)

**Cause**: SMC access denied or wrong key code

**Solution**:
```swift
// Try multiple key variations
for keyCode in ["TC0F", "TC0X", "TC0E"] {
    if let temp = readSMC(key: keyCode), temp > 0 {
        return temp
    }
}
```

---

## Testing Checklist

- [ ] Temperature reads are within realistic range (30–110°C)
- [ ] Fan speeds match System Report (About This Mac)
- [ ] No crashes when SMC unavailable
- [ ] Graceful fallback to ProcessInfo-only metrics
- [ ] No hung threads during IOKit calls
- [ ] Timeout after 100ms if IOKit slow
- [ ] Entitlements allow SMC access on deployed app

---

## References

- Apple IOKit Documentation: https://developer.apple.com/documentation/iokit
- SMCKit (third-party Swift wrapper): https://github.com/Apple-Fabric/smckit
- System Report sensor list: About This Mac → System Report → Hardware

---

**Last Updated**: 2026-03-15  
**Maintained By**: Claude Agent (Sensor Team)
