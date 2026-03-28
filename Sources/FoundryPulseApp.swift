import SwiftUI
import AppKit

// MARK: - Forge Language Logging

/// Log message using Forge metallurgy language.
///
/// Examples:
/// - "Reading vitals..."
/// - "Pulse steady."
/// - "The forge overheats!"
/// - "Vitals exported."
func forgeLog(_ message: String) {
    let timestamp = DateFormatter.forgeFormatter.string(from: Date())
    print("[\(timestamp)] FORGE: \(message)")
}

extension DateFormatter {
    static let forgeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

// MARK: - Main Entry Point

@main
struct FoundryPulseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            EmptyView()
                .frame(width: 0, height: 0)
                .hidden()
        }
    }
}

/// App delegate handling app lifecycle, menu bar setup, and window management.
class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?
    var sensorMonitor: SensorMonitor?
    var databaseManager: DatabaseManager?
    var alertManager: AlertManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        forgeLog("Reading vitals...")
        
        // Hide dock icon (menu bar app only)
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize managers
        databaseManager = DatabaseManager.shared
        sensorMonitor = SensorMonitor(pollingInterval: 2.0)
        alertManager = AlertManager(sensorMonitor: sensorMonitor!)
        
        // Initialize menu bar controller
        menuBarController = MenuBarController(sensorMonitor: sensorMonitor!)
        
        // Start sensor polling in background
        DispatchQueue.global(qos: .userInitiated).async {
            self.sensorMonitor?.startPolling()
        }
        
        forgeLog("Pulse steady.")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Allow app to stay running even when all windows close
        return false
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        forgeLog("The forge cools. Shutting down sensors...")
        sensorMonitor?.stopPolling()
        return .terminateNow
    }
}

/// Menu bar status item controller.
///
/// Manages:
/// - NSStatusBar icon and menu
/// - Popover visibility/positioning
/// - Sparkline graph update loop
/// - Click/keyboard interactions
class MenuBarController {
    let statusItem: NSStatusItem
    let popover: NSPopover
    let sensorMonitor: SensorMonitor
    var eventMonitor: Any?
    
    init(sensorMonitor: SensorMonitor) {
        self.sensorMonitor = sensorMonitor

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Create popover (must be initialized before using self)
        popover = NSPopover()
        popover.contentViewController = NSHostingController(rootView: MenuBarView(sensorMonitor: sensorMonitor))
        popover.behavior = .transient

        // Configure status bar button (uses self, so all stored properties must be set first)
        if let button = statusItem.button {
            button.title = "⚡"
            button.font = NSFont.systemFont(ofSize: 13, weight: .medium)
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // Setup keyboard shortcut (Cmd+Shift+P)
        setupKeyboardShortcut()
    }
    
    @objc func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            // Position popover relative to menu bar item
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    private func setupKeyboardShortcut() {
        // Register global keyboard shortcut (Cmd+Shift+P)
        // Note: Requires accessibility permissions on macOS
        // For now, placeholder; implement with custom event monitor
    }
}
